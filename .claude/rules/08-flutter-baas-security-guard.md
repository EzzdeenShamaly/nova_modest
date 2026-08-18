---
description: With Firebase or Supabase the database rules are the only thing between the app and the data — treat Security Rules and RLS policies as source code, not dashboard settings
applies-to: projects whose techContext.md locks a Firebase or Supabase data source
---

## What This Rule Does

`03-flutter-security-guard` assumes the server is somewhere else — that a
backend you do not control validates every request, and the client's job is to
keep its credentials safe. With a BaaS backend that assumption is false, and
following only `03` will ship an app with an open database.

This rule covers what changes when the database is directly reachable from the
client.

**Install condition:** only when `techContext.md` locks a Firebase or Supabase
data source. `/platform-init` installs it; a pure REST project never sees it.
A hybrid project (Firebase Auth + REST data) **does** get it — the auth surface
alone is enough.

## The Shift

| REST backend | Firebase / Supabase |
|---|---|
| Authorisation lives on a server you cannot touch from Flutter | **Authorisation lives in your repo**, as rules or policies |
| A bad client request is rejected server-side | **The rule set is the only thing rejecting it** |
| The API key is a secret | **The anon / public key ships inside the APK by design** |
| Adding a table changes nothing about client security | **Adding a table without a policy exposes it** |

The consequence: the single highest-severity defect in a BaaS Flutter app is
not a leaked key. It is a table with row-level security disabled.

## Non-Negotiables

### 1. No table without a policy

Supabase: RLS enabled on every table in `public`, plus at least one policy.
A table with RLS **enabled and zero policies** is closed (safe but broken);
a table with RLS **disabled** is world-readable to anyone holding the anon
key, which is everyone who has the app.

Firestore: every collection covered by a rule. The default-deny root match is
the floor, not the ceiling.

This is a **`NO-GO`** item in `/production-readiness-review`, not a warning.

### 2. Rules and policies are source code

- `firestore.rules`, `storage.rules`, and Supabase migrations live in the repo
  and are reviewed like Dart.
- **Never** instruct the user to make an authorisation change in the web
  dashboard. Dashboard edits are invisible to git, invisible to review, and
  lost on the next environment.
- If the user says a policy was set in the dashboard, tell them plainly that
  it needs to be captured as a migration or a rules file before release.

### 3. `allow read, write: if true` is forbidden

Including "temporarily", including "just for development", including behind a
comment saying it will be fixed later. Firebase's own test-mode default expires
for a reason. If the agent is asked to write this, refuse and offer a
user-scoped rule instead.

The Supabase equivalent — a policy with `USING (true)` on a table holding
anything user-specific — is the same violation.

### 4. Client-side filtering is not authorisation

```dart
// This is a UX optimisation. It is NOT security.
await client.from('orders').select().eq('user_id', currentUser.id);
```

Anyone can call the same endpoint without the filter. The policy must enforce
ownership server-side:

```sql
create policy "own orders" on orders
  for select using (auth.uid() = user_id);
```

When generating a query with an ownership filter, state in the summary that a
matching policy is required, and say whether one was found.

### 5. `service_role` never enters the client

The Supabase `service_role` key **bypasses RLS entirely**. It belongs in an
Edge Function or a server, never in `lib/`, never in `--dart-define`, never in
a `.env` the app reads. Same for a Firebase Admin SDK service-account JSON.

Enforced by `.github/workflows/flutter-ci.yml`; also refuse at write time.

### 6. The anon key is public — do not hide it

The Supabase anon key and the Firebase `google-services.json` / web API key
are **designed** to ship in the client. They identify the project; they do not
grant access.

Do not waste effort obfuscating them, do not treat their presence as a finding,
and do not let their presence create false confidence. What protects the data
is the policy. Say so when the user asks.

`guard-write.mjs` blocks hardcoded secrets by pattern; a public anon key in a
config file is not that, and should not be reported as one.

### 7. Storage buckets are tables too

`storage.objects` needs policies exactly like any other table. A public bucket
is a deliberate choice for avatars and a data breach for documents. Ask which
one it is; do not assume.

## Failure Mapping

`permission-denied` (Firebase) and Postgres error `42501` (Supabase) are **not
network failures**. They mean a rule rejected the request. Mapping them to
`NetworkFailure` sends the user a "check your connection" message for an
authorisation bug and hides it for months.

Both map to `UnauthorizedFailure`. See `06-flutter-error-guard` §7.

When `/flutter-debug` sees either code, the first hypothesis is the rule set,
not the query.

## Relationship to Other Rules

- `03-flutter-security-guard` — still applies in full. This rule adds to it.
- `06-flutter-error-guard` §7 — the BaaS exception-to-`Failure` tables.
- `01-flutter-architecture-guard` — the BaaS SDK stays behind the data-source
  seam. `supabase_flutter` and `cloud_firestore` are imported in exactly one
  layer, same as `dio`.
