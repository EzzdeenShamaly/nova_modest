-- `place_order` now reports the status it wrote.
--
-- It answered with the number, the timestamp and the totals — everything only
-- the server can compute, except this one. `orders.status` carries a default,
-- so the client had two choices: hardcode a status, and tell the shopper
-- something untrue on the confirmation screen, or re-read the row it had just
-- written. Returning it costs neither.
--
-- Everything else is unchanged from 20260829120000_init.sql. The three edits
-- are the `v_status` declaration, the `returning` clause, and one key in the
-- result object.

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
  -- The status the insert actually wrote, rather than one a client guesses.
  v_status public.order_status;
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
  returning id, status into v_order_id, v_status;

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
    'status', v_status,
    'totals', jsonb_build_object(
      'subtotal', v_subtotal,
      'shipping', v_shipping_cost,
      'payment_fee', v_payment_fee
    )
  );
end;
$$;
