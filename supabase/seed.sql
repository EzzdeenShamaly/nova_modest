-- Catalog seed matching FakeCatalogRepository (p1–p8, same copy and prices).

insert into public.product_categories (id, name, sort_order) values
  ('abayas', 'عبايات', 1),
  ('hijab-shawls', 'حجاب وشالات', 2),
  ('sets', 'أطقم', 3),
  ('accessories', 'إكسسوارات', 4);

insert into public.product_tags (id, name) values
  ('daily', 'يومي'),
  ('occasions', 'مناسبات'),
  ('colourful', 'ملون');

insert into public.products (
  id, category_id, name, price, description, is_sold_out, is_featured
) values
  (
    'p1',
    'abayas',
    'عباءة كلاسيكية باللون الزيتي',
    450,
    'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي والمناسبات الخاصة.',
    false,
    true
  ),
  (
    'p2',
    'abayas',
    'عباءة سوداء بتفاصيل عصرية',
    520,
    'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي والمناسبات الخاصة.',
    false,
    true
  ),
  (
    'p3',
    'hijab-shawls',
    'شيلة حريرية فاخرة',
    120,
    'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي والمناسبات الخاصة.',
    false,
    true
  ),
  (
    'p4',
    'sets',
    'طقم مريح بلون ترابي',
    380,
    'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي والمناسبات الخاصة.',
    false,
    true
  ),
  (
    'p5',
    'abayas',
    'عباية حرير مغسول',
    850,
    'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي والمناسبات الخاصة.',
    false,
    false
  ),
  (
    'p6',
    'abayas',
    'عباية كتان يومية',
    620,
    'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي والمناسبات الخاصة.',
    true,
    false
  ),
  (
    'p7',
    'abayas',
    'عباية رسمية كحلية',
    950,
    'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي والمناسبات الخاصة.',
    false,
    false
  ),
  (
    'p8',
    'abayas',
    'عباية كريب صيفية',
    780,
    'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي والمناسبات الخاصة.',
    false,
    false
  );

insert into public.product_tag_assignments (product_id, tag_id) values
  ('p1', 'colourful'),
  ('p1', 'daily'),
  ('p2', 'occasions'),
  ('p3', 'occasions'),
  ('p4', 'daily'),
  ('p5', 'occasions'),
  ('p6', 'daily'),
  ('p7', 'occasions'),
  ('p7', 'colourful'),
  ('p8', 'daily'),
  ('p8', 'colourful');

insert into public.product_colours (product_id, id, name, hex)
select p.id, c.id, c.name, c.hex
from public.products p
cross join (
  values
    ('light-grey', 'رمادي فاتح', '#D1D5DB'),
    ('grey', 'رمادي', '#6B7280'),
    ('black', 'أسود', '#000000')
) as c(id, name, hex);

insert into public.product_sizes (product_id, size, sort_order)
select p.id, s.size, s.sort_order
from public.products p
cross join (
  values
    ('S', 1),
    ('M', 2),
    ('L', 3),
    ('XL', 4)
) as s(size, sort_order);

insert into public.product_features (product_id, text, icon, sort_order)
select p.id, f.text, f.icon, f.sort_order
from public.products p
cross join (
  values
    ('قماش كريب فاخر', 'fabric', 1),
    ('قصة واسعة مريحة', 'fit', 2),
    ('يفضل الغسيل الجاف', 'care', 3)
) as f(text, icon, sort_order);

insert into public.trending_searches (term, sort_order) values
  ('عبايات', 1),
  ('حجاب وشالات', 2),
  ('مناسبات', 3),
  ('أطقم', 4),
  ('يومي', 5);
