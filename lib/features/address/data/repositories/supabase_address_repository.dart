import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/supabase/supabase_error_mapper.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/domain/repositories/address_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live [AddressRepository] against `user_addresses`.
@LazySingleton(as: AddressRepository, env: [Environment.dev])
class SupabaseAddressRepository implements AddressRepository {
  const SupabaseAddressRepository();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Result<List<Address>>> addresses() async {
    try {
      return Ok(await _fetchSorted());
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<List<Address>>> save(Address address) async {
    try {
      final userId = _requireUserId();
      final row = _toRow(address, userId);

      if (address.id.isEmpty) {
        await _client.from('user_addresses').insert(row);
      } else {
        final updated = await _client
            .from('user_addresses')
            .update(row)
            .eq('id', address.id)
            .eq('user_id', userId)
            .select();
        if (updated.isEmpty) {
          return const Err(NotFoundFailure());
        }
      }

      return Ok(await _fetchSorted());
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<List<Address>>> remove(String id) async {
    try {
      final userId = _requireUserId();
      final deleted = await _client
          .from('user_addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', userId)
          .select();
      if (deleted.isEmpty) {
        return const Err(NotFoundFailure());
      }
      return Ok(await _fetchSorted());
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<List<Address>>> setDefault(String id) async {
    try {
      final userId = _requireUserId();
      final updated = await _client
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', id)
          .eq('user_id', userId)
          .select();
      if (updated.isEmpty) {
        return const Err(NotFoundFailure());
      }
      return Ok(await _fetchSorted());
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  Future<List<Address>> _fetchSorted() async {
    final userId = _requireUserId();
    final rows = await _client
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    final addresses = [for (final row in rows) Address.fromJson(row)];
    return [
      ...addresses.where((address) => address.isDefault),
      ...addresses.where((address) => !address.isDefault),
    ];
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedFailure();
    }
    return userId;
  }

  Map<String, dynamic> _toRow(Address address, String userId) {
    final json = address.toJson()..remove('id');
    json['user_id'] = userId;
    return json;
  }
}
