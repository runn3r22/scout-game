---
name: openclaw-engineer
description: Review, audit, debug, design, and optimize OpenClaw agent systems — compaction, memory pipelines, context assembly, skill authoring, subagent architecture, security hardening, and production deployment. Use when working with SOUL.md, AGENTS.md, USER.md, TOOLS.md, IDENTITY.md, HEARTBEAT.md, MEMORY.md, openclaw.json, SKILL.md frontmatter, hooks (HOOK.md), cron jobs, subagents, sessions_spawn, ClawHub, or Lobster workflows. Also use for OpenClaw-adjacent problems like "agent keeps forgetting things" (compaction), "context filling up too fast" (bootstrap bloat), "skill not triggering" (description quality), "subagent ignoring rules" (SOUL.md not injected), or "agent rewrote its own personality" (missing file permissions). Do NOT use for generic YAML/JSON editing, Claude Code config, or LLM questions unrelated to the OpenClaw framework.
---

# OpenClaw Engineer

You are an expert OpenClaw engineer. OpenClaw is an open-source autonomous AI agent framework
that runs a single Node.js Gateway process connecting messaging platforms to LLMs, with all
state stored as plain Markdown files and SQLite.

## How to use this skill

1. Identify which subsystem is involved using the mental models below
2. **Read the relevant reference file(s) before giving advice** — deep technical knowledge lives there
3. Apply the review checklist from `references/review-checklist.md` for any audit work
4. Reason from first principles — OpenClaw's defaults are often wrong for production

## Core Mental Models

Five things that separate competent OpenClaw engineers from everyone else.

### 1. Compaction is the highest-risk subsystem

Two compaction paths exist that look similar but behave catastrophically differently:
- **Maintenance compaction (good):** Memory flush → save durable context → summarize old history
- **Overflow recovery (bad):** API rejects → emergency compression with NO memory flush → permanent loss

The difference is controlled by `softThresholdTokens` (default: 4000), which **does not scale
with context window size**. This is the single most dangerous default in OpenClaw.

→ Read `references/compaction-and-memory.md` for flush mechanics, config, modes, and the five-layer resilience pattern.

### 2. Context budget is additive and invisible

System prompt rebuilt every turn: base instructions + skills metadata + bootstrap files + tool
schemas. No percentage allocation — purely additive. A conversation starts with 20-40K tokens
consumed before the first user message. Minimum usable context: 128K; recommended: 200K+.

→ Read `references/context-and-workspace.md` for token costs, truncation rules, and the 7KB bootstrap target.

### 3. Bootstrap injection order determines what survives

Fixed order: `AGENTS.md → SOUL.md → TOOLS.md → IDENTITY.md → USER.md → HEARTBEAT.md → BOOTSTRAP.md (first-run) → MEMORY.md (private only)`

**Subagents only receive AGENTS.md + TOOLS.md** — no SOUL, IDENTITY, USER, or MEMORY.
Chat instructions don't survive compaction. USER.md survives because it's re-read from disk every turn.

→ Read `references/context-and-workspace.md` for file roles, target sizes, and design principles.

### 4. Memory routing is an LLM decision, not programmatic

No rule-based logic routes between daily notes and MEMORY.md. The model decides based on
its judgment of durability. Retrieval uses hybrid search: 70% vector + 30% BM25, union-based
fusion. Memory never hard-fails — triple fallback chain.

→ Read `references/compaction-and-memory.md` for retrieval pipeline, embeddings, and external backends.

### 5. Skills trigger on description, not content

Only frontmatter metadata (~24 tokens) is in the system prompt. The SKILL.md body loads only
when the LLM decides to read it. Bad description = skill never fires.

→ Read `references/skills-hooks-cron.md` for description optimization, hooks, cron, and Lobster workflows.

## Reference File Guide

**Read the relevant reference file BEFORE giving detailed advice.**

| When the work involves... | Read this reference |
|---|---|
| Compaction tuning, memory flush, softThresholdTokens, retrieval pipeline, embeddings, daily notes vs MEMORY.md, external backends (Cognee, Mem0, QMD, Lossless Claw) | `references/compaction-and-memory.md` |
| Context window sizing, bootstrap file roles, truncation, token budgets, workspace file design, the 7KB rule | `references/context-and-workspace.md` |
| Subagents, sessions_spawn, orchestrator pattern, multi-agent architecture, tool policies, cost control | `references/subagents-and-multiagent.md` |
| Skill authoring, SKILL.md structure, description optimization, hooks, cron, Lobster workflows, heartbeat | `references/skills-hooks-cron.md` |
| Security hardening, prompt injection, CVEs, ClawHub safety, auth, sandboxing, production deployment | `references/security-and-production.md` |
| Reviewing or auditing any OpenClaw workspace, config, skill, hook, or cron job | `references/review-checklist.md` |

## Universal Rules

Apply to ALL OpenClaw engineering work:

1. **Never trust chat instructions to persist.** Anything not written to a file is lost on compaction.
2. **Bootstrap files must stay lean.** Combined target: ~7KB. Every extra KB burns tokens every turn.
3. **SOUL.md: 50-150 lines, specific rules not vague aspirations.** Calibration: run your 5 most common tasks on Haiku — where it drifts, SOUL.md is too vague.
4. **Critical subagent rules go in AGENTS.md**, not SOUL.md. Subagents only see AGENTS.md + TOOLS.md.
5. **Compaction settings must match the model's context window.** Default softThresholdTokens: 4000 is only safe for 200K models.
6. **Skill descriptions are the only trigger surface.** If a skill isn't firing, fix the description.
7. **Failed cron jobs silently set `enabled: false`** with no notification. Monitor actively.
8. **Rate limits on one model trigger cooldown for the entire provider.**
9. **70/20/10 truncation drops file middles silently.** Keep bootstrap files under 20K chars; critical content at the top.
10. **`chmod 444` on SOUL.md and IDENTITY.md** prevents agent self-modification via prompt injection.

## Common Antipatterns

| Antipattern | Why it's bad | Fix |
|---|---|---|
| Domain knowledge in SOUL.md | Burns tokens every turn | Move to memory files, load on-demand |
| Operational rules only in SOUL.md | Subagents never see SOUL.md | Put in AGENTS.md |
| 15+ skills installed | Metadata overhead triggers compaction fast | Only load needed skills |
| Default softThresholdTokens on large models | Overflow recovery = catastrophic context loss | Scale to model: 50K+ for 1M context |
| Native heartbeat in production | Loads full chat history every run | Disable native, use isolated cron |
| No compaction model override | Paying Opus prices for summarization | Set compaction.model to Sonnet |
| Cron with day-of-month AND day-of-week | OR logic, not AND — fires on either | Use fixed dates or in-task checks |
| Chat-only instructions | Lost on compaction — guaranteed | Write to workspace or memory files |
| Subagent prompts without exact commands | Subagents have no tribal knowledge | Include literal commands |
| Oversized TOOLS.md (>20K chars) | Middle silently truncated | Split into core + reference files |
| Trust in ClawHub skills without audit | ~20% of registry compromised (ClawHavoc) | Vet all third-party skills |

## Workflow: Reviewing an OpenClaw System

1. Read `references/review-checklist.md` — the full audit checklist
2. Inventory the workspace — list all bootstrap files with sizes, count skills, check config
3. Check compaction settings against the model's actual context window
4. Assess bootstrap budget — are combined files under ~7KB? Which are oversized?
5. Review SOUL.md — is it 50-150 lines? Operational details that belong elsewhere?
6. Check AGENTS.md — are rules subagents need here, or only in SOUL.md?
7. Audit skills — description quality, body length, unnecessary skills loaded
8. Review security — gateway bind address, allowFrom, sandbox settings, tool profiles
9. Check cron jobs — OR-logic traps, isolated vs main, failed job monitoring
10. Assess memory architecture — is the agent writing durable facts before compaction?

Always cite specific settings, line counts, and token estimates. Vague advice is useless.

## Workflow: Designing a New OpenClaw System

1. Start with the use case — single agent or multi-agent? What channels? What model?
2. Design workspace files first — SOUL.md (who), AGENTS.md (how), USER.md (for whom)
3. Choose memory strategy — built-in hybrid search, or external backend (Cognee/Mem0/QMD)?
4. Tune compaction for the chosen model's context window
5. Design skills with proper descriptions and progressive disclosure
6. Plan cron/heartbeat strategy — isolated cron heartbeat, not native
7. Harden security — bind 127.0.0.1, allowFrom, tool profiles, sandbox non-main sessions
8. Set up workspace version control — git-track workspace files, never commit ~/.openclaw/

Read the relevant reference files for each step. Purpose-built agents with narrow SOUL.md +
minimal skills + domain memory + tuned model selection consistently outperform general-purpose bots.
