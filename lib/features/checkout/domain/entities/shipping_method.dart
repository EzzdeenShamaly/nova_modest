/// How the order travels, from Figma `1:2059`.
///
/// **One method today**, and the frame draws it as a chosen radio rather than a
/// stated fact — so it is modelled as a choice with one option, not as a
/// constant. That is the opposite call to step 1's dialling code, and for a
/// reason: a code selector with one entry chooses nothing and changes nothing,
/// while this one carries a price into the order total and is the row a second
/// method slots into.
///
/// The name and the delivery window are localized copy, so they live in the ARB
/// and not here. What belongs to the domain is which methods exist and what
/// each costs.
enum ShippingMethod {
  /// «التوصيل القياسي» — ٣-٥ أيام عمل.
  standard(cost: 35);

  const ShippingMethod({required this.cost});

  /// What this method adds to the order.
  ///
  /// The same 35 the cart quotes: `CartTotals.shippingFee` was moved off its
  /// old flat 30 onto this, so the total a shopper sees in the cart is the
  /// total they see at checkout. A figure that changes between the two, with
  /// nothing on screen explaining it, is how a checkout loses a sale.
  final num cost;
}
