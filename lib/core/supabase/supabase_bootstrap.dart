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

  await Supabase.initialize(
    url: SupabaseEnv.url,
    anonKey: SupabaseEnv.anonKey,
    // **Not the default.** `supabase_flutter` defaults to PKCE
    // (`gotrue_client.dart`: `AuthFlowType flowType = AuthFlowType.pkce`), and
    // PKCE is incompatible with the sign-in this app actually has.
    //
    // Under PKCE, `signInWithOtp` sends a `code_challenge` and the server binds
    // the emailed token to a flow row; redeeming it means
    // `exchangeCodeForSession(authCode)`, and that `auth_code` arrives in a
    // **link**, never in six typed digits. `verifyOTP` has no PKCE branch at
    // all — its body is `{email, token, type, …}` with no `code_verifier` — so
    // every verification failed with 403 `otp_expired` no matter how fresh the
    // code was.
    //
    // The evidence: three rows in `auth.flow_state`, `code_challenge_method`
    // s256, `auth_code_issued_at` null — one per attempt from the app, and
    // none for the same requests issued without a challenge, which succeeded.
    //
    // Implicit is the flow a typed one-time code belongs to. PKCE guards the
    // redirect hop that this design does not have: the shopper reads six digits
    // off a screen and types them (Figma `1:2438`). Adopting PKCE properly
    // would mean emailing a link instead, handling deep links on every
    // platform, and deleting that screen — a different product, not a fix.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );
}
