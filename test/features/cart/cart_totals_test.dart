import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';

/// The cart shows the number the shopper will pay.
///
/// Found in the live run on 2026-09-19: the cart said 555 and the order came to
/// 570, because the cash-on-delivery fee joined only at checkout. The property
/// is stated against checkout itself rather than against a literal, so the two
/// cannot drift apart again — if checkout's default method or its fee ever
/// changes, this fails instead of the shopper finding out.
void main() {
  const set = Product(
    id: 'p4',
    name: 'طقم مريح',
    price: 380,
    categoryId: 'sets',
  );
  const abaya = Product(
    id: 'p1',
    name: 'عباءة',
    price: 450,
    categoryId: 'abayas',
  );

  test('the cart total is what checkout charges by default', () {
    const items = [CartItem(product: set), CartItem(product: abaya, quantity: 2)];
    final cart = CartTotals.of(items);

    final charged = CheckoutDraft(cart: cart, items: items).totals!.total;

    expect(cart.total, charged);
  });

  test('the run that found it: one line at 380 comes to 430, not 415', () {
    final cart = CartTotals.of(const [CartItem(product: set)]);

    expect(cart.total, 430);
  });

  test('an empty cart asks for nothing', () {
    expect(CartTotals.of(const []).total, 0);
  });
}
