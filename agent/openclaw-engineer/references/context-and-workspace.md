# Context Assembly & Workspace Design — Deep Reference

## System Prompt Structure (Rebuilt Every Turn)

OpenClaw reconstructs the system prompt before every LLM call from four parts:

1. **Base agent instructions** — OpenClaw's built-in tooling, safety, skills list, time, runtime
2. **Skills metadata** — compact XML list of name + description + path (NOT full SKILL.md)
3. **Bootstrap context files** — injected under "Project Context" in fixed order
4. **Per-run overrides** — heartbeat instructions, session-specific context

### Bootstrap Injection Order (Fixed)

```
AGENTS.md → SOUL.md → TOOLS.md → IDENTITY.md → USER.md → HEARTBEAT.md → BOOTSTRAP.md (first-run only) → MEMORY.md (private sessions only)
```

**Subagent sessions:** Only `AGENTS.md + TOOLS.md` — no personality, user context, or memory.
**Heartbeat with `lightContext: true`:** Only `HEARTBEAT.md`.

### Truncation Rules

**Per-file cap:** `bootstrapMaxChars` = 20,000 characters (default)
**Aggregate cap:** `bootstrapTotalMaxChars` = 150,000 characters (~50K tokens)

**70/20/10 truncation strategy** (for files exceeding per-file cap):
- 70% from the head (kept)
- 20% from the tail (kept)
- 10% for truncation marker
- **The middle is silently dropped**

This is critical: if important content sits in the middle of a large file, it will be silently
lost. Put critical content at the TOP of files, supporting detail at the bottom.

**Truncation warning:** `bootstrapPromptTruncationWarning` (`off`, `once`, `always`; default `once`)
**Inspect context:** `/context list` or `/context detail`

### Token Costs (Typical)

| Component | Tokens |
|---|---|
| System prompt base | ~9,600 |
| Tool schemas (JSON, not visible as text) | ~8,000 |
| Browser tool schema | ~2,453 |
| Exec tool schema | ~1,560 |
| Skills metadata list | ~550 (for ~23 skills, ~24 tokens/skill) |
| Project context (bootstrap files) | ~6,000 (varies) |

**No percentage-based budget.** OpenClaw uses an additive model: system prompt has fixed cost,
remaining space fills with conversation history until compaction triggers. This means every token
you add to bootstrap files directly reduces conversation capacity.

---

## Workspace File Roles and Target Sizes

### The 7KB Rule

All bootstrap files combined should target ~7KB. A production user cut response times from
10 minutes to normal by reducing injected files from 47,000 to 16,000 characters. Move
detailed content to memory files that load on-demand via semantic search.

### File-by-File Guide

#### SOUL.md — Personality & Behavioral Core (Target: 50-150 lines)

The highest-leverage configuration surface in an OpenClaw workspace. Defines WHO the agent is.

**What belongs here:**
- Core personality traits and communication style
- Hard behavioral rules ("always confirm before deleting files")
- Boundaries and prohibited behaviors
- Response format preferences

**What does NOT belong here:**
- Project details, client info, domain knowledge (→ memory files)
- Long instruction lists (agent ignores items in the middle of long lists)
- Frequently changing information
- Rules that subagents must follow (→ AGENTS.md instead)

**Calibration heuristic:** Run your 5 most common tasks on Haiku. Where Haiku drifts from
desired behavior, SOUL.md is too vague at that point. Write short, specific prevention rules —
not incident reports.

#### AGENTS.md — Operating Manual (Target: <100 lines)

How the agent operates: memory workflows, tool usage patterns, session management, error
handling. Think SOUL.md = "who you are", AGENTS.md = "how you work."

**Critical:** This is the ONLY personality/instruction file subagents see. Any rules that must
apply to subagent behavior MUST be here, not in SOUL.md.

#### USER.md — Static User Profile (Target: <40 lines)

Name, timezone, language, accessibility needs, communication style. Re-read from disk every turn
(survives compaction). Only for facts that rarely change. Evolving context belongs in MEMORY.md
or daily notes.

#### TOOLS.md — Tool Guidance (Target: <5KB)

Notes about local environment and tool conventions. Does NOT control which tools are available
(that's in openclaw.json). This is guidance for HOW to use them.

Watch the size: tool schemas (JSON) also count toward context and aren't visible as text. If
TOOLS.md exceeds 20K chars, the middle is silently truncated.

#### IDENTITY.md — Agent Identity (Target: 10-20 lines)

Agent name, self-concept, signature emoji, one-line personality vibe. Typically auto-generated
during `openclaw onboard`. Rarely edited.

#### HEARTBEAT.md — Background Checklist (Target: 5-10 lines)

The heartbeat contract: agent scans checklist, does lightweight work, replies `HEARTBEAT_OK` if
nothing needs attention. Keep extremely short.

If HEARTBEAT.md is effectively empty (only blank lines and headers), heartbeat runs are skipped
entirely to save API costs.

**Critical cost warning:** Native heartbeat loads full chat history on every run.
**Fix:** Disable native heartbeat (`heartbeat.every: "0m"`) and use isolated cron heartbeat.
Cache warmer pattern: set interval to ~55 minutes against 1-hour model cache TTL.

Per-agent heartbeat configs support different intervals, models, and targets. Using Haiku
instead of Opus: ~$0.15/month vs ~$7.20/month.

#### MEMORY.md — Curated Long-Term Memory (No hard line limit)

Durable facts: decisions, preferences, patterns learned across sessions. Only loaded in private
sessions. Subject to 20K char per-file cap when loaded.

The agent should periodically promote important patterns from daily notes into MEMORY.md and
prune stale entries.

#### Daily Notes — memory/YYYY-MM-DD.md (No limit)

Append-only logs. Not auto-generated — the LLM creates them. At session start, the model reads
today's + yesterday's notes via tool calls. Over time, hundreds of dated files accumulate and
become searchable through `memory_search`. These can grow freely since they're only retrieved
via search, not bulk-loaded.

---

## Config Reference: Context and Workspace

```json5
{
  agents: {
    defaults: {
      bootstrapMaxChars: 20000,          // per-file cap
      bootstrapTotalMaxChars: 150000,    // aggregate cap (~50K tokens)
      bootstrapPromptTruncationWarning: "once",  // off, once, always
      heartbeat: {
        every: "30m",        // default (1h for Anthropic OAuth)
        lightContext: true,  // only inject HEARTBEAT.md (recommended)
        activeHours: "08:00-22:00",  // timezone-aware window
      }
    }
  }
}
```

## Design Principles for Workspace Architecture

1. **Bootstrap = durable, small, static.** Memory = evolving, searchable on demand.
2. **One file, one clear purpose.** Don't overload SOUL.md with operational rules.
3. **Subagent-visible rules in AGENTS.md.** Everything else is invisible to subagents.
4. **Progressive disclosure everywhere.** System prompt → bootstrap files → memory files → search results. Each layer loads only when needed.
5. **Measure, don't guess.** Use `/context detail` to check actual token overhead. Use `/context list` to see what's injected.
6. **Version control the workspace.** Git-track AGENTS.md, SOUL.md, USER.md, TOOLS.md, IDENTITY.md, MEMORY.md, and memory/*.md. Never commit `~/.openclaw/` config or session data.
