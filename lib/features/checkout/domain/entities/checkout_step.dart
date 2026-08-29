/// Where the shopper is in the checkout flow.
///
/// **The design counts three steps, not four.** `1:2163`, `1:1944` and `1:2059`
/// each carry a step indicator — the first is named "الخطوة 1 من 3" — while
/// `1:1840` "مراجعة الطلب" carries none. Review is a confirmation *after* the
/// three steps, and success is the outcome; neither is a step, and
/// [indicatorIndex] is null for both.
enum CheckoutStep {
  contact,
  address,
  payment,
  review,
  success;

  /// How many stations the indicator draws.
  static const int indicatorCount = 3;

  /// This step's place in the indicator, or null for the screens that show
  /// none.
  int? get indicatorIndex => switch (this) {
    CheckoutStep.contact => 0,
    CheckoutStep.address => 1,
    CheckoutStep.payment => 2,
    CheckoutStep.review || CheckoutStep.success => null,
  };

  /// The step after this one, or null at the end of the flow.
  CheckoutStep? get next {
    final index = CheckoutStep.values.indexOf(this);
    return index == CheckoutStep.values.length - 1
        ? null
        : CheckoutStep.values[index + 1];
  }

  /// The step before this one, or null at the start.
  ///
  /// Null is what tells the host to leave checkout entirely rather than move
  /// within it — there is nowhere further back to go.
  CheckoutStep? get previous {
    final index = CheckoutStep.values.indexOf(this);
    // Success is terminal: an order is placed, and going "back" into review
    // would offer to place it again.
    if (index == 0 || this == CheckoutStep.success) return null;
    return CheckoutStep.values[index - 1];
  }
}
