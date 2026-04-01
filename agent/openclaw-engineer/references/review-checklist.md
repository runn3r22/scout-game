# OpenClaw Review Checklist — Comprehensive Audit Guide

Use this checklist when reviewing, auditing, or improving any OpenClaw-based system. Work through
each section systematically. Skip sections that don't apply, but don't skip the assessment —
explicitly note "N/A" or "not applicable" so the review is provably complete.

---

## 1. Bootstrap File Health

For each bootstrap file (SOUL.md, AGENTS.md, TOOLS.md, IDENTITY.md, USER.md, HEARTBEAT.md):

- [ ] **Measure actual size** — count lines and characters. Compare against targets:
  - SOUL.md: 50-150 lines
  - AGENTS.md: <100 lines
  - USER.md: <40 lines
  - TOOLS.md: <5KB
  - IDENTITY.md: 10-20 lines
  - HEARTBEAT.md: 5-10 lines
  - Combined total: target ~7KB

- [ ] **Check for domain knowledge in SOUL.md** — project details, client info, operational
  procedures, lists of tools, anything that changes frequently. All belong in memory files.

- [ ] **Check for oversized files approaching 20K chars** — these trigger 70/20/10 truncation.
  Is critical content in the middle section that would be silently dropped?

- [ ] **Verify critical subagent rules are in AGENTS.md** — SOUL.md is NOT injected for subagents.
  Any rule that must apply universally (including subagent behavior) must be in AGENTS.md.

- [ ] **Check SOUL.md calibration** — are rules specific and actionable, or vague aspirations?
  Test: would a cheap model (Haiku) follow these instructions? If not, too vague.

- [ ] **Verify USER.md contains only static facts** — name, timezone, preferences that rarely
  change. Evolving context belongs in MEMORY.md or daily notes.

---

## 2. Compaction Configuration

- [ ] **Identify the model and its context window size** — this determines everything else.

- [ ] **Check `softThresholdTokens`** against the model's context window:
  - 200K model: default 4000 is OK (flush at ~176K)
  - 500K+ model: must increase (recommended 50000)
  - 1M model: must increase significantly (recommended 50000+, reserveTokensFloor: 120000)
  - If using default 4000 on a large-context model: **CRITICAL FINDING**

- [ ] **Check if compaction model override is set** — `agents.defaults.compaction.model`.
  Running Opus for summarization when Sonnet would suffice wastes 2-5x on compaction costs.

- [ ] **Check compaction mode** — `default` or `safeguard`. If `safeguard`, note bug #2418
  (dropped chunks removed without summarization).

- [ ] **Assess memory flush defense** — is the agent writing durable facts before compaction?
  Look for: autojournal habits, observer crons, reactive file watchers.

---

## 3. Skill Audit

For each installed skill:

- [ ] **Count total skills** — 15+ skills trigger compaction from metadata alone. Is every
  installed skill actually needed for this agent's role?

- [ ] **Check description quality** for each skill:
  - Does it include WHAT + WHEN + trigger phrases?
  - Is it third person?
  - Are there negative triggers to prevent overlap?
  - Is "when to use" in the body instead of the description? (Body is invisible at routing time)

- [ ] **Check SKILL.md body length** — over 500 lines? Move content to `references/`.

- [ ] **Check for extraneous files** — README.md, CHANGELOG.md, INSTALLATION_GUIDE.md inside
  skill folders are useless (SKILL.md is the only doc surface).

- [ ] **Verify frontmatter** — only `name` and `description` required. No XML angle brackets.
  Name: lowercase + hyphens only.

- [ ] **Check skill provenance** — is it from ClawHub? Has it been vetted? ~20% of ClawHub
  was compromised. 36% of skills contain some form of prompt injection (Snyk).

- [ ] **Check for hardcoded paths** — use `{baseDir}` to reference skill folder, not absolute paths.

---

## 4. Security Assessment

- [ ] **Gateway bind address** — must be `127.0.0.1`. If `0.0.0.0`, CRITICAL FINDING.

- [ ] **`allowFrom` on all channels** — are there access controls? Open DMs = public access.

- [ ] **`dmScope` setting** — `"main"` collapses all DMs into one session (cross-user leakage).
  Recommended: `"per-channel-peer"`.

- [ ] **Sandbox mode for non-main sessions** — are subagents sandboxed?

- [ ] **Tool profiles** — is `tools.profile: "minimal"` used for untrusted contexts?

- [ ] **SOUL.md/IDENTITY.md permissions** — `chmod 444` prevents agent self-modification.

- [ ] **Provider spend caps** — are there budget limits to prevent runaway costs?

- [ ] **OpenClaw version** — is it post-v2026.1.29 (CVE-2026-25253 patch)?

- [ ] **`openclaw security audit --deep`** — has this been run?

- [ ] **Model choice for tool-enabled agents** — smaller models are less robust against
  prompt injection. Latest-gen instruction-hardened models recommended.

---

## 5. Cron Job Review

For each cron job:

- [ ] **Check for OR-logic trap** — does the cron expression have BOTH day-of-month AND
  day-of-week? If yes, it fires on either (OR), not both (AND). Common source of bugs.

- [ ] **Verify `sessionTarget`** — `"isolated"` starts fresh (no prior context). `"main"`
  injects into main session. Wrong choice = broken cron or polluted main context.

- [ ] **Check for failed jobs** — failed cron jobs silently set `enabled: false`.
  Review `~/.openclaw/cron/jobs.json` for disabled jobs that should be running.

- [ ] **Verify delivery mode** — `announce`, `webhook`, or `none`. Is the right one chosen?

- [ ] **Check retry behavior** — backoff is 30s → 1m → 5m → 15m → 60m. Jobs that consistently
  fail will eventually disable themselves silently.

---

## 6. Hook Review

For each hook:

- [ ] **Handler error safety** — does the handler swallow its own errors? Unhandled throw in
  a hook can break the main agent flow.

- [ ] **Sync hook caution** — `tool_result_persist` hooks are SYNC and can transform data.
  They MUST return cleanly. Verify return value correctness.

- [ ] **Event appropriateness** — `message:received` fires on EVERY message. Is this necessary
  or is it adding ~100 tokens of overhead per message?

- [ ] **Bootstrap file injection** — if using `agent:bootstrap` to inject virtual files, are
  they lean? They add to bootstrap token cost.

---

## 7. Subagent Architecture

- [ ] **Task prompt quality** — do prompts include exact tool commands? Subagents have no
  tribal knowledge. "Use bird" means nothing; `bird search "query" -n 10` does.

- [ ] **Write restrictions** — are there explicit boundaries on what subagents can write?
  Without restrictions, subagents share the full workspace and can modify anything.

- [ ] **Model selection** — are subagents inheriting expensive models unnecessarily? Mechanical
  tasks (reviews, data extraction, summarization) work fine on cheaper models.

- [ ] **Timeout configuration** — do all subagents have `runTimeoutSeconds`? Without it,
  runaway subagents can burn tokens indefinitely.

- [ ] **Tool surface** — are unnecessary tools available to subagents? Each unused tool schema
  wastes context tokens. Deny tools subagents don't need.

- [ ] **Context expectations** — does the task prompt reference files the subagent needs to
  `read`? Remember: subagents don't see SOUL.md, USER.md, or MEMORY.md.

---

## 8. Memory Architecture

- [ ] **Memory file organization** — is detailed/evolving content in bootstrap files when it
  should be in memory files? Bootstrap = durable, small, static. Memory = evolving, searchable.

- [ ] **MEMORY.md curation** — is MEMORY.md actively maintained? Stale entries waste tokens
  when loaded. Agent should periodically promote patterns from daily notes and prune stale entries.

- [ ] **Embedding provider** — which provider is active? Is an API key configured, or is it
  falling back to a less effective method?

- [ ] **Extra search paths** — are domain-specific directories (e.g., `trading/`, `.learnings/`)
  configured in `memorySearch.extraPaths`?

---

## 9. Token Budget Assessment

- [ ] **Estimate total boot context** — system prompt (~9,600) + tool schemas (~8,000) +
  skills metadata (~24/skill × count) + bootstrap files (measure actual chars ÷ 3 for tokens).

- [ ] **Compare against model context window** — how much room is left for conversation?
  - 128K model with 40K boot: 88K for conversation
  - 200K model with 40K boot: 160K for conversation (comfortable)
  - 32K model: probably unusable (too little room after boot)

- [ ] **Check heartbeat token cost** — native heartbeat loads full history. Is `lightContext: true`
  set? Or better: is native heartbeat disabled in favor of isolated cron?

- [ ] **Identify token sinks** — browser tool (~2,453 tokens), unnecessary skills, oversized
  bootstrap files, verbose TOOLS.md.

---

## 10. Lane Queue & Session Config

- [ ] **Queue mode** — is `collect` (default, coalesce messages) appropriate? `steer` injects
  mid-run (useful for interactive). `interrupt` (legacy) aborts runs.

- [ ] **`debounceMs`** — default 1000ms. Too low = race conditions. Too high = slow response.

- [ ] **`maxConcurrent`** — default 4 global sessions. Is this appropriate for the deployment?

- [ ] **Session key structure** — is `dmScope` set correctly for multi-user scenarios?

---

## Severity Classification

When reporting findings, classify severity:

| Severity | Description | Examples |
|---|---|---|
| **CRITICAL** | Immediate risk of data loss, security breach, or system failure | Default softThresholdTokens on 1M model, gateway on 0.0.0.0, hardcoded API keys |
| **HIGH** | Significant operational or cost impact | No compaction model override (Opus for summarization), unvetted ClawHub skills, failed cron jobs running silently disabled |
| **MEDIUM** | Suboptimal but functional | SOUL.md over 150 lines, missing tool deny on subagents, no timeout on subagents |
| **LOW** | Improvement opportunities | Skills metadata overhead, suboptimal memory organization, missing extra search paths |

---

## Report Format

Structure findings as:

```
## [SEVERITY] Finding Title

**What:** Description of the issue
**Why it matters:** Impact on the system (token cost, data loss risk, security, etc.)
**Where:** Specific file, config key, or component
**Fix:** Concrete remediation with exact config or file changes
**Effort:** Estimated time/complexity (trivial / minor / moderate / significant)
```

Always cite specific numbers: line counts, character counts, token estimates, config values.
Vague findings like "SOUL.md is too big" are useless. "SOUL.md is 287 lines (target: 50-150).
Lines 95-180 contain trading pipeline details that belong in memory/trading-pipeline.md" is actionable.
