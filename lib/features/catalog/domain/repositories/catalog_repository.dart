import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';

/// The catalogue seam.
///
/// Same arrangement as `AuthRepository`: a fake carries the app until the
/// backend exists, and swapping in the real implementation is one registration
/// line — no bloc, widget or test above this interface changes.
///
/// One repository serves every catalogue screen. Home and the product listing
/// read the same rows through different queries rather than each carrying its
/// own data.
abstract class CatalogRepository {
  /// Categories for the Home filter row, in display order.
  Future<Result<List<ProductCategory>>> categories();

  /// Products for the Home grid.
  ///
  /// A curated subset, not the whole catalogue — "featured" is a selection the
  /// backend makes, and Home is not a listing screen.
  Future<Result<List<Product>>> featuredProducts();

  /// Every product in one category, for the listing screen.
  Future<Result<List<Product>>> productsInCategory(String categoryId);

  /// Every product matching a free-text [query], for the search screen.
  ///
  /// An empty or whitespace-only query is an empty result, not the whole
  /// catalogue: "show me everything" is what the listing is for.
  ///
  /// Matching is the backend's business — which fields count and how text is
  /// normalised are decisions that belong behind this seam, not in a bloc.
  Future<Result<List<Product>>> searchProducts(String query);

  /// Terms to offer before the shopper has typed anything.
  ///
  /// A curated list the backend owns, like [featuredProducts]. Not derived from
  /// the shopper's own history — that is a separate concern with separate
  /// storage.
  Future<Result<List<String>>> trendingSearches();

  /// One product, with its detail fields populated.
  ///
  /// An unknown id is a [NotFoundFailure], not an empty result: asking for a
  /// product that does not exist is a different thing from a category that
  /// happens to be empty.
  Future<Result<Product>> productById(String id);
}
