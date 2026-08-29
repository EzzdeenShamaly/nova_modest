import 'package:nova_modest/features/catalog/domain/entities/product.dart';

/// How a result set is ordered.
///
/// A domain value with the ordering on it, not a `switch` in a widget: which
/// products come first is a rule about the data
/// (`01-flutter-architecture-guard.md`).
enum ProductSort {
  /// Whatever order the catalogue returned — its own idea of relevance for the
  /// query, which no client-side comparator can reconstruct.
  relevance,
  priceAscending,
  priceDescending;

  /// [products] in this order. Never sorts in place: the unsorted list is the
  /// state's, and mutating it would make `relevance` unrecoverable.
  List<Product> apply(List<Product> products) => switch (this) {
    ProductSort.relevance => products,
    ProductSort.priceAscending => [
      ...products,
    ]..sort((a, b) => a.price.compareTo(b.price)),
    ProductSort.priceDescending => [
      ...products,
    ]..sort((a, b) => b.price.compareTo(a.price)),
  };
}
