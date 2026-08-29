import 'package:injectable/injectable.dart' hide Order;
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/supabase/supabase_error_mapper.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/order.dart';
import 'package:nova_modest/features/checkout/domain/entities/order_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';
import 'package:nova_modest/features/checkout/domain/repositories/order_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live [OrderRepository] against the `place_order` RPC.
@LazySingleton(as: OrderRepository, env: [Environment.dev])
class SupabaseOrderRepository implements OrderRepository {
  const SupabaseOrderRepository();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Result<Order>> place(CheckoutDraft draft) async {
    final totals = draft.totals;
    if (draft.contact?.isComplete != true ||
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
              'full_name': draft.contact!.fullName,
              'phone': draft.contact!.phone,
              'email': draft.contact!.email,
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

      return Ok(_orderFromRpc(response));
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  static String _shipping(ShippingMethod method) => switch (method) {
    ShippingMethod.standard => 'standard',
  };

  static String _payment(PaymentMethod method) => switch (method) {
    PaymentMethod.cashOnDelivery => 'cash_on_delivery',
    PaymentMethod.card => 'card',
  };

  static Order _orderFromRpc(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    return Order(
      number: json['number'] as String,
      placedAt: DateTime.parse(json['placed_at'] as String),
      totals: OrderTotals(
        subtotal: _asNum(totals['subtotal']),
        shipping: _asNum(totals['shipping']),
        paymentFee: _asNum(totals['payment_fee']),
      ),
    );
  }

  static num _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.parse(value);
    throw FormatException('Expected a number, got $value');
  }
}
