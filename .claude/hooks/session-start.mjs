#!/usr/bin/env node
// SessionStart - makes rule 00-memory-think deterministic.
// Injects a memory-bank Tier 1 digest plus repo-map freshness, so the agent
// starts every session already oriented instead of being asked to read files.

import { join } from "node:path";
import { readPayload, projectDir, readIfExists, ageInDays, inject } from "./_lib.mjs";

await readPayload();
const root = projectDir();
const mb = (f) => join(root, "memory-bank", f);

const TIER1 = ["activeContext.md", "progress.md", "techContext.md"];
const STALE_DAYS = 7;
const MAX_CHARS = 1400; // per file, keeps the digest bounded

const out = ["# Session context (auto-injected by .claude/hooks/session-start.mjs)"];
const problems = [];

// --- repo-map freshness -----------------------------------------------------
const mapPath = join(root, ".claude", "cache", "repo-map.json");
const mapAge = ageInDays(mapPath);
if (mapAge === null) {
  problems.push("`.claude/cache/repo-map.json` is MISSING - run `/repo-discovery` before generating or auditing code.");
} else if (mapAge > STALE_DAYS) {
  problems.push(`\`.claude/cache/repo-map.json\` is ${Math.floor(mapAge)} days old - run \`/repo-discovery\` to refresh.`);
} else {
  out.push(`\n**repo-map.json:** fresh (${Math.floor(mapAge)}d old).`);
}

// --- Tier 1 digest ----------------------------------------------------------
// A file full of [square-bracket] template slots is not context - it is the
// unfilled template. Flag it rather than injecting noise the agent will trust.
const placeholderMarker = /^\s*(>\s*)?(EXAMPLE|TODO|TBD|PLACEHOLDER|_?fill me in_?)/im;
const isUnfilledTemplate = (s) => {
  const lines = s.split("\n").filter(l => l.trim());
  if (!lines.length) return true;
  const slots = lines.filter(l => /\[[^\]]{3,}\]/.test(l) && !/\]\(/.test(l)).length;
  return slots / lines.length > 0.3;
};
let anyContent = false;

// --- the stack lock ---------------------------------------------------------
// Nothing in this kit is safe to generate before /platform-init has decided
// which state management this project uses. Surface that first.
const tech = readIfExists(mb("techContext.md"));
if (!tech || !/Locked by:\s*`?\/platform-init/i.test(tech)) {
  problems.push(
    "`/platform-init` has NOT run for this project - state management is undecided. " +
    "Run `/platform-init` before any flutter-*-gen skill; generating against a guess " +
    "is how a codebase ends up with two state-management styles."
  );
}

for (const f of TIER1) {
  const body = readIfExists(mb(f));
  if (body === null) { problems.push(`\`memory-bank/${f}\` not found.`); continue; }
  const trimmed = body.trim();
  if (!trimmed || trimmed.length < 60 || placeholderMarker.test(trimmed) || isUnfilledTemplate(trimmed)) {
    problems.push(`\`memory-bank/${f}\` is still an unfilled template - run \`/context-sync\` before trusting anything in it.`);
    continue;
  }
  anyContent = true;
  const age = ageInDays(mb(f));
  const stale = age !== null && age > STALE_DAYS ? ` _(stale: ${Math.floor(age)}d)_` : "";
  const clipped = trimmed.length > MAX_CHARS
    ? trimmed.slice(0, MAX_CHARS) + `\n... [truncated - read memory-bank/${f} in full if you need more]`
    : trimmed;
  out.push(`\n## memory-bank/${f}${stale}\n\n${clipped}`);
}

// --- always-on rules --------------------------------------------------------
out.push(`
## Binding rules this session (full text in .claude/rules/)

- **00-memory-think** - the digest above satisfies the read step. Re-read the
  full file if any of it looks contradictory or stale.
- **05-planning-rigor** - no plan/task board without an elicitation pass;
  always give options with tradeoffs.
- **13-plan-approval-gate** - for ANY new screen or feature, present the plan and
  WAIT for an explicit \"موافق\"/\"go ahead\" before writing a single file. Answers to
  clarifying questions, a design link, and \"continue\" are NOT approval. No
  exceptions for tasks that look simple.
- **09-minimal-changes** - change only what the task requires; minimise the diff.
  Temporary \`// DEBUG-TEMP:\` instrumentation is allowed during
  \`/flutter-debug\` and must never reach a commit.
- **07-flutter-direction-guard** - direction-neutral layout APIs in every
  project: \`EdgeInsetsDirectional\`, \`AlignmentDirectional\`,
  \`TextAlign.start\`. A physical \`left\`/\`right\` needs a
  \`// direction-fixed:\` tag naming the reason.
- **10-evidence-and-dependency-guard** - verify classes/providers/routes/
  pubspec.yaml packages exist before referencing them; never add a pub.dev
  package that is not already in pubspec.yaml.

Glob-scoped rules are NOT auto-loaded in Claude Code. Read from
\`.claude/rules/\` on demand:

| Touching | Read first |
|---|---|
| widgets, screens, feature \`.dart\` files | \`01-flutter-architecture-guard.md\` |
| cubits, blocs, notifiers, any state | \`02-flutter-state-guard.md\` |
| repositories, data sources, anything that can fail | \`06-flutter-error-guard.md\` |
| any source or config file | \`03-flutter-security-guard.md\` |
| \`_test.dart\` files | \`04-flutter-test-guard.md\` |
| Firestore Rules, RLS, BaaS data sources | \`08-flutter-baas-security-guard.md\` (if installed) |
| \`.arb\` files, user-facing strings | \`11-flutter-l10n-guard.md\` (if installed) |

Prefer the subagents in \`.claude/agents/\` for multi-file reads -
\`pattern-scout\` before any \`flutter-*-gen\` skill, \`flutter-auditor\` /
\`mobile-security-auditor\` for reviews, \`repo-cartographer\` for scans.`);

if (problems.length) {
  out.push(`\n## Attention required\n\n${problems.map(p => "- " + p).join("\n")}`);
} else if (anyContent) {
  out.push(`\n_Memory-bank Tier 1 is present and current._`);
}

inject("SessionStart", out.join("\n"));
