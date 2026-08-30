# nova_modest

Arabic-first modest-fashion shop. The live backend is a local Supabase
project in `supabase/`.

## Local backend

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started).
2. Start the stack from this directory:

```bash
supabase start
```

3. Copy `config/dev.json.example` to `config/dev.json` (gitignored). After
   `supabase start`, confirm the printed anon key matches the example.
4. Read emailed one-time codes in Inbucket: http://127.0.0.1:55324
5. Studio: http://127.0.0.1:55323
6. Run the app:

```bash
flutter run --dart-define-from-file=config/dev.json
```

Ports use **55321–55329** instead of the usual 54321 range because Windows
reserves 54297–54396 on this machine.

Android emulator traffic is rewritten from `127.0.0.1` to `10.0.2.2` in
`SupabaseEnv`. Google sign-in needs a web client ID and the Google provider
enabled in Supabase; email OTP works locally without that.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
