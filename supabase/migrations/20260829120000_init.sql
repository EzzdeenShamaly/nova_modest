-- NOVA MODEST initial schema: profiles, catalog, addresses, orders, RLS.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

create type public.address_kind as enum ('home', 'work', 'other');
create type public.shipping_method as enum ('standard');
create type public.payment_method as enum ('cash_on_delivery', 'card');
create type public.order_status as enum (
  'pending',
  'confirmed',
  'shipped',
  'delivered',
  'cancelled'
);

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  display_name text not null,
  avatar_url text,
  phone text,
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Shopper'
    )
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.touch_profile_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_profile_updated_at();

-- ---------------------------------------------------------------------------
-- Catalog
-- ---------------------------------------------------------------------------

create table public.product_categories (
  id text primary key,
  name text not null,
  sort_order int not null default 0
);

create table public.products (
  id text primary key,
  category_id text not null references public.product_categories (id),
  name text not null,
  price numeric not null check (price >= 0),
  description text,
  image_url text,
  is_sold_out boolean not null default false,
  is_featured boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.product_tags (
  id text primary key,
  name text not null
);

create table public.product_tag_assignments (
  product_id text not null references public.products (id) on delete cascade,
  tag_id text not null references public.product_tags (id) on delete cascade,
  primary key (product_id, tag_id)
);

create table public.product_colours (
  product_id text not null references public.products (id) on delete cascade,
  id text not null,
  name text not null,
  hex text not null,
  primary key (product_id, id)
);

create table public.product_sizes (
  product_id text not null references public.products (id) on delete cascade,
  size text not null,
  sort_order int not null default 0,
  primary key (product_id, size)
);

create table public.product_features (
  id bigint generated always as identity primary key,
  product_id text not null references public.products (id) on delete cascade,
  text text not null,
  icon text,
  sort_order int not null default 0
);

create table public.trending_searches (
  term text primary key,
  sort_order int not null default 0
);

-- Same Arabic folding the Flutter fake used: alef variants, taa marbuta,
-- alef maqsura, harakat, tatweel.
create or replace function public.normalize_ar(input text)
returns text
language sql
immutable
as $$
  select lower(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              trim(coalesce(input, '')),
              '[أإآٱ]',
              'ا',
              'g'
            ),
            'ة',
            'ه',
            'g'
          ),
          'ى',
          'ي',
          'g'
        ),
        E'[\u064B-\u0652]',
        '',
        'g'
      ),
      E'\u0640',
      '',
      'g'
    )
  );
$$;

create or replace function public.search_product_ids(p_query text)
returns table (id text)
language sql
stable
security invoker
set search_path = public
as $$
  with needle as (
    select public.normalize_ar(p_query) as value
  )
  select p.id
  from public.products p
  join public.product_categories c on c.id = p.category_id
  cross join needle
  where needle.value <> ''
    and public.normalize_ar(
      p.name || ' ' || c.name || ' ' || coalesce(
        (
          select string_agg(t.name, ' ')
          from public.product_tag_assignments a
          join public.product_tags t on t.id = a.tag_id
          where a.product_id = p.id
        ),
        ''
      )
    ) like '%' || needle.value || '%';
$$;

-- ---------------------------------------------------------------------------
-- Addresses
-- ---------------------------------------------------------------------------

create table public.user_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind public.address_kind not null,
  label text not null,
  recipient_name text not null,
  phone text not null,
  country text not null,
  region text not null,
  city text not null,
  street text not null,
  postal_code text,
  notes text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index user_addresses_one_default
  on public.user_addresses (user_id)
  where is_default;

create or replace function public.user_addresses_before_write()
returns trigger
language plpgsql
as $$
begin
  new.user_id := coalesce(new.user_id, auth.uid());

  if (
    select count(*)
    from public.user_addresses
    where user_id = new.user_id
      and id is distinct from new.id
  ) = 0 then
    new.is_default := true;
  end if;

  if new.is_default then
    update public.user_addresses
    set is_default = false
    where user_id = new.user_id
      and id is distinct from new.id
      and is_default;
  end if;

  return new;
end;
$$;

create trigger user_addresses_before_write
  before insert or update on public.user_addresses
  for each row execute function public.user_addresses_before_write();

create or replace function public.user_addresses_after_delete()
returns trigger
language plpgsql
as $$
begin
  if old.is_default then
    update public.user_addresses
    set is_default = true
    where id = (
      select id
      from public.user_addresses
      where user_id = old.user_id
      order by created_at
      limit 1
    );
  end if;
  return old;
end;
$$;

create trigger user_addresses_after_delete
  after delete on public.user_addresses
  for each row execute function public.user_addresses_after_delete();

-- ---------------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------------

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  number text not null unique,
  placed_at timestamptz not null default now(),
  contact_full_name text not null,
  contact_phone text not null,
  contact_email text,
  address_kind public.address_kind,
  address_label text,
  address_recipient_name text not null,
  address_phone text not null,
  address_country text not null,
  address_region text not null,
  address_city text not null,
  address_street text not null,
  address_postal_code text,
  address_notes text,
  shipping_method public.shipping_method not null default 'standard',
  payment_method public.payment_method not null default 'cash_on_delivery',
  subtotal numeric not null check (subtotal >= 0),
  shipping numeric not null check (shipping >= 0),
  payment_fee numeric not null check (payment_fee >= 0),
  total numeric generated always as (subtotal + shipping + payment_fee) stored,
  status public.order_status not null default 'pending'
);

create table public.order_items (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id text not null,
  product_name text not null,
  unit_price numeric not null,
  colour_id text,
  colour_name text,
  size text,
  quantity int not null check (quantity > 0 and quantity <= 10)
);

create table public.order_number_sequences (
  day date primary key,
  last_value int not null
);

create or replace function public.place_order(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_contact jsonb := payload -> 'contact';
  v_address jsonb := payload -> 'address';
  v_items jsonb := payload -> 'items';
  v_item jsonb;
  v_shipping public.shipping_method;
  v_payment public.payment_method;
  v_product public.products%rowtype;
  v_qty int;
  v_subtotal numeric := 0;
  v_shipping_cost numeric;
  v_payment_fee numeric;
  v_day date;
  v_seq int;
  v_number text;
  v_order_id uuid;
  v_placed_at timestamptz := now();
  v_colour_name text;
begin
  if v_contact is null
     or nullif(trim(v_contact ->> 'full_name'), '') is null
     or nullif(trim(v_contact ->> 'phone'), '') is null
     or v_address is null
     or nullif(trim(v_address ->> 'recipient_name'), '') is null
     or nullif(trim(v_address ->> 'street'), '') is null
     or v_items is null
     or jsonb_typeof(v_items) <> 'array'
     or jsonb_array_length(v_items) = 0 then
    raise exception 'Order is missing required details.' using errcode = 'P0001';
  end if;

  begin
    v_shipping := coalesce(payload ->> 'shipping', 'standard')::public.shipping_method;
  exception
    when invalid_text_representation then
      raise exception 'Invalid shipping method.' using errcode = 'P0001';
  end;

  begin
    v_payment := coalesce(payload ->> 'payment', 'cash_on_delivery')::public.payment_method;
  exception
    when invalid_text_representation then
      raise exception 'Invalid payment method.' using errcode = 'P0001';
  end;

  if v_payment = 'card' then
    raise exception 'Card payment is not available.' using errcode = 'P0001';
  end if;

  for v_item in select value from jsonb_array_elements(v_items)
  loop
    select * into v_product
    from public.products
    where public.products.id = v_item ->> 'product_id';

    if not found then
      raise exception 'Product not found.' using errcode = 'P0001';
    end if;

    v_qty := coalesce((v_item ->> 'quantity')::int, 0);
    if v_qty < 1 or v_qty > 10 then
      raise exception 'Invalid quantity.' using errcode = 'P0001';
    end if;

    v_subtotal := v_subtotal + (v_product.price * v_qty);
  end loop;

  v_shipping_cost := case v_shipping when 'standard' then 35 else 0 end;
  v_payment_fee := case v_payment when 'cash_on_delivery' then 15 else 0 end;

  v_day := (timezone('utc', v_placed_at))::date;
  insert into public.order_number_sequences as seq (day, last_value)
  values (v_day, 1)
  on conflict (day) do update
    set last_value = seq.last_value + 1
  returning last_value into v_seq;

  v_number :=
    'ORD-'
    || to_char(v_placed_at, 'YYMMDD')
    || '-'
    || lpad(v_seq::text, 4, '0');

  insert into public.orders (
    user_id,
    number,
    placed_at,
    contact_full_name,
    contact_phone,
    contact_email,
    address_kind,
    address_label,
    address_recipient_name,
    address_phone,
    address_country,
    address_region,
    address_city,
    address_street,
    address_postal_code,
    address_notes,
    shipping_method,
    payment_method,
    subtotal,
    shipping,
    payment_fee
  )
  values (
    v_user_id,
    v_number,
    v_placed_at,
    trim(v_contact ->> 'full_name'),
    trim(v_contact ->> 'phone'),
    nullif(trim(v_contact ->> 'email'), ''),
    nullif(v_address ->> 'kind', '')::public.address_kind,
    v_address ->> 'label',
    trim(v_address ->> 'recipient_name'),
    trim(coalesce(v_address ->> 'phone', '')),
    coalesce(v_address ->> 'country', ''),
    coalesce(v_address ->> 'region', ''),
    coalesce(v_address ->> 'city', ''),
    trim(v_address ->> 'street'),
    nullif(v_address ->> 'postal_code', ''),
    nullif(v_address ->> 'notes', ''),
    v_shipping,
    v_payment,
    v_subtotal,
    v_shipping_cost,
    v_payment_fee
  )
  returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(v_items)
  loop
    select * into v_product
    from public.products
    where public.products.id = v_item ->> 'product_id';

    v_colour_name := null;
    if nullif(v_item ->> 'colour_id', '') is not null then
      select c.name
      into v_colour_name
      from public.product_colours c
      where c.product_id = v_product.id
        and c.id = v_item ->> 'colour_id';
    end if;

    insert into public.order_items (
      order_id,
      product_id,
      product_name,
      unit_price,
      colour_id,
      colour_name,
      size,
      quantity
    )
    values (
      v_order_id,
      v_product.id,
      v_product.name,
      v_product.price,
      nullif(v_item ->> 'colour_id', ''),
      v_colour_name,
      nullif(v_item ->> 'size', ''),
      (v_item ->> 'quantity')::int
    );
  end loop;

  return jsonb_build_object(
    'number', v_number,
    'placed_at', v_placed_at,
    'totals', jsonb_build_object(
      'subtotal', v_subtotal,
      'shipping', v_shipping_cost,
      'payment_fee', v_payment_fee
    )
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.product_categories enable row level security;
alter table public.products enable row level security;
alter table public.product_tags enable row level security;
alter table public.product_tag_assignments enable row level security;
alter table public.product_colours enable row level security;
alter table public.product_sizes enable row level security;
alter table public.product_features enable row level security;
alter table public.trending_searches enable row level security;
alter table public.user_addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_number_sequences enable row level security;

create policy profiles_select_own
  on public.profiles for select
  using (auth.uid() = id);

create policy profiles_update_own
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy catalog_categories_read
  on public.product_categories for select
  to anon, authenticated
  using (true);

create policy catalog_products_read
  on public.products for select
  to anon, authenticated
  using (true);

create policy catalog_tags_read
  on public.product_tags for select
  to anon, authenticated
  using (true);

create policy catalog_tag_assignments_read
  on public.product_tag_assignments for select
  to anon, authenticated
  using (true);

create policy catalog_colours_read
  on public.product_colours for select
  to anon, authenticated
  using (true);

create policy catalog_sizes_read
  on public.product_sizes for select
  to anon, authenticated
  using (true);

create policy catalog_features_read
  on public.product_features for select
  to anon, authenticated
  using (true);

create policy catalog_trending_read
  on public.trending_searches for select
  to anon, authenticated
  using (true);

create policy addresses_select_own
  on public.user_addresses for select
  using (auth.uid() = user_id);

create policy addresses_insert_own
  on public.user_addresses for insert
  with check (auth.uid() = user_id);

create policy addresses_update_own
  on public.user_addresses for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy addresses_delete_own
  on public.user_addresses for delete
  using (auth.uid() = user_id);

create policy orders_select_own
  on public.orders for select
  using (auth.uid() is not null and auth.uid() = user_id);

create policy order_items_select_own
  on public.order_items for select
  using (
    exists (
      select 1
      from public.orders o
      where o.id = order_items.order_id
        and o.user_id = auth.uid()
    )
  );

revoke insert, update, delete on public.orders from anon, authenticated;
revoke insert, update, delete on public.order_items from anon, authenticated;
revoke all on public.order_number_sequences from anon, authenticated;

grant execute on function public.normalize_ar(text) to anon, authenticated;
grant execute on function public.search_product_ids(text) to anon, authenticated;
grant execute on function public.place_order(jsonb) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Storage
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'product-images',
    'product-images',
    true,
    5242880,
    array['image/png', 'image/jpeg', 'image/webp']
  ),
  (
    'avatars',
    'avatars',
    false,
    2097152,
    array['image/png', 'image/jpeg', 'image/webp']
  );

create policy product_images_public_read
  on storage.objects for select
  using (bucket_id = 'product-images');

create policy avatars_select_own
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy avatars_insert_own
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy avatars_update_own
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
