import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';

part 'product_filter.freezed.dart';

/// Every way the catalogue can be narrowed, as one value.
///
/// There is deliberately **one** filter model for the whole app rather than one
/// per screen. The product listing narrows by tag and the search screen by
/// category, price, size and colour — but "apply a filter to products already
/// in hand" is the same operation in both, and writing it twice is how two
/// screens drift into two different ideas of what filtering means.
///
/// [apply] is a pure function of the value and the list, so it is tested
/// directly rather than through a bloc.
@freezed
abstract class ProductFilter with _$ProductFilter {
  const ProductFilter._();

  const factory ProductFilter({
    /// Empty means every category. Products match if they are in **any** of
    /// them — facets are OR within, AND between.
    @Default(<String>{}) Set<String> categoryIds,

    /// Single-select, unlike the others: the listing's chip row has one "All"
    /// chip and one active tag, which is a different affordance from a
    /// checkbox list.
    String? tagId,
    num? minPrice,
    num? maxPrice,
    @Default(<String>{}) Set<String> sizes,
    @Default(<String>{}) Set<String> colourIds,
  }) = _ProductFilter;

  /// Nothing narrowed. The starting value on every screen.
  static const ProductFilter none = ProductFilter();

  /// How many facets are narrowing, for the badge on the filter control.
  ///
  /// A price range counts once however many of its two ends are set.
  int get activeCount => [
    categoryIds.isNotEmpty,
    tagId != null,
    minPrice != null || maxPrice != null,
    sizes.isNotEmpty,
    colourIds.isNotEmpty,
  ].where((active) => active).length;

  bool get isEmpty => activeCount == 0;

  /// [products] narrowed to those matching every active facet.
  List<Product> apply(List<Product> products) => [
    for (final product in products)
      if (_matches(product)) product,
  ];

  bool _matches(Product product) {
    if (categoryIds.isNotEmpty && !categoryIds.contains(product.categoryId)) {
      return false;
    }
    if (tagId != null && !product.tags.any((tag) => tag.id == tagId)) {
      return false;
    }
    if (minPrice case final floor? when product.price < floor) return false;
    if (maxPrice case final ceiling? when product.price > ceiling) return false;
    // A garment offered in no sizes at all cannot satisfy a size filter, so it
    // drops out rather than passing through unchecked.
    if (sizes.isNotEmpty && !product.sizes.any(sizes.contains)) return false;
    if (colourIds.isNotEmpty &&
        !product.colours.any((colour) => colourIds.contains(colour.id))) {
      return false;
    }
    return true;
  }
}
