/// How the order is paid for, from Figma `1:2059`.
///
/// **Cash on delivery is the only method this project has**, and the frame says
/// so itself: the card option is drawn with "قريباً" under it and an empty
/// radio. So [card] exists here as an unavailable option rather than being
/// omitted — the design deliberately tells the shopper it is coming, and
/// dropping it would drop that message.
///
/// Nothing behind [card] is stubbed. There is no card form, no token, no
/// gateway; [isAvailable] is false and the UI cannot select it.
enum PaymentMethod {
  /// «الدفع عند الاستلام» — the frame's chosen option.
  cashOnDelivery(fee: 15, isAvailable: true),

  /// «البطاقة الائتمانية» — drawn, labelled "قريباً", not selectable.
  card(fee: 0, isAvailable: false);

  const PaymentMethod({required this.fee, required this.isAvailable});

  /// What this method adds to the order — «رسوم إضافية ١٥ ر.س» for cash.
  ///
  /// On the method rather than as a checkout constant, so choosing differently
  /// moves the total on its own. A constant would quietly become wrong the day
  /// [card] is switched on, and the total is not a place to be quietly wrong.
  final num fee;

  /// Whether the shopper may choose it.
  final bool isAvailable;
}
