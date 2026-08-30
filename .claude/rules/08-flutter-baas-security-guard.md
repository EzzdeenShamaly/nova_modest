## What This Rule Does

Installed by `/platform-init` when a project has a BaaS data source. **This
project has one**: Supabase, added 2026-08-29 alongside the existing REST seam.

`06-flutter-error-guard` §7 covers what a BaaS failure *becomes* — which
exception maps to which `Failure`. This rule covers what produces those failures
in the first place: the policies, the functions and the keys. The two are one
subject read from opposite ends, and the row that joins them is this:

> **`42501` and `PGRST301` are authorisation failures, not network failures.**
> Mapping either to `NetworkFailure` shows a shopper "check your connection" for
> a missing policy, and hides a real defect — possibly for months, because the
> app works on the developer's own account.

---

## 1. The server is the security boundary. The app is not.

Every rule below follows from one fact: **a Supabase anon key ships inside the
app**. Anyone holding the binary can issue any query the key allows. So:

- **Never** rely on a screen not offering an action to prevent it. `/orders` is
  behind the sign-in gate *and* `orders_select_own` restricts rows to
  `auth.uid()`. The gate is a convenience; the policy is the control.
- **Never** filter by user id in Dart and treat that as protection. A `.eq('user_id', …)`
  the client chooses is a client-side filter, not a boundary.
- A repository that reads someone's own rows should carry **no** user predicate
  at all: RLS applies it. `SupabaseOrderRepository.orders()` selects from
  `orders` with no `where`, and that is correct.

## 2. RLS on every table, and a policy for every intended access

`alter table … enable row level security` is deny-all until a policy grants
something. Both halves are required:

- **RLS enabled and no policy** is a table nothing can touch. That is a valid
  and deliberate state — `order_number_sequences` is exactly this, reachable
  only through a `security definer` function — but it must be *chosen*, never
  the result of forgetting the policy.
- **A policy without RLS enabled** grants nothing and protects nothing; the
  table is wide open and the policy is decoration.

When adding a table, state which of the two you intended in the migration.

## 3. `security definer` is a hole you open on purpose

A `security definer` function runs as its owner and **bypasses RLS entirely**.
`place_order` is one, and has to be: it prices lines from the catalogue, takes
the day's next number from a table nothing else may touch, and inserts an order
with its items — one transaction, not four round trips a phone could interleave.

Every such function must:

- `set search_path = public`, so a caller cannot shadow a table name.
- Validate its own input. `place_order` re-checks the contact, the address, the
  item count, the quantity range and the payment method, and raises `P0001` —
  because the client's identical checks are a courtesy, not a guarantee.
- **Price from the database, never from the payload.** `place_order` reads
  `products.price` and computes the subtotal itself; a client-supplied total
  would let anyone buy anything for zero.
- Be granted narrowly: `grant execute … to anon, authenticated`, nothing wider.

## 4. Keys, and what may be committed

- The **anon/publishable key** is public by design and belongs in
  `--dart-define-from-file`, not in source. `config/dev.json` is git-ignored;
  `config/dev.json.example` is the committed shape.
- The **service-role key bypasses every policy**. It must never appear in the
  app, in `config/`, in a test, or in CI logs. If one is ever pasted into this
  repo, treat it as leaked and rotate it — moving it to another committed file
  is not a fix (`03-flutter-security-guard`).
- `SupabaseEnv` reads both through `String.fromEnvironment`, and
  `initializeSupabase()` throws rather than starting with an empty key — a
  missing key should stop the app, not silently produce a client that fails
  every call with something that looks like a network error.

## 5. One SDK seam, as with `dio`

`supabase_flutter` may be imported by:

- `lib/core/supabase/` — bootstrap, env, error mapping.
- `lib/features/*/data/repositories/supabase_*_repository.dart`.

Nothing else. **No bloc, screen or widget imports it**, exactly as nothing above
`core/network/` imports `dio`. `Supabase.instance.client` is read inside the
repositories rather than registered in `get_it`, so the test environment never
constructs one.

## 6. Migrations are append-only

A migration that has run is history. Change behaviour by adding a file, never by
editing one that shipped — an edited migration is applied on a fresh database
and not on an existing one, so the two diverge silently.

`alter type … add value` cannot be used in the same transaction that uses the
new value, so an enum change and its first use are two files.

## 7. The environments are the fakes' whole purpose

Repositories are bound per environment:

```dart
@LazySingleton(as: OrderRepository, env: [Environment.test])   // the fake
@LazySingleton(as: OrderRepository, env: [Environment.dev])    // Supabase
```

The suite runs `configureDependencies(environment: Environment.test)` and never
touches a network. **A test that needs a live Supabase is not a unit test** — it
is an integration test and belongs in `integration_test/`, which this project
does not yet have.

What *is* unit-testable in a Supabase repository is the mapping: column names,
status strings, and the fact that Postgres sends `numeric` as a string often
enough that assuming `num` is how these classes break first. See
`test/features/orders/supabase_order_mapping_test.dart`.

## Relationship to Other Rules

- `06-flutter-error-guard` §7 — the failure mapping this rule's policies produce.
- `03-flutter-security-guard` — secrets, and why no key is committed.
- `10-evidence-and-dependency-guard` — confirm a table, column or policy exists
  before writing a query against it. A wrong column name is a runtime error, not
  a compile-time one.
