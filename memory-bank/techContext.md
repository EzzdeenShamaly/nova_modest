# Tech Context

**Last Updated:** _not yet synced_
**Locked by:** _`/platform-init` has NOT run — this project has no state-management decision yet_

> This file is **Tier 1**. `/platform-init` writes the locked stack once;
> `/context-sync` refreshes the observed reality around it on every sync and
> never rewrites the lock.
>
> While the `Locked by:` line above still says "has NOT run", no
> `flutter-*-gen` skill will generate state code — it would be a guess. Run
> `/platform-init` first. It asks one question.

## Template (filled by `/platform-init`, then refreshed by `/context-sync`)

- Flutter/Dart SDK: `[from pubspec.yaml environment constraint]`
- State management: `[Cubit | Bloc | Riverpod]` — state lives in `[folder]`
- Error handling: `[Result<Failure,T> + fold | thrown Failure + AsyncValue.guard]`
- DI: `[get_it + injectable | Riverpod providers]`
- Routing: `[go_router]`, shell routes: `[yes/no]`
- Models: `[freezed + json_serializable]`
- HTTP client: `dio`, behind `lib/core/network/api_client.dart` — leaks above core: `[n]`
- Secure storage: `[flutter_secure_storage | none detected]`
- Testing: `[bloc_test + mocktail | ProviderContainer + mocktail]`, integration_test: `[yes/no]`
- Localization: `[intl/ARB present | none detected]`

> EXAMPLE — what a filled-in file looks like:
>
> **Last Updated:** 2026-08-15
> **Locked by:** `/platform-init`
>
> - Flutter/Dart SDK: `>=3.5.0 <4.0.0`
> - State management: **Cubit** (`flutter_bloc`) — state in `features/<f>/presentation/cubit/`
> - Error handling: `Result<Failure, T>` + `fold`; shared hierarchy in `core/error/`
> - DI: `get_it` + `injectable`
> - Routing: `go_router`, shell routes: yes (bottom-nav shell for the authenticated area)
> - Models: `freezed` + `json_serializable`, one class per entity
> - HTTP client: `dio` behind `core/network/api_client.dart` — leaks above core: 0
> - Secure storage: `flutter_secure_storage` (auth tokens only)
> - Testing: `bloc_test` + `mocktail`, integration_test: no
> - Localization: ARB files under `lib/l10n/`, `en` + `ar`
