import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_feature.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';

/// Stands in for the catalogue backend.
///
/// Registered in the `test` environment. The running app uses
/// `SupabaseCatalogRepository`.
///
/// The rows below carry the design's own copy and prices, so every screen is
/// built against the content it was designed for rather than lorem ipsum.
/// Product, category and tag names are **data**, not UI strings: they come from
/// the backend, so they are deliberately not in the ARB files — which is why
/// they stay Arabic under an English UI.
///
/// `imageUrl` is null throughout - there is no artwork yet, and the card draws a
/// palette placeholder instead. Supplying URLs later changes nothing else.
@LazySingleton(as: CatalogRepository, env: [Environment.test])
class FakeCatalogRepository implements CatalogRepository {
  const FakeCatalogRepository();

  /// Long enough for the loading state to be real, short enough not to irritate.
  static const Duration _latency = Duration(milliseconds: 600);

  static const List<ProductCategory> _categories = [
    ProductCategory(id: 'abayas', name: 'عبايات'),
    ProductCategory(id: 'hijab-shawls', name: 'حجاب وشالات'),
    ProductCategory(id: 'sets', name: 'أطقم'),
    ProductCategory(id: 'accessories', name: 'إكسسوارات'),
  ];

  static const ProductTag _daily = ProductTag(id: 'daily', name: 'يومي');
  static const ProductTag _occasions = ProductTag(
    id: 'occasions',
    name: 'مناسبات',
  );
  static const ProductTag _colourful = ProductTag(
    id: 'colourful',
    name: 'ملون',
  );

  // The garment's own colours — content, not palette. Rendered as themselves,
  // because a swatch that showed anything else would misinform the shopper
  // (`12-flutter-design-system-guard.md` does not apply to product data).
  static const List<ProductColour> _colours = [
    ProductColour(id: 'light-grey', name: 'رمادي فاتح', hex: '#D1D5DB'),
    ProductColour(id: 'grey', name: 'رمادي', hex: '#6B7280'),
    ProductColour(id: 'black', name: 'أسود', hex: '#000000'),
  ];

  static const List<String> _sizes = ['S', 'M', 'L', 'XL'];

  static const List<ProductFeature> _features = [
    ProductFeature(text: 'قماش كريب فاخر', icon: 'fabric'),
    ProductFeature(text: 'قصة واسعة مريحة', icon: 'fit'),
    ProductFeature(text: 'يفضل الغسيل الجاف', icon: 'care'),
  ];

  /// The design's own description (Figma `1:2584`). One sample serves every row
  /// — a fake should carry the copy it was designed against, not invent a
  /// different paragraph per product.
  static const String _description =
      'عباية كلاسيكية مصممة بعناية من أجود أنواع قماش الكريب السعودي، '
      'توفر لك إطلالة أنيقة وعملية في آن واحد. تتميز بقصة مريحة تضمن حرية '
      'الحركة، مع تفاصيل بسيطة تضفي لمسة من الفخامة. مناسبة للارتداء اليومي '
      'والمناسبات الخاصة.';

  /// One catalogue. [featuredProducts] takes a slice of it and
  /// [productsInCategory] filters it — neither keeps a list of its own, so the
  /// two screens can never drift apart.
  static const List<Product> _products = [
    Product(
      id: 'p1',
      name: 'عباءة كلاسيكية باللون الزيتي',
      price: 450,
      categoryId: 'abayas',
      description: _description,
      colours: _colours,
      sizes: _sizes,
      features: _features,
      tags: [_colourful, _daily],
    ),
    Product(
      id: 'p2',
      name: 'عباءة سوداء بتفاصيل عصرية',
      price: 520,
      categoryId: 'abayas',
      description: _description,
      colours: _colours,
      sizes: _sizes,
      features: _features,
      tags: [_occasions],
    ),
    Product(
      id: 'p3',
      name: 'شيلة حريرية فاخرة',
      price: 120,
      categoryId: 'hijab-shawls',
      description: _description,
      colours: _colours,
      sizes: _sizes,
      features: _features,
      tags: [_occasions],
    ),
    Product(
      id: 'p4',
      name: 'طقم مريح بلون ترابي',
      price: 380,
      categoryId: 'sets',
      description: _description,
      colours: _colours,
      sizes: _sizes,
      features: _features,
      tags: [_daily],
    ),
    // From the listing design (Figma `1:2671`).
    Product(
      id: 'p5',
      name: 'عباية حرير مغسول',
      price: 850,
      categoryId: 'abayas',
      description: _description,
      colours: _colours,
      sizes: _sizes,
      features: _features,
      tags: [_occasions],
    ),
    Product(
      id: 'p6',
      name: 'عباية كتان يومية',
      price: 620,
      categoryId: 'abayas',
      // The design's sold-out card. Kept in the data rather than faked in the
      // widget, so every screen showing this product agrees.
      isSoldOut: true,
      description: _description,
      colours: _colours,
      sizes: _sizes,
      features: _features,
      tags: [_daily],
    ),
    Product(
      id: 'p7',
      name: 'عباية رسمية كحلية',
      price: 950,
      categoryId: 'abayas',
      description: _description,
      colours: _colours,
      sizes: _sizes,
      features: _features,
      tags: [_occasions, _colourful],
    ),
    Product(
      id: 'p8',
      name: 'عباية كريب صيفية',
      price: 780,
      categoryId: 'abayas',
      description: _description,
      colours: _colours,
      sizes: _sizes,
      features: _features,
      tags: [_daily, _colourful],
    ),
  ];

  /// How much of the catalogue Home shows.
  ///
  /// "Featured" is a selection, not the whole shelf. Returning everything here
  /// would have silently doubled Home's grid the moment the listing's products
  /// were added to the list above.
  static const int _featuredCount = 4;

  @override
  Future<Result<List<ProductCategory>>> categories() async {
    await Future<void>.delayed(_latency);
    return const Ok(_categories);
  }

  @override
  Future<Result<List<Product>>> featuredProducts() async {
    await Future<void>.delayed(_latency);
    return Ok(_products.take(_featuredCount).toList());
  }

  @override
  Future<Result<Product>> productById(String id) async {
    await Future<void>.delayed(_latency);
    final match = _products.where((product) => product.id == id);
    if (match.isEmpty) {
      return const Err(NotFoundFailure());
    }
    return Ok(match.first);
  }

  @override
  Future<Result<List<Product>>> productsInCategory(String categoryId) async {
    await Future<void>.delayed(_latency);
    return Ok(
      _products.where((product) => product.categoryId == categoryId).toList(),
    );
  }

  @override
  Future<Result<List<Product>>> searchProducts(String query) async {
    await Future<void>.delayed(_latency);

    final needle = _normalise(query);
    if (needle.isEmpty) return const Ok(<Product>[]);

    return Ok([
      for (final product in _products)
        if (_haystack(product).contains(needle)) product,
    ]);
  }

  @override
  Future<Result<List<String>>> trendingSearches() async {
    await Future<void>.delayed(_latency);
    return const Ok(_trending);
  }

  /// The terms offered before anything is typed.
  ///
  /// Drawn from the catalogue's own category and tag names rather than from the
  /// design's five invented phrases, so **every** term returns results. A list
  /// that reads well and matches nothing is a worse fake than one that is a
  /// little duller: it makes the screen look broken.
  static const List<String> _trending = [
    'عبايات',
    'حجاب وشالات',
    'مناسبات',
    'أطقم',
    'يومي',
  ];

  /// Everything about a product a query may match: its name, the category it
  /// sits in, and the tags it carries.
  static String _haystack(Product product) {
    final category = _categories
        .where((entry) => entry.id == product.categoryId)
        .map((entry) => entry.name);
    return _normalise(
      [
        product.name,
        ...category,
        for (final tag in product.tags) tag.name,
      ].join(' '),
    );
  }

  /// Folds away the differences an Arabic shopper does not type consistently.
  ///
  /// A backend's search index does exactly this, which is why it lives behind
  /// the seam rather than in a bloc. Without it "عبايه" finds nothing while
  /// "عباية" finds eight rows, and the screen looks broken to the person who
  /// typed it the ordinary way.
  static String _normalise(String input) {
    const alef = 'أإآٱ';
    final buffer = StringBuffer();

    for (final rune in input.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      // Harakat and tatweel carry no meaning for matching.
      if (rune >= 0x064B && rune <= 0x0652) continue;
      if (rune == 0x0640) continue;
      if (alef.contains(char)) {
        buffer.write('ا');
      } else if (char == 'ة') {
        buffer.write('ه');
      } else if (char == 'ى') {
        buffer.write('ي');
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }
}
