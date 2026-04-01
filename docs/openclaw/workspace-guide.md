# OpenClaw Workspace & Configuration Guide

> Your files are your agent. Know what each one does.
> March 2026 — Version 1.0

---

## 1. The Big Picture

OpenClaw is a locally-hosted AI agent framework. A single Node.js Gateway process runs on your machine (or VPS), connecting messaging platforms like WhatsApp, Telegram, Slack, and Discord to large language models.

All agent state — memory, personality, instructions — lives as **plain Markdown files in a workspace directory**. There is no database UI, no web dashboard for configuration. Your files are your agent.

This matters because every workspace file has a specific role in the agent's system prompt. Some files get injected into every single LLM call (costing tokens every turn), while others are loaded on-demand only when the agent decides it needs them. Understanding this distinction is the single most important thing for keeping your agent fast, affordable, and well-behaved.

**Core Principle:** OpenClaw is only as smart as the prompt it constructs. You control every file that goes into that prompt. Edit SOUL.md and you change WHO the agent is. Edit memory files and you change WHAT it remembers. There's no magic — it's all text files.

---

## 2. Where Things Live

### 2.1 The Two Directories

OpenClaw uses two separate directories. Do not confuse them:

- `~/.openclaw/` — Config, credentials, sessions, memory index (SQLite). This is system-level. Never commit this to git.
- `~/.openclaw/workspace/` — Your agent workspace. All the Markdown files that shape the agent's behavior. This is what you version-control.

If the `OPENCLAW_PROFILE` environment variable is set, the workspace path becomes `~/.openclaw/workspace-<profile>`. Useful for separating personal vs. work agents.

### 2.2 Key System Paths

| File | Loaded | Purpose |
|------|--------|---------|
| `~/.openclaw/openclaw.json` | On boot | Main config: models, channels, auth, sandbox settings |
| `~/.openclaw/credentials/` | On boot | OAuth tokens, API keys (plaintext — protect this directory) |
| `~/.openclaw/memory/<id>.sqlite` | On search | Vector + BM25 index for memory retrieval |
| `~/.openclaw/agents/<id>/sessions/` | Per session | Session history and transcripts |

---

## 3. Workspace Files: The Complete Map

Every file below lives in your workspace directory. The "Loaded" column tells you when each file hits the LLM's context window.

### 3.1 Bootstrap Files (Injected Every Turn)

These files cost you tokens on every single message. They're rebuilt into the system prompt before each LLM call. **Keep them lean.**

| File | Loaded | Purpose |
|------|--------|---------|
| `AGENTS.md` | Every turn | Operating instructions: how the agent uses memory, tools, and responds |
| `SOUL.md` | Every turn | Personality, tone, behavioral rules, boundaries |
| `TOOLS.md` | Every turn | Notes about local tools and conventions (guidance only, not access control) |
| `IDENTITY.md` | Every turn | Agent name, vibe/theme, emoji — created during initial bootstrap |
| `USER.md` | Every turn | Who you are: name, timezone, preferences, communication style |
| `HEARTBEAT.md` | Heartbeat runs | Tiny checklist for periodic background runs |
| `BOOTSTRAP.md` | First run only | One-time setup ritual, only runs on brand-new workspace |

**Token Budget Reality:**
- All bootstrap files share a combined cap of `bootstrapTotalMaxChars`: **150,000** (~50K tokens).
- Each individual file is capped at `bootstrapMaxChars`: **20,000 chars**.
- Files that exceed the per-file cap are truncated using a 70/20/10 rule: 70% from the top, 20% from the bottom, 10% for a truncation marker. **The middle of oversized files is silently dropped.**

### 3.2 Memory Files (On-Demand)

These files are **not** injected into every turn. They're loaded when the agent decides to read them (via tool calls) or when the memory search pipeline retrieves relevant chunks.

| File | Loaded | Purpose |
|------|--------|---------|
| `MEMORY.md` | Private sessions only | Curated long-term facts: decisions, preferences, durable knowledge |
| `memory/YYYY-MM-DD.md` | Via tool call | Daily notes — append-only logs of conversations and events |
| `memory/*.md` | Via search | Any custom memory files (projects.md, clients.md, etc.) |

**Important:** MEMORY.md is loaded only in private/DM sessions, never in group chats. This protects sensitive information. Daily notes are NOT auto-generated — the LLM creates them when it decides something is worth logging.

### 3.3 Skills Directory

Skills live at `workspace/skills/` and extend the agent's capabilities. Only skill **metadata** (name + description + path, roughly 97 chars per skill) is injected into the system prompt. The full SKILL.md content loads only when the agent decides to use it.

**Warning:** Even metadata adds up fast. Running 15+ skills means the metadata alone can push context toward compaction thresholds within minutes. Only install skills the agent actually needs for its role.

---

## 4. What to Put in Each File

### 4.1 SOUL.md — The Most Important File

This is the highest-leverage configuration surface in your entire OpenClaw setup. It defines WHO the agent is.

**Target 50-150 lines.** If you're over 150 lines, you're almost certainly putting operational detail that belongs in memory files.

**What belongs here:**
- Core personality traits and communication style
- Hard behavioral rules (e.g., "always confirm before deleting files")
- Boundaries and things the agent should never do
- Response format preferences (brevity, bullet points, etc.)

**What does NOT belong here:**
- Project details, client information, or domain knowledge (use memory files)
- Long lists of instructions (the agent will ignore items in the middle of long lists)
- Information that changes frequently

**Calibration Trick:** Run your 5 most common tasks with a cheap/small model (like Haiku). Wherever the small model drifts from desired behavior, your SOUL.md is too vague at that point. Write short, specific prevention rules — not incident reports.

### 4.2 AGENTS.md — Operating Manual

This tells the agent how to operate: how to use memory, tools, when to save notes, how to handle multi-step tasks. Think of SOUL.md as "who you are" and AGENTS.md as "how you work."

**Good content:**
- Memory workflow: when to write to MEMORY.md vs. daily notes
- Tool usage patterns: when to search memory before responding
- Session management: how to handle context getting large
- Error handling: what to do when a tool call fails

Keep it focused. This is also injected every turn.

### 4.3 USER.md — Static User Profile

Name, timezone, language preference, any accessibility needs, communication style preferences. This survives compaction because it's re-read from disk every turn.

Keep it under 40 lines. Do not put evolving context here. USER.md is for facts that rarely change. Your current projects, ongoing tasks, or temporary preferences belong in MEMORY.md or daily notes.

### 4.4 TOOLS.md — Tool Guidance

Notes about your local environment and tool conventions. This does **not** control which tools are available (that's in `openclaw.json`). It's guidance for how to use them.

**Examples:**
- "Always use the staging database connection, never production"
- "When running shell commands, prefer fish shell syntax"
- "Browser tool: always close tabs after scraping"

**Watch the size.** Tool schemas (JSON) also count toward context and aren't visible as text. The browser tool alone costs ~2,453 tokens. TOOLS.md can easily exceed the 20K char cap if you're not careful.

### 4.5 IDENTITY.md — Agent Identity

Short file. Agent's name, its self-concept, signature emoji, and one-line personality vibe. Typically auto-generated during `openclaw onboard` and rarely edited afterward.

### 4.6 HEARTBEAT.md — Background Checklist

The heartbeat is a periodic background run. The contract: the agent scans this checklist, does any lightweight work, and replies `HEARTBEAT_OK` if nothing needs attention. Keep it extremely short.

**Critical cost warning:** Native heartbeat loads full chat history on every run. In production, disable native heartbeat (`heartbeat.every: "0m"`) and use an isolated cron heartbeat instead. This avoids loading the full conversation history and saves significant tokens.

### 4.7 MEMORY.md — Long-Term Memory

Curated, durable facts. The LLM decides what goes here (it's not programmatic). Think: decisions made, user preferences learned over time, project context that matters across sessions.

Only loaded in private sessions.

**The key insight:** MEMORY.md is the curated version. Daily notes (`memory/YYYY-MM-DD.md`) are the raw, append-only logs. The agent should periodically promote important patterns from daily notes into MEMORY.md and prune stale entries.

### 4.8 Daily Notes — `memory/YYYY-MM-DD.md`

These accumulate automatically as the agent works. At session start, the agent reads today's and yesterday's notes via tool calls (they're not auto-injected).

Over time, hundreds of dated files become searchable through the memory search pipeline.

You don't typically edit these manually. But understanding they exist matters: this is where the agent's working memory lives between sessions. **If compaction runs without flushing memory to these files first, anything not saved here is lost permanently.**

---

## 5. The Lean Files Rule

| File | Injected | Target Size | Consequence if Big |
|------|----------|-------------|--------------------|
| SOUL.md | Every turn | 50-150 lines | Token burn + vague behavior |
| AGENTS.md | Every turn | Under 100 lines | Token burn + ignored rules |
| USER.md | Every turn | Under 40 lines | Token burn |
| TOOLS.md | Every turn | Under 5KB | Middle silently truncated |
| IDENTITY.md | Every turn | 10-20 lines | Wasted tokens |
| HEARTBEAT.md | Heartbeat only | 5-10 lines | Expensive heartbeat runs |
| MEMORY.md | Private sessions | No hard limit* | Longer load, more tokens |
| memory/*.md | On-demand | No hard limit* | Searched, not bulk-loaded |

\* Still subject to the per-file 20,000 char cap when loaded. Keep MEMORY.md well-curated. Daily notes can grow freely since they're only retrieved via search.

**The 7KB Rule:** Aim for all bootstrap files (SOUL.md + AGENTS.md + USER.md + TOOLS.md + IDENTITY.md) to total under ~7KB combined. One production user cut response times from 10 minutes to normal by reducing injected workspace files from 47,000 to 16,000 characters. Move detailed content into memory files that load on-demand via semantic search.

---

## 6. How Memory Actually Works

OpenClaw's memory search is a hybrid retrieval pipeline: 70% vector similarity (cosine via sqlite-vec) and 30% keyword matching (BM25 via SQLite FTS5). When the agent searches memory, both engines run in parallel, results are merged by weighted score, and the top matches are returned.

**What you need to know:**
- The LLM decides what to save — there's no rule-based logic routing info between daily notes and MEMORY.md. The system prompt tells the model the convention, and it uses judgment.
- Daily notes vs. MEMORY.md is a durability question. Daily notes are raw logs. MEMORY.md is curated. Think of daily notes as a journal and MEMORY.md as a reference card.
- Embedding provider auto-selects: Local -> OpenAI -> Gemini -> Voyage -> Mistral -> disabled. Changing providers triggers a full reindex.
- Memory search never hard-fails: triple fallback from sqlite-vec -> JS cosine -> BM25-only.

---

## 7. Compaction: The Thing That Will Bite You

When conversation history grows too large for the model's context window, OpenClaw "compacts" it: summarizing old messages and keeping recent ones. There are two paths:

**Good Path: Maintenance Compaction**
- Triggers when context is getting full but before the API rejects anything.
- Before summarizing, the agent gets a silent turn to flush important information to disk (memory files).
- Recent messages (~20K tokens) are kept intact. This is graceful.

**Bad Path: Overflow Recovery**
- Triggers when the API rejects the request because context is already too large.
- Emergency compression fires with **no memory flush, no saving, maximum context loss**.
- Everything the agent didn't already write to disk is gone forever.

**Critical Production Setting:** The `softThresholdTokens` setting (default: 4,000) does NOT scale with your model's context window. On a 1M context model, the flush triggers at ~996K tokens but the API may reject much earlier. For large-context models, manually set `reserveTokensFloor: 120000` and `softThresholdTokens: 50000` in your `openclaw.json`.

---

## 8. Getting Started Checklist

1. **Install and onboard:** Run `openclaw onboard` or `openclaw setup`. This creates the workspace and seeds bootstrap files.
2. **Configure your LLM provider:** Add API keys to `~/.openclaw/openclaw.json`. Start with one provider.
3. **Write your SOUL.md:** 50-150 lines. Specific rules, not vague aspirations. Test with a cheap model.
4. **Fill USER.md:** Name, timezone, key preferences. Under 40 lines.
5. **Connect one channel:** Telegram is the fastest. Test with DMs before adding groups.
6. **Run `openclaw doctor`:** Do this after every config change. It catches broken paths, missing dependencies, and config errors.
7. **Git-track your workspace:** `git init` inside your workspace directory. Commit AGENTS.md, SOUL.md, USER.md, TOOLS.md, IDENTITY.md, and memory files. Never commit `~/.openclaw/` config or credentials.
8. **Security audit:** Run `openclaw security audit --deep` before any network exposure. Bind gateway to `127.0.0.1`. Use `allowFrom` on channels. Sandbox non-main sessions.

---

## 9. Common Mistakes to Avoid

- **Stuffing everything into SOUL.md.** Domain knowledge, project details, and client info belong in memory files, not in a file injected every turn.
- **Installing every cool skill.** Each skill adds ~97 chars of metadata to every turn. 15+ skills and you're burning context on metadata alone.
- **Ignoring compaction settings.** Default `softThresholdTokens` (4,000) is fine for 200K models but dangerous for 1M+ context windows.
- **Leaving heartbeat on default.** Native heartbeat loads full history. Switch to isolated cron heartbeat in production.
- **Not running `openclaw doctor`.** Run it after every config change. It's your safety net.
- **Trusting chat instructions to survive.** Anything said in conversation that isn't written to a file WILL be lost on compaction. Important instructions must be in workspace files.
- **Skipping security hardening.** Default gateway binds to all interfaces. 135K+ instances are publicly exposed. Always bind to `127.0.0.1` and use SSH/Tailscale for remote access.

---

## 10. Quick Reference

| Command | Purpose |
|---------|---------|
| `openclaw onboard` | First-time setup |
| `openclaw doctor --fix` | Diagnose and auto-fix issues |
| `openclaw security audit --deep` | Full security scan |
| `openclaw gateway start/stop/status` | Control the gateway |
| `openclaw setup` | Recreate missing defaults without overwriting existing files |
