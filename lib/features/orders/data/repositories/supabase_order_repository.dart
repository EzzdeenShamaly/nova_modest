// hide Order: injectable exports an `Order` annotation that shadows this
// feature's entity.
import 'package:injectable/injectable.dart' hide Order;
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/supabase/supabase_error_mapper.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/orders/domain/repositories/order_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live [OrderRepository]: the `place_order` RPC to write, plain selects to
/// read back.
///
/// Writing goes through an RPC because placing an order is one transaction —
/// price the lines from the catalogue, take the day's next number, insert the
/// order and its items — and none of that should be four round trips a phone
/// could interleave. Reading is two ordinary selects, because RLS
/// (`orders_select_own`, `order_items_select_own`) already scopes them to the
/// signed-in shopper and there is nothing to make atomic.
@LazySingleton(as: OrderRepository, env: [Environment.dev])
class SupabaseOrderRepository implements OrderRepository {
  const SupabaseOrderRepository();

  SupabaseClient get _client => Supabase.instance.client;

  /// Columns of one order plus its lines, in the shape [_orderFromRow] reads.
  static const String _orderColumns = '''
number, placed_at, status, subtotal, shipping, payment_fee,
contact_full_name, contact_phone, contact_email,
address_kind, address_label, address_recipient_name, address_phone,
address_country, address_region, address_city, address_street,
address_postal_code, address_notes,
order_items (product_id, product_name, unit_price, colour_id, colour_name, size, quantity)
''';

  @override
  Future<Result<Order>> place(CheckoutDraft draft) async {
    final totals = draft.totals;
    final contact = draft.contact;
    // Checked before the call: a refusal the caller could have avoided should
    // not cost a round trip. `place_order` raises P0001 for the same cases, so
    // this is a courtesy rather than the guarantee.
    if (contact?.isComplete != true ||
        draft.address == null ||
        totals == null ||
        draft.items.isEmpty) {
      return const Err(ValidationFailure('Order is missing required details.'));
    }

    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'place_order',
        params: {
          'payload': {
            'contact': {
              'full_name': contact!.fullName,
              'phone': contact.phone,
              'email': contact.email,
            },
            'address': draft.address!.toJson(),
            'shipping': _shipping(draft.shipping),
            'payment': _payment(draft.payment),
            'items': [
              for (final item in draft.items)
                {
                  'product_id': item.product.id,
                  'colour_id': item.colourId,
                  'size': item.size,
                  'quantity': item.quantity,
                },
            ],
          },
        },
      );

      return Ok(orderFromRpc(response, draft));
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<List<Order>>> orders() async {
    try {
      final rows = await _client
          .from('orders')
          .select(_orderColumns)
          // Newest first, as `1:1356` lists them.
          .order('placed_at', ascending: false);

      return Ok([for (final row in rows) orderFromRow(row)]);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<Order>> orderByNumber(String number) async {
    try {
      final row = await _client
          .from('orders')
          .select(_orderColumns)
          .eq('number', number)
          // maybeSingle, not single: PostgREST raises PGRST116 for no rows and
          // this returns null instead, so "no such order" stays a
          // NotFoundFailure rather than arriving as a thrown ServerFailure.
          .maybeSingle();

      if (row == null) return const Err(NotFoundFailure());
      return Ok(orderFromRow(row));
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  // --- Mapping --------------------------------------------------------------
  //
  // Public for testing: reading an order back is where this class actually
  // breaks — a renamed column or an unknown status string — and none of it
  // needs a server to exercise.

  /// What `place_order` returns, completed from the [draft] that produced it.
  ///
  /// The RPC answers with the number, the timestamp, the status and the totals
  /// it computed — the four things only the server can know. The lines, the
  /// address and the recipient come from the draft rather than a second read:
  /// they were just sent, and the draft is still in hand.
  static Order orderFromRpc(Map<String, dynamic> json, CheckoutDraft draft) {
    final totals = json['totals'] as Map<String, dynamic>;
    return Order(
      number: json['number'] as String,
      placedAt: DateTime.parse(json['placed_at'] as String),
      totals: OrderTotals(
        subtotal: _asNum(totals['subtotal']),
        shipping: _asNum(totals['shipping']),
        paymentFee: _asNum(totals['payment_fee']),
      ),
      // From the server, never assumed: `orders.status` defaults to `pending`,
      // so hardcoding anything here would tell the shopper something untrue on
      // the confirmation screen.
      status: statusFrom(json['status'] as String?),
      items: draft.items,
      address: draft.address,
      recipientName: draft.contact?.fullName,
      recipientPhone: draft.contact?.phone,
    );
  }

  /// One row of `orders` with its `order_items` joined.
  static Order orderFromRow(Map<String, dynamic> row) {
    final lines = (row['order_items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    return Order(
      number: row['number'] as String,
      placedAt: DateTime.parse(row['placed_at'] as String),
      totals: OrderTotals(
        subtotal: _asNum(row['subtotal']),
        shipping: _asNum(row['shipping']),
        paymentFee: _asNum(row['payment_fee']),
      ),
      status: statusFrom(row['status'] as String?),
      items: [for (final line in lines) _itemFromRow(line)],
      address: _addressFromRow(row),
      recipientName: row['contact_full_name'] as String?,
      recipientPhone: row['contact_phone'] as String?,
    );
  }

  /// A line, rebuilt from what the order **recorded** rather than from the
  /// catalogue.
  ///
  /// `order_items` stores `product_name` and `unit_price` precisely so history
  /// does not move: re-reading today's catalogue would restate what someone was
  /// charged every time the shop re-prices. The `Product` here is therefore a
  /// historical snapshot with no description, images or sizes — nothing on an
  /// order screen asks for those.
  static CartItem _itemFromRow(Map<String, dynamic> line) {
    final colourId = line['colour_id'] as String?;
    final colourName = line['colour_name'] as String?;

    return CartItem(
      product: Product(
        id: line['product_id'] as String,
        name: line['product_name'] as String,
        price: _asNum(line['unit_price']),
        // The order does not record which category the garment was filed
        // under, and no order screen groups by one.
        categoryId: '',
        colours: [
          if (colourId != null && colourName != null)
            // hex is unknown here and unused: order screens name the colour,
            // they do not swatch it.
            ProductColour(id: colourId, name: colourName, hex: ''),
        ],
      ),
      colourId: colourId,
      size: line['size'] as String?,
      quantity: (line['quantity'] as num).toInt(),
    );
  }

  /// The address as it was at the time, flattened across the `orders` row.
  ///
  /// Null when the row carries no street — the column is `not null`, so this is
  /// a guard against a future shape rather than a case the schema allows.
  static Address? _addressFromRow(Map<String, dynamic> row) {
    final street = row['address_street'] as String?;
    if (street == null || street.isEmpty) return null;

    return Address(
      // An order's address is a copy, not a row in `user_addresses`: the
      // shopper may have deleted or edited that one since.
      id: '',
      kind: _addressKindFrom(row['address_kind'] as String?),
      label: row['address_label'] as String? ?? '',
      recipientName: row['address_recipient_name'] as String? ?? '',
      phone: row['address_phone'] as String? ?? '',
      country: row['address_country'] as String? ?? '',
      region: row['address_region'] as String? ?? '',
      city: row['address_city'] as String? ?? '',
      street: street,
      postalCode: row['address_postal_code'] as String?,
      notes: row['address_notes'] as String?,
    );
  }

  static AddressKind _addressKindFrom(String? value) => switch (value) {
    'home' => AddressKind.home,
    'work' => AddressKind.work,
    _ => AddressKind.other,
  };

  /// `public.order_status` as this app's enum.
  ///
  /// An unrecognised value falls back to [OrderStatus.pending] rather than
  /// throwing: a server that gains a stage before the app ships should leave a
  /// shopper looking at the earliest one, not at a crash.
  static OrderStatus statusFrom(String? value) => switch (value) {
    'pending' => OrderStatus.pending,
    'confirmed' => OrderStatus.confirmed,
    'processing' => OrderStatus.processing,
    'shipped' => OrderStatus.shipped,
    'delivered' => OrderStatus.delivered,
    'cancelled' => OrderStatus.cancelled,
    _ => OrderStatus.pending,
  };

  static String _shipping(ShippingMethod method) => switch (method) {
    ShippingMethod.standard => 'standard',
  };

  static String _payment(PaymentMethod method) => switch (method) {
    PaymentMethod.cashOnDelivery => 'cash_on_delivery',
    PaymentMethod.card => 'card',
  };

  static num _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.parse(value);
    throw FormatException('Expected a number, got $value');
  }
}
