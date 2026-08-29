import 'package:nova_modest/core/supabase/supabase_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only place [Supabase.initialize] is called.
///
/// Repositories then read [Supabase.instance.client]. The client is not
/// registered in get_it so the test environment never has to construct it.
Future<void> initializeSupabase() async {
  if (SupabaseEnv.anonKey.isEmpty) {
    throw StateError(
      'SUPABASE_ANON_KEY is missing. Copy config/dev.json.example to '
      'config/dev.json and run with --dart-define-from-file=config/dev.json.',
    );
  }

  await Supabase.initialize(url: SupabaseEnv.url, anonKey: SupabaseEnv.anonKey);
}
