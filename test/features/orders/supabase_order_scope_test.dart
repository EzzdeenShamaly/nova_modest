import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/orders/data/repositories/supabase_order_repository.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// "طلباتي" lists the caller's own orders — even when the caller is an admin.
///
/// Measured live on 2026-09-19: RLS gives an admin's session every row, because
/// `orders_admin_read` is OR'd with `orders_select_own`, and the storefront's
/// query carried no user predicate, so an admin saw every customer's orders as
/// their own. RLS cannot run in a unit test, so this stands a **fake PostgREST**
/// up on loopback that answers exactly as production answers an admin: with no
/// `user_id` filter it returns every row. A repository that only trusts RLS
/// shows everything here, which is the defect reproduced; one that names the
/// caller shows theirs.
///
/// Loopback only — no network, no Supabase, nothing outside this process.
void main() {
  const admin = 'admin-uid';
  const shopper = 'shopper-uid';

  Map<String, dynamic> row(String number, String userId, String placedAt) => {
    'number': number,
    'user_id': userId,
    'placed_at': placedAt,
    'status': 'pending',
    'subtotal': 380,
    'shipping': 35,
    'payment_fee': 15,
    'contact_full_name': 'اسم',
    'contact_phone': '+966500000000',
    'contact_email': null,
    'address_kind': 'home',
    'address_label': 'المنزل',
    'address_recipient_name': 'اسم',
    'address_phone': '+966500000000',
    'address_country': 'السعودية',
    'address_region': 'حي',
    'address_city': 'الرياض',
    'address_street': 'شارع',
    'address_postal_code': null,
    'address_notes': null,
    'order_items': [
      {
        'product_id': 'p4',
        'product_name': 'منتج',
        'unit_price': 380,
        'colour_id': null,
        'colour_name': null,
        'size': null,
        'quantity': 1,
      },
    ],
  };

  // The three orders production held on 2026-09-19: two the admin placed, one
  // a customer did.
  final table = [
    row('ORD-260831-0001', admin, '2026-08-31T13:28:00Z'),
    row('ORD-260917-0001', admin, '2026-09-17T12:51:00Z'),
    row('ORD-260919-0001', shopper, '2026-09-19T09:00:30Z'),
  ];

  late HttpServer server;
  late SupabaseClient client;
  final requests = <Uri>[];

  setUp(() async {
    requests.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests.add(req.uri);
      // Every `col=eq.value` filter in the query narrows the table, as
      // PostgREST's would. With none, everything comes back — the admin case.
      var rows = table;
      req.uri.queryParameters.forEach((column, value) {
        if (value.startsWith('eq.')) {
          final wanted = value.substring(3);
          rows = [for (final r in rows) if ('${r[column]}' == wanted) r];
        }
      });
      rows = [...rows]
        ..sort((a, b) => '${b['placed_at']}'.compareTo('${a['placed_at']}'));
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(rows));
      await req.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'anon-key');
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  _ScopedRepository asUser(String? uid) => _ScopedRepository(client, uid);

  List<String> numbersIn(Result<List<Order>> result) => [
    for (final o in (result as Ok<List<Order>>).value) o.number,
  ];

  test('an admin session lists only its own orders, not every customer\'s', () async {
    final result = await asUser(admin).orders();

    // Without the predicate this is all three — the live defect.
    expect(numbersIn(result), ['ORD-260917-0001', 'ORD-260831-0001']);
    expect(
      requests.single.queryParameters['user_id'],
      'eq.$admin',
      reason: 'the caller is named in the request itself',
    );
  });

  test('an admin cannot open a customer\'s order through the storefront', () async {
    final result = await asUser(admin).orderByNumber('ORD-260919-0001');

    // The row exists and RLS would hand it to an admin; "mine" says no.
    expect(result, isA<Err<Order>>());
    expect((result as Err<Order>).failure, isA<NotFoundFailure>());
  });

  test('and still opens one of its own', () async {
    final result = await asUser(admin).orderByNumber('ORD-260917-0001');

    expect((result as Ok<Order>).value.number, 'ORD-260917-0001');
  });

  test('a customer session is unchanged: exactly its own', () async {
    final result = await asUser(shopper).orders();

    expect(numbersIn(result), ['ORD-260919-0001']);
  });

  test('with no session it refuses locally and spends no request', () async {
    final list = await asUser(null).orders();
    final one = await asUser(null).orderByNumber('ORD-260917-0001');

    expect((list as Err<List<Order>>).failure, isA<UnauthorizedFailure>());
    expect((one as Err<Order>).failure, isA<UnauthorizedFailure>());
    expect(requests, isEmpty);
  });
}

/// Points the repository at the fake, as a session for [_uid].
class _ScopedRepository extends SupabaseOrderRepository {
  _ScopedRepository(this._client, this._uid);

  final SupabaseClient _client;
  final String? _uid;

  @override
  SupabaseClient get client => _client;

  @override
  String? get currentUserId => _uid;
}
