import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/supabase/supabase_error_mapper.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_feature.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live [CatalogRepository] against PostgREST + `search_product_ids`.
@LazySingleton(as: CatalogRepository, env: [Environment.dev])
class SupabaseCatalogRepository implements CatalogRepository {
  const SupabaseCatalogRepository();

  static const String _productSelect =
      'id, name, price, category_id, image_url, is_sold_out, description, '
      'product_colours (id, name, hex), '
      'product_sizes (size, sort_order), '
      'product_features (text, icon, sort_order), '
      'product_tag_assignments (product_tags (id, name))';

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Result<List<ProductCategory>>> categories() async {
    try {
      final rows = await _client
          .from('product_categories')
          .select()
          .order('sort_order');
      return Ok(
        [for (final row in rows) ProductCategory.fromJson(row)],
      );
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<List<Product>>> featuredProducts() async {
    try {
      final rows = await _client
          .from('products')
          .select(_productSelect)
          .eq('is_featured', true)
          .order('id');
      return Ok([for (final row in rows) _productFromRow(row)]);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<List<Product>>> productsInCategory(String categoryId) async {
    try {
      final rows = await _client
          .from('products')
          .select(_productSelect)
          .eq('category_id', categoryId)
          .order('id');
      return Ok([for (final row in rows) _productFromRow(row)]);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<List<Product>>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return const Ok(<Product>[]);
      }

      final matches = await _client.rpc<List<dynamic>>(
        'search_product_ids',
        params: {'p_query': query},
      );
      final ids = [
        for (final row in matches)
          if (row is Map<String, dynamic>) row['id'] as String,
      ];
      if (ids.isEmpty) return const Ok(<Product>[]);

      final rows = await _client
          .from('products')
          .select(_productSelect)
          .inFilter('id', ids);
      return Ok([for (final row in rows) _productFromRow(row)]);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<List<String>>> trendingSearches() async {
    try {
      final rows = await _client
          .from('trending_searches')
          .select('term')
          .order('sort_order');
      return Ok([
        for (final row in rows) row['term'] as String,
      ]);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<Product>> productById(String id) async {
    try {
      final row = await _client
          .from('products')
          .select(_productSelect)
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        return const Err(NotFoundFailure());
      }
      return Ok(_productFromRow(row));
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  Product _productFromRow(Map<String, dynamic> row) {
    final colours = [
      for (final colour in (row['product_colours'] as List<dynamic>? ?? []))
        ProductColour.fromJson(Map<String, dynamic>.from(colour as Map)),
    ];

    final sizeRows = [
      ...(row['product_sizes'] as List<dynamic>? ?? []),
    ]..sort((a, b) {
      final aOrder = (a as Map)['sort_order'] as int? ?? 0;
      final bOrder = (b as Map)['sort_order'] as int? ?? 0;
      return aOrder.compareTo(bOrder);
    });
    final sizes = [
      for (final size in sizeRows) (size as Map)['size'] as String,
    ];

    final featureRows = [
      ...(row['product_features'] as List<dynamic>? ?? []),
    ]..sort((a, b) {
      final aOrder = (a as Map)['sort_order'] as int? ?? 0;
      final bOrder = (b as Map)['sort_order'] as int? ?? 0;
      return aOrder.compareTo(bOrder);
    });
    final features = [
      for (final feature in featureRows)
        ProductFeature.fromJson(
          Map<String, dynamic>.from(feature as Map)
            ..remove('sort_order'),
        ),
    ];

    final tags = [
      for (final assignment
          in (row['product_tag_assignments'] as List<dynamic>? ?? []))
        if ((assignment as Map)['product_tags'] is Map)
          ProductTag.fromJson(
            Map<String, dynamic>.from(assignment['product_tags'] as Map),
          ),
    ];

    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      price: _asNum(row['price']),
      categoryId: row['category_id'] as String,
      imageUrl: row['image_url'] as String?,
      isSoldOut: row['is_sold_out'] as bool? ?? false,
      description: row['description'] as String?,
      colours: colours,
      sizes: sizes,
      features: features,
      tags: tags,
    );
  }

  static num _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.parse(value);
    throw FormatException('Expected a number, got $value');
  }
}
