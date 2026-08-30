/// How far along an order is.
///
/// **One enum reconciling two frames that disagreed.** `1:1480` draws a
/// five-stage tracker — قيد الانتظار, مؤكد, قيد التحضير, تم الشحن, تم التوصيل —
/// while `1:1356` shows only three badges and calls the last one "مكتمل". Five
/// values with two strings for [delivered] keeps both drawings honest without
/// inventing a second notion of progress; a three-value enum would have deleted
/// two stages the design draws explicitly.
///
/// Declared in order, so [index] *is* the progress: the tracker compares
/// against it rather than carrying a position of its own.
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
  delivered;

  /// Whether this stage is behind [current].
  bool isBefore(OrderStatus current) => index < current.index;
}
