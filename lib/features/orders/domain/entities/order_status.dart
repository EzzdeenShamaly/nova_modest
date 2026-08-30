/// How far along an order is.
///
/// **One enum reconciling two frames that disagreed.** `1:1480` draws a
/// five-stage tracker — قيد الانتظار, مؤكد, قيد التحضير, تم الشحن, تم التوصيل —
/// while `1:1356` shows only three badges and calls the last one "مكتمل". Five
/// values with two strings for [delivered] keeps both drawings honest without
/// inventing a second notion of progress; a three-value enum would have deleted
/// two stages the design draws explicitly.
///
/// The first five are declared **in the order they happen**, so [index] *is*
/// the progress and the tracker compares against it rather than carrying
/// positions of its own. [cancelled] sits outside that line and is excluded
/// from [journey] for exactly that reason.
enum OrderStatus {
  /// Placed, nothing done yet.
  pending,

  /// Accepted by the shop.
  confirmed,

  /// Being picked and packed. Where a newly placed order sits.
  processing,

  /// Handed to the courier.
  shipped,

  /// With the shopper. «مكتمل» on a badge, «تم التوصيل» on the tracker.
  delivered,

  /// Called off. **Not on the tracker**, which draws the five stages an order
  /// passes *through*; a cancelled order left that path rather than advancing
  /// along it, so the tracker shows where it stopped and the badge says it was
  /// cancelled.
  ///
  /// Exists because `public.order_status` has it. Nothing in this app cancels
  /// an order — that is a backend action — but a status arriving from the
  /// server with no Dart counterpart is a parse failure on a screen the shopper
  /// is looking at.
  cancelled;

  /// The stages an order passes through, in order — what the tracker draws.
  ///
  /// [cancelled] is not one of them: it is an outcome, not a stage, and putting
  /// it sixth on a progress rail would suggest every order ends there.
  static const List<OrderStatus> journey = [
    pending,
    confirmed,
    processing,
    shipped,
    delivered,
  ];

  /// Whether this stage is behind [current].
  bool isBefore(OrderStatus current) => index < current.index;
}
