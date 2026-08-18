#!/usr/bin/env node
/**
 * Stop hook — post-hoc verification.
 *
 * Every other hook in this kit fires *before* a write. Nothing checked the
 * result. This closes that gap: when a session touched Dart, it runs the same
 * three commands CI runs, and reports back inside the same session so the
 * agent can fix what it just broke instead of discovering it after a push.
 *
 * Deliberately non-blocking. A Stop hook that fails the turn on a formatting
 * nit is a hook people delete. It reports; the agent decides.
 *
 * Skips itself entirely when:
 *   - no tracked .dart file changed (git is the source of truth)
 *   - this is not a git repo, or flutter is not on PATH
 *   - .claude/cache/skip-verify exists (escape hatch for long sessions)
 */

import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { readPayload, projectDir, ok } from "./_lib.mjs";

const root = projectDir();

const sh = (cmd, timeout = 180_000) => {
  try {
    return {
      code: 0,
      out: execSync(cmd, {
        cwd: root,
        timeout,
        stdio: ["ignore", "pipe", "pipe"],
        encoding: "utf8",
        maxBuffer: 12 * 1024 * 1024,
      }),
    };
  } catch (e) {
    return {
      code: e.status ?? 1,
      out: `${e.stdout ?? ""}${e.stderr ?? ""}`,
      timedOut: e.signal === "SIGTERM" || e.code === "ETIMEDOUT",
    };
  }
};

const has = (bin) =>
  sh(process.platform === "win32" ? `where ${bin}` : `command -v ${bin}`, 10_000)
    .code === 0;

await readPayload();

// --- preconditions -------------------------------------------------------

if (existsSync(join(root, ".claude", "cache", "skip-verify"))) ok();
if (!existsSync(join(root, "pubspec.yaml"))) ok();
if (sh("git rev-parse --is-inside-work-tree", 10_000).code !== 0) ok();

const changed = sh("git status --porcelain", 15_000)
  .out.split("\n")
  .map((l) => l.slice(3).trim())
  .filter(Boolean);

const dart = changed.filter((f) => f.endsWith(".dart"));
if (dart.length === 0) ok();

if (!has("flutter")) {
  console.log(
    "Session touched Dart, but `flutter` is not on PATH — skipping verification.",
  );
  ok();
}

// --- checks --------------------------------------------------------------

const findings = [];
const passed = [];

const fmt = sh("dart format --output=none --set-exit-if-changed .", 90_000);
if (fmt.code !== 0) {
  findings.push(
    `**Formatting** — \`dart format\` would change files. Run \`dart format .\`\n${fmt.out.trim().split("\n").slice(0, 12).join("\n")}`,
  );
} else passed.push("format");

const analyze = sh("flutter analyze --no-fatal-infos", 240_000);
if (analyze.timedOut) {
  findings.push("**Analyze** — timed out after 4 minutes. Run it manually.");
} else if (analyze.code !== 0) {
  const lines = analyze.out
    .split("\n")
    .filter((l) => /error •|warning •/.test(l))
    .slice(0, 25);
  findings.push(
    `**Analyze** — \`flutter analyze\` failed.\n${(lines.length ? lines : analyze.out.split("\n").slice(0, 15)).join("\n")}`,
  );
} else passed.push("analyze");

// Tests are slow. Only run them when the session actually touched tests.
const touchedTests = changed.some(
  (f) => f.startsWith("test/") || f.endsWith("_test.dart"),
);
if (touchedTests) {
  const test = sh("flutter test --reporter compact", 420_000);
  if (test.timedOut) {
    findings.push("**Tests** — timed out after 7 minutes. Run them manually.");
  } else if (test.code !== 0) {
    const lines = test.out
      .split("\n")
      .filter((l) => /\[E\]|Expected:|Actual:|failed|Some tests/.test(l))
      .slice(0, 25);
    findings.push(
      `**Tests** — \`flutter test\` failed.\n${(lines.length ? lines : test.out.split("\n").slice(-20)).join("\n")}`,
    );
  } else passed.push("tests");
}

// Leftover debug instrumentation — see 09-minimal-changes.
const debugTemp = sh(
  process.platform === "win32"
    ? 'findstr /s /n /c:"DEBUG-TEMP" lib\\*.dart test\\*.dart'
    : "grep -rn 'DEBUG-TEMP' lib/ test/ --include='*.dart'",
  20_000,
);
if (debugTemp.code === 0 && debugTemp.out.trim()) {
  findings.push(
    `**Debug instrumentation left in place** — \`09-minimal-changes\` allows \`// DEBUG-TEMP:\` during \`/flutter-debug\`, but none may be committed. Remove:\n${debugTemp.out.trim().split("\n").slice(0, 15).join("\n")}`,
  );
}

// --- report --------------------------------------------------------------

if (findings.length === 0) {
  console.log(
    `Post-session verification passed (${passed.join(", ")}) across ${dart.length} changed Dart file(s).`,
  );
  ok();
}

console.log(
  [
    `## Post-session verification — ${findings.length} issue(s)`,
    "",
    `${dart.length} Dart file(s) changed this session.` +
      (passed.length ? ` Passed: ${passed.join(", ")}.` : ""),
    "",
    ...findings.map((f) => `- ${f}\n`),
    "These are from the working tree as it stands now. Fix them before",
    "committing — CI runs the same checks and will fail on the same things.",
  ].join("\n"),
);
ok();
