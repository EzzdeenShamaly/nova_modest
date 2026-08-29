import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';

part 'product_filter_options.freezed.dart';

/// What a [ProductFilter] can currently be set to, derived from the products
/// in hand.
///
/// Derived rather than fetched, exactly as the listing already derives its
/// tags: an option that cannot match anything on screen is a dead control, and
/// the catalogue already says which sizes, colours and tags its products carry.
/// It also means no facet is ever invented — the design's fixed XS–XL and
/// five-colour rows would offer choices this catalogue cannot satisfy.
@freezed
abstract class ProductFilterOptions with _$ProductFilterOptions {
  const ProductFilterOptions._();

  const factory ProductFilterOptions({
    @Default(<ProductCategory>[]) List<ProductCategory> categories,
    @Default(<ProductTag>[]) List<ProductTag> tags,
    @Default(<String>[]) List<String> sizes,
    @Default(<ProductColour>[]) List<ProductColour> colours,
    num? minPrice,
    num? maxPrice,
  }) = _ProductFilterOptions;

  /// The options [products] support.
  ///
  /// [categories] is the catalogue's own list, kept only where a product on
  /// screen belongs to it — products carry a `categoryId` but not its name, and
  /// the name is data the backend owns rather than an ARB string.
  ///
  /// Everything is in first-seen order and de-duplicated: the catalogue's order
  /// is a decision it already made, and re-sorting would be inventing another.
  static ProductFilterOptions from(
    List<Product> products, {
    List<ProductCategory> categories = const [],
  }) {
    final categoryIds = <String>{};
    final tags = <ProductTag>[];
    final tagIds = <String>{};
    final sizes = <String>[];
    final sizeSet = <String>{};
    final colours = <ProductColour>[];
    final colourIds = <String>{};
    num? min;
    num? max;

    for (final product in products) {
      categoryIds.add(product.categoryId);
      for (final tag in product.tags) {
        if (tagIds.add(tag.id)) tags.add(tag);
      }
      for (final size in product.sizes) {
        if (sizeSet.add(size)) sizes.add(size);
      }
      for (final colour in product.colours) {
        if (colourIds.add(colour.id)) colours.add(colour);
      }
      if (min == null || product.price < min) min = product.price;
      if (max == null || product.price > max) max = product.price;
    }

    return ProductFilterOptions(
      categories: [
        for (final category in categories)
          if (categoryIds.contains(category.id)) category,
      ],
      tags: tags,
      sizes: sizes,
      colours: colours,
      minPrice: min,
      maxPrice: max,
    );
  }

  /// Whether a facet is worth showing at all.
  ///
  /// One option cannot narrow anything — every product already matches it — so
  /// a single-category listing hides the category section instead of drawing a
  /// checkbox that does nothing. This is what lets one sheet serve both the
  /// listing and search without either carrying a special case.
  bool get hasCategories => categories.length > 1;
  bool get hasTags => tags.length > 1;
  bool get hasSizes => sizes.length > 1;
  bool get hasColours => colours.length > 1;

  /// A range needs two different ends to be draggable.
  bool get hasPriceRange =>
      minPrice != null && maxPrice != null && minPrice! < maxPrice!;

  bool get isEmpty =>
      !hasCategories && !hasTags && !hasSizes && !hasColours && !hasPriceRange;
}
