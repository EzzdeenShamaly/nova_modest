#!/usr/bin/env node
// PreToolUse: Write | Edit | MultiEdit | NotebookEdit
// Turns the always-on prose rules into hard blocks.

import { join } from "node:path";
import { readPayload, relPath, targetPath, writtenContent, block, ok, projectDir, readIfExists } from "./_lib.mjs";

const p = await readPayload();
const file = relPath(targetPath(p));
const body = writtenContent(p);
if (!file) ok();

const lower = file.toLowerCase();

// 1. The structural cache is machine-owned (CLAUDE.md: "never hand-edit").
if (lower.endsWith(".claude/cache/repo-map.json")) {
  block(`BLOCKED: .claude/cache/repo-map.json is generated and owned by /repo-discovery.
Hand-editing it makes every downstream skill trust wrong data.
Run \`/repo-discovery\` (or delegate to the repo-cartographer subagent) instead.`);
}

// 2. Never write secret-bearing files.
if (/(^|\/)\.env(\.|$)/.test(lower) || /(^|\/)secrets?\.(json|ya?ml)$/.test(lower)) {
  block(`BLOCKED: ${file} holds secrets and must not be written by an agent.
Tell the user which key is needed and let them add it themselves.
(.claude/rules/03-flutter-security-guard.md)`);
}

// 3. Tier 2 memory-bank files are human-authored standards — with one
//    exception: the FIRST fill, while the file is still the shipped template.
//    /platform-init and /flutter-project-init have to write these once, and a
//    guard that blocks its own bootstrap just teaches people to disable it.
const TIER2 = /^memory-bank\/(architecture|domainRules|securityStandards)\.md$/i;
if (TIER2.test(file) && !process.env.CLAUDE_ALLOW_TIER2_EDIT) {
  const current = readIfExists(join(projectDir(), file)) ?? "";
  // Unfilled template markers: "> EXAMPLE —" blocks or [bracket slots].
  const slots = (current.match(/\[[^\]]{3,}\]/g) ?? []).length;
  const stillTemplate = current.trim() === "" || /^\s*>\s*EXAMPLE/im.test(current) || slots >= 3;

  if (!stillTemplate) {
    block(`BLOCKED: ${file} is a Tier 2 (human-authored) memory-bank standard
and has already been filled in. Agents read these; they do not rewrite them.
Propose the change to the user in chat instead. If the user explicitly asked
for this edit, they can re-run with CLAUDE_ALLOW_TIER2_EDIT=1 set.`);
  }
  // else: first fill — allowed through.
}

// 4. Hardcoded credentials in the content being written.
if (body) {
  const secretPatterns = [
    [/(?:api[_-]?key|apikey|secret|client[_-]?secret|access[_-]?token)\s*[:=]\s*["'][A-Za-z0-9_\-\/+]{16,}["']/i, "hardcoded API key/secret"],
    [/-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/, "private key material"],
    [/\bBearer\s+eyJ[A-Za-z0-9_\-]{20,}/, "hardcoded JWT"],
  ];
  for (const [re, what] of secretPatterns) {
    const m = body.match(re);
    if (m && !/\$\{|\{\{|<YOUR|placeholder|example|REDACTED|env:|dart-define/i.test(m[0])) {
      block(`BLOCKED: ${what} detected in the content being written to ${file}.
Match: ${m[0].slice(0, 60)}...
Use --dart-define / flutter_secure_storage / environment configuration.
Never inline credentials. (.claude/rules/03-flutter-security-guard.md)`);
    }
  }
}

ok();
