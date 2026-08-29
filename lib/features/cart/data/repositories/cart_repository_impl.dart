import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/cart/data/models/cart_line_dto.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/repositories/cart_repository.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SharedPreferences`-backed cart that stores ids and rehydrates from the
/// catalogue.
///
/// Plain preferences rather than `flutter_secure_storage`, for the same reason
/// the onboarding flag uses them: a list of product ids is not sensitive, and
/// `03-flutter-security-guard` reserves the keystore for tokens and PII.
///
/// Depends on [CatalogRepository] deliberately — rehydration is a data-layer
/// concern, so nothing above it ever learns that the cart is stored as ids.
@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._preferences, this._catalog);

  static const String _linesKey = 'cart.lines';

  final SharedPreferences _preferences;
  final CatalogRepository _catalog;

  @override
  Future<Result<List<CartItem>>> load() async {
    final stored = _readLines();
    return switch (stored) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => _hydrate(value),
    };
  }

  @override
  Future<Result<List<CartItem>>> add({
    required Product product,
    String? colourId,
    String? size,
    int quantity = 1,
  }) => _mutate((lines) {
    final index = lines.indexWhere(
      (line) =>
          line.productId == product.id &&
          line.colourId == colourId &&
          line.size == size,
    );

    if (index == -1) {
      return [
        ...lines,
        CartLineDto(
          productId: product.id,
          colourId: colourId,
          size: size,
          quantity: quantity.clamp(1, CartItem.maxQuantity),
        ),
      ];
    }

    // The same garment in the same colour and size is one line with a higher
    // count, not a second row.
    final merged = (lines[index].quantity + quantity).clamp(
      1,
      CartItem.maxQuantity,
    );
    return [...lines]..[index] = lines[index].copyWith(quantity: merged);
  });

  @override
  Future<Result<List<CartItem>>> updateQuantity(String lineId, int quantity) =>
      _mutate(
        (lines) => [
          for (final line in lines)
            if (_lineIdOf(line) == lineId)
              line.copyWith(quantity: quantity.clamp(1, CartItem.maxQuantity))
            else
              line,
        ],
      );

  @override
  Future<Result<List<CartItem>>> remove(String lineId) => _mutate(
    (lines) => [
      for (final line in lines)
        if (_lineIdOf(line) != lineId) line,
    ],
  );

  /// Read, transform, write, then return the resulting cart — the shape every
  /// mutation shares.
  Future<Result<List<CartItem>>> _mutate(
    List<CartLineDto> Function(List<CartLineDto> lines) change,
  ) async {
    final stored = _readLines();
    if (stored is Err<List<CartLineDto>>) return Err(stored.failure);

    final next = change((stored as Ok<List<CartLineDto>>).value);
    final written = await _writeLines(next);
    if (written is Err<void>) return Err(written.failure);

    return _hydrate(next);
  }

  /// Turns stored ids back into products.
  ///
  /// A product that has left the catalogue drops out rather than failing the
  /// whole screen — and storage is pruned so it does not cost a lookup again.
  /// Any other failure is real and propagates.
  Future<Result<List<CartItem>>> _hydrate(List<CartLineDto> lines) async {
    final items = <CartItem>[];
    final survivors = <CartLineDto>[];

    for (final line in lines) {
      final result = await _catalog.productById(line.productId);
      switch (result) {
        case Err(failure: NotFoundFailure()):
          continue;
        case Err(:final failure):
          return Err(failure);
        case Ok(:final value):
          survivors.add(line);
          items.add(
            CartItem(
              product: value,
              colourId: line.colourId,
              size: line.size,
              quantity: line.quantity,
            ),
          );
      }
    }

    if (survivors.length != lines.length) {
      final written = await _writeLines(survivors);
      if (written is Err<void>) return Err(written.failure);
    }

    return Ok(items);
  }

  Result<List<CartLineDto>> _readLines() {
    try {
      final raw = _preferences.getString(_linesKey);
      if (raw == null || raw.isEmpty) return const Ok(<CartLineDto>[]);

      final decoded = jsonDecode(raw) as List<dynamic>;
      return Ok([
        for (final entry in decoded)
          CartLineDto.fromJson(entry as Map<String, dynamic>),
      ]);
    } on PlatformException catch (_) {
      return const Err(CacheFailure('Could not read the saved cart.'));
    } on FormatException catch (_) {
      // Corrupt JSON. Reported rather than silently reset: quietly emptying
      // someone's cart is worse than telling them it could not be read.
      return const Err(CacheFailure('The saved cart could not be read.'));
    } on TypeError catch (_) {
      // Well-formed JSON of the wrong shape — an older or hand-edited value.
      return const Err(CacheFailure('The saved cart could not be read.'));
    }
  }

  Future<Result<void>> _writeLines(List<CartLineDto> lines) async {
    try {
      final encoded = jsonEncode([for (final line in lines) line.toJson()]);
      // setString reports whether the write landed; ignoring it would let a
      // failed save look like a success until the next launch.
      final written = await _preferences.setString(_linesKey, encoded);
      if (!written) {
        return const Err(CacheFailure('Could not save the cart.'));
      }
      return const Ok(null);
    } on PlatformException catch (_) {
      return const Err(CacheFailure('Could not save the cart.'));
    }
  }

  /// The stored counterpart of [CartItem.lineId] — kept in step with it so a
  /// line can be found without hydrating first.
  static String _lineIdOf(CartLineDto line) =>
      '${line.productId}|${line.colourId ?? ''}|${line.size ?? ''}';
}
