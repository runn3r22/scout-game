# OpenClaw Filesystem & Hidden State — Deep Reference

Where things actually live, what files control what, and the non-obvious state that
the docs don't emphasize. This is the "where to look" guide when debugging.

---

## The Two Trees

OpenClaw state is split across two roots. Confusing them is the #1 debugging mistake.

### 1. `~/.openclaw/` — Framework State (The Engine)

Owned by the Gateway process. Never git-tracked. Contains config, sessions, cron,
credentials, logs, memory indexes, and plugin state. **This is where most debugging happens.**

### 2. `<workspace>/` — Agent State (The Mind)

Default: `~/.openclaw/workspace/`. Git-tracked. Contains bootstrap files (SOUL.md, etc.),
memory notes, skills, scripts, and domain files. **This is what the agent sees and edits.**

These can diverge: config says one thing, workspace says another. Always check both.

---

## `~/.openclaw/` Complete Map

### Top-Level Config Files

| File | What it controls | When to check |
|---|---|---|
| `openclaw.json` | **Master config** — models, compaction, channels, plugins, tools, gateway, auth profiles, heartbeat, everything | Any behavior change, debugging, tuning |
| `openclaw.json.bak` / `.bak.1-.4` | Rolling config backups (auto-created on writes) | Recovering from bad config edit, diffing changes |
| `.env` | Environment variables (API keys, tokens, RPC URLs) | API auth failures, embedding provider issues, tool auth |
| `exec-approvals.json` | Exec binary allowlist — which binaries the agent can shell out to | "Permission denied" on exec, adding new tools |
| `exec-approvals.json.backup` | Backup of exec approvals | Recovery |
| `exec-approvals.sock` | Unix socket for the interactive approval flow | Approval prompts not appearing |
| `update-check.json` | Last update check timestamp + last notified version | Version staleness, update nag issues |
| `.telegram_token` | Bot token (can also be in openclaw.json) | Telegram auth issues |

**Config format:** JSON5 (comments + trailing commas allowed). All fields optional — OpenClaw fills defaults.

**Config hot-reload:** `hybrid` mode (default) hot-applies safe changes, auto-restarts for infrastructure changes. Modes: `hybrid`, `hot`, `restart`, `off`.

**Config backup gotcha:** `config.patch` resolves `${VAR}` env references and writes **plaintext secrets** back to disk (known issue #15932).

### Agent State (`agents/<agentId>/`)

Each agent (default: `main`) has its own state tree:

```
agents/
  main/
    agent/
      auth-profiles.json    # Resolved auth credentials + usage stats
    sessions/
      sessions.json         # Session store — routing, metadata, token counters
      <sessionId>.jsonl     # Transcript files (append-only, tree-structured)
      <sessionId>.jsonl.reset.<timestamp>   # Archived transcripts from /reset
      <sessionId>.jsonl.deleted.<timestamp> # Soft-deleted transcripts
      <sessionId>-topic-<threadId>.jsonl    # Telegram topic sessions
```

#### `sessions.json` — The Session Router

Key/value map: `sessionKey → SessionEntry`. Small, mutable, safe to edit or delete entries.

**Session key format:**
- Main DM: `agent:main:main`
- Cron: `agent:main:cron:<jobId>`
- Subagent: `agent:main:subagent:<uuid>`
- Group: `agent:main:telegram:<groupId>`
- Topic: `agent:main:telegram:<groupId>:topic:<threadId>`

**Key fields per entry:** `sessionId`, `model`, `contextTokens`, `inputTokens`, `outputTokens`,
`estimatedCostUsd`, `compactionCount`, `skillsSnapshot`, `cacheRead`, `cacheWrite`, `status`,
`deliveryContext`, `lastChannel`.

**Debug use:** Check `contextTokens` to see how full a session is. Check `compactionCount` to see
how many times compaction has run. Check `estimatedCostUsd` for cost tracking.

#### Transcript `.jsonl` Structure

Each line is a JSON object with `type`, `id`, `parentId`, `timestamp`. Types include:
- `session` — session metadata (version, cwd)
- `model_change` — model switches
- `thinking_level_change` — thinking level changes
- `user_message`, `assistant_message` — conversation turns
- `tool_use`, `tool_result` — tool calls and responses
- `compaction` — compaction summary entries

**Tree structure:** entries have `id` + `parentId` forming a tree (not a flat list).
The model context is rebuilt by walking this tree.

**Transcript accumulation:** Old sessions are never auto-purged by default. They accumulate
indefinitely. Configure cleanup via `session.maintenance`:

```json5
{
  session: {
    maintenance: {
      mode: "enforce",        // "warn" (default) or "enforce"
      pruneAfter: "30d",      // stale-entry age cutoff
      maxEntries: 500,        // cap entries in sessions.json
      rotateBytes: "10mb",    // rotate sessions.json when oversized
      resetArchiveRetention: "30d",  // retention for *.reset.* archives
      maxDiskBytes: "500mb",  // optional disk budget for sessions dir
      highWaterBytes: "80%",  // target after cleanup
    }
  }
}
```

Manual cleanup: `openclaw sessions cleanup --dry-run` / `--enforce`

### Cron State (`cron/`)

```
cron/
  jobs.json       # All cron job definitions + execution state
  jobs.json.bak   # Backup
  runs/           # Cron execution transcripts (.jsonl per run)
```

#### `jobs.json` Structure

```json5
{
  "version": 1,
  "jobs": [
    {
      "id": "uuid",
      "name": "Human-readable name",
      "enabled": true,          // CRITICAL: failed jobs silently set this to false
      "schedule": {
        "kind": "cron",         // "cron" | "every" | "at"
        "expr": "0 23 * * *",   // 5-field cron expression
        "tz": "Europe/Rome",    // IANA timezone (optional)
        "staggerMs": 300000     // Auto-stagger for top-of-hour expressions
      },
      "sessionTarget": "isolated",  // "isolated" (fresh session) | "main" (inject into main)
      "wakeMode": "next-heartbeat", // "now" | "next-heartbeat"
      "payload": {
        "kind": "agentTurn",
        "message": "The cron prompt...",
        "model": "provider/model",
        "thinking": "high",
        "timeoutSeconds": 900
      },
      "state": {
        "nextRunAtMs": 1775077200000,
        "lastRunAtMs": 1774990800040,
        "lastStatus": "ok",        // "ok" | "error" | "timeout"
        "lastDurationMs": 650404,
        "consecutiveErrors": 0,
        "lastDelivered": true,
        "lastDeliveryStatus": "delivered"
      },
      "delivery": {
        "mode": "announce",   // "announce" | "webhook" | "none"
        "channel": "last"     // or specific channel
      }
    }
  ]
}
```

**Silent disable pattern:** When a cron job fails, backoff is 30s → 1m → 5m → 15m → 60m.
After enough consecutive failures, `enabled` is silently set to `false`. No notification.
Check for this with: `cat ~/.openclaw/cron/jobs.json | jq '.jobs[] | select(.enabled == false) | .name'`

### Hooks (`hooks/`)

```
hooks/
  <hook-name>/
    HOOK.md       # Frontmatter: name, description, events
    handler.ts    # TypeScript event handler
    openclaw/     # Nested hook pack (some hooks install this way)
```

**Hook enable/disable is in `openclaw.json`**, not in the hook directory:
```json5
{
  hooks: {
    internal: {
      enabled: true,
      entries: {
        "hook-name": { enabled: false }  // disable specific hook
      }
    }
  }
}
```

Gateway restart required after enabling/disabling hooks.

### Memory Index (`memory/`)

```
memory/
  <agentId>.sqlite    # SQLite database with embeddings + FTS5 index
```

**This is NOT the agent's memory files** (those are in the workspace). This is the search index.

Schema tables:
- `files` — mtime/hash for change detection
- `chunks` — text chunks with line numbers and SHA-256 hashes
- `embedding_cache` — cross-file embedding deduplication
- `chunks_fts` — FTS5 virtual table (BM25 keyword search)
- `chunks_vec` — vec0 virtual table (vector similarity search)

**Chunking:** ~400 tokens (~1600 chars) with 80-token overlap, line-aware splitting.
**File watcher:** 1.5-second debounce. Sync runs on session start, on search, or on interval.
**Reindex trigger:** Changing embedding provider/model triggers full reindex automatically.

**Debug:** If memory search returns bad results, the SQLite file may be stale or corrupt.
Delete it and let OpenClaw rebuild on next session start.

### Other Directories

| Directory | Contents | When to check |
|---|---|---|
| `credentials/` | Channel auth files (telegram-allowFrom.json, pairing state) | Channel access control issues |
| `devices/paired.json` | Paired control devices (hashed device IDs) | Remote control / pairing issues |
| `devices/pending.json` | Pending pairing requests | Pairing flow stuck |
| `delivery-queue/` | Outbound message queue (drains automatically) | Messages not delivering |
| `logs/commands.log` | Command execution audit log | Tracing what the agent executed |
| `logs/config-health.json` | Config diagnostics from last `doctor` run | Config validation |
| `logs/config-audit.jsonl` | Config change audit trail (timestamped) | Who changed what, when |
| `media/` | Files staged for channel delivery (Telegram `filePath` requires this) | File send failures |
| `tasks/runs.sqlite` | Background task tracking (SQLite + WAL) | Task state issues |
| `telegram/` | Telegram-specific state: command hashes, sticker cache, update offsets | Telegram weirdness |
| `subagents/runs.json` | Subagent execution tracking | Subagent debugging |
| `completions/` | Shell completion scripts (bash, zsh, fish, powershell) | Tab completion setup |
| `canvas/index.html` | Canvas tool UI | Canvas rendering |
| `.locks/` | Lock files for various subsystems | Deadlocks, concurrent access issues |
| `skills/` | **Managed skills** (installed via ClawHub) | Separate from workspace skills |

### Hidden Files

| File | What |
|---|---|
| `.env` | Environment variables loaded by gateway |
| `.telegram_token` | Telegram bot token (alternative to config) |

User-specific dotfiles may also appear here (e.g. private keys for custom tools/scripts). These are not OpenClaw framework files.

---

## `<workspace>/` Map

### Bootstrap Files (Injected Every Turn)

**Injection order (fixed):**
`AGENTS.md → SOUL.md → TOOLS.md → IDENTITY.md → USER.md → HEARTBEAT.md → BOOTSTRAP.md (first-run only) → MEMORY.md (private sessions only)`

**Subagents only receive:** AGENTS.md + TOOLS.md

**Per-file cap:** `bootstrapMaxChars` = 20,000 chars (default)
**Aggregate cap:** `bootstrapTotalMaxChars` = 150,000 chars (~50K tokens)

**Truncation (70/20/10):** Files over the per-file cap keep 70% head, 20% tail, drop the middle silently.

### Workspace Metadata

| File/Dir | What |
|---|---|
| `.openclaw/workspace-state.json` | Setup timestamp — marks workspace as initialized |
| `.clawhub/lock.json` | ClawHub skill install manifest — tracks installed versions + timestamps |
| `.git/` | Git repo (auto-initialized if git is installed) |
| `.gitignore` | Should exclude sensitive files |
| `.env` | Workspace-level environment variables |

### Skills Directory (`skills/`)

```
skills/
  .blocklist          # Skills intentionally removed (auto-updater checks this)
  .clawdhub/          # ClawHub metadata
  <skill-name>/
    SKILL.md          # Required — YAML frontmatter + body
    references/       # Optional — loaded on demand
    scripts/          # Optional — executable code
    assets/           # Optional — templates, output files
```

**Skill precedence:** workspace skills > managed skills (`~/.openclaw/skills/`) > bundled skills

**Blocklist pattern:** One skill name per line. Auto-updater cron should check this and
trash any blocklisted skill that gets reinstalled. Zombie skills (blocklisted but physically
present) are a common issue — the auto-updater doesn't always catch them.

---

## The OpenClaw Package Itself

Installed location varies by setup. Common: `~/.npm-global/lib/node_modules/openclaw/`

### Key package contents:

| Path | What | When useful |
|---|---|---|
| `docs/` | **Full official documentation** (~200+ markdown files) | Authoritative reference for any feature |
| `docs/gateway/configuration-reference.md` | Complete config key reference | Exact field semantics and defaults |
| `docs/reference/session-management-compaction.md` | Deep dive on sessions + compaction internals | Session debugging, compaction tuning |
| `docs/reference/memory-config.md` | All memory search config knobs | Memory/embedding tuning |
| `docs/gateway/troubleshooting.md` | Deep troubleshooting runbook | Gateway issues |
| `docs/channels/troubleshooting.md` | Per-channel failure signatures | Channel issues |
| `docs/gateway/sandbox-vs-tool-policy-vs-elevated.md` | Why a tool is blocked | Permission debugging |
| `docs/concepts/system-prompt.md` | How the system prompt is assembled | Understanding context injection |
| `docs/concepts/context-engine.md` | Pluggable context assembly | Custom compaction / context plugins |
| `docs/reference/templates/` | Default templates for SOUL.md, AGENTS.md, etc. | Starting fresh, comparing against defaults |
| `skills/` | Bundled skills | Lowest-priority skill source |
| `scripts/` | Setup and utility scripts (sandbox setup, etc.) | Installation, sandbox config |

**Finding docs path on any system:**
```bash
# npm global install
ls $(npm root -g)/openclaw/docs/

# Or find it
find / -path "*/openclaw/docs/gateway/configuration-reference.md" 2>/dev/null
```

---

## Log Files & Where to Find Them

| Log | Location | Format |
|---|---|---|
| Gateway file log | `/tmp/openclaw/openclaw-YYYY-MM-DD.log` | JSON lines (one object per line) |
| Command audit log | `~/.openclaw/logs/commands.log` | Text — what the agent executed |
| Config audit | `~/.openclaw/logs/config-audit.jsonl` | JSON lines — config changes |
| Config health | `~/.openclaw/logs/config-health.json` | JSON — last doctor diagnostics |
| Session transcripts | `~/.openclaw/agents/<id>/sessions/*.jsonl` | JSON lines — full conversation |
| Cron run transcripts | `~/.openclaw/cron/runs/*.jsonl` | JSON lines — cron execution logs |

**Tailing logs:**
```bash
openclaw logs --follow           # Gateway log (file-based)
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log  # Same thing, raw
```

**Log levels:** Configured via `logging.level` (file) and `logging.consoleLevel` (terminal).
`--verbose` only affects console, NOT file logs. Set `logging.level: "debug"` for verbose file logs.

---

## Diagnostic Commands Quick Reference

```bash
# Health & status
openclaw status                     # Overall status
openclaw gateway status             # Gateway runtime + RPC probe
openclaw doctor                     # Diagnose issues
openclaw doctor --fix               # Auto-fix common issues
openclaw security audit --deep      # Full security scan
openclaw channels status --probe    # Channel connectivity

# Context & tokens
/context list                       # What's injected (in chat)
/context detail                     # Token breakdown per file (in chat)

# Sessions
openclaw sessions list              # All active sessions
openclaw sessions cleanup --dry-run # Preview cleanup
openclaw sessions cleanup --enforce # Actually clean up

# Cron
openclaw cron list                  # All jobs + state
openclaw cron edit <id> --enabled false  # Toggle
openclaw cron run <id>              # Manual trigger

# Sandbox
openclaw sandbox explain            # What's sandboxed and why
openclaw sandbox explain --session agent:main:main

# Skills
openclaw skills list                # Installed skills
openclaw skills search <query>      # Search ClawHub

# Hooks
openclaw hooks list                 # All hooks + status
openclaw hooks enable <name>
openclaw hooks disable <name>

# Models & auth
openclaw models status              # Available models
openclaw config get agents.defaults.models  # Configured aliases

# Logs
openclaw logs --follow              # Tail gateway log
```

---

## Channel & Messaging Pipeline

How OpenClaw talks to the outside world. Understanding this flow is critical for debugging
"bot doesn't reply" and "message not delivered" issues.

### Message Flow

```
Inbound message (Telegram/Discord/Slack/WhatsApp/etc.)
  → Channel adapter normalizes to internal envelope
  → Routing: bindings → agent + session key
  → Deduplication (short-lived cache, prevents replays after reconnects)
  → Debouncing (batch rapid messages from same sender, configurable per-channel)
  → Queue (if agent is mid-run: collect/steer/interrupt mode)
  → Agent run (model call with tools + streaming)
  → Outbound: chunking → channel adapter → delivery
```

**Routing is deterministic.** The model does NOT choose which channel to reply on. Replies
always go back to the channel the message came from. Cross-channel messaging requires the
`message` tool with explicit channel targeting.

### Channel State Files

| Channel | State directory | Key files |
|---|---|---|
| Telegram | `~/.openclaw/telegram/` | `sticker-cache.json`, `update-offset-default.json`, `command-hash-*.txt` |
| WhatsApp | `~/.openclaw/whatsapp/` or Baileys state dir | Session auth state (QR pairing). Most fragile channel. |
| Discord | No dedicated state dir | Token in config or env var `DISCORD_BOT_TOKEN` |
| Slack | No dedicated state dir | App token + bot token in config |
| All channels | `~/.openclaw/credentials/` | `<channel>-allowFrom.json` (approved DM senders), `<channel>-pairing.json` (pending codes) |

### Channel Config in `openclaw.json`

All channel config lives under `channels.<provider>`:

```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "...",          // or env: TELEGRAM_BOT_TOKEN
      dmPolicy: "pairing",     // pairing | allowlist | open | disabled
      allowFrom: [123456789],  // numeric user IDs (NOT @usernames)
      groupPolicy: "allowlist", // allowlist | open | disabled
      groups: {
        "-1001234567890": {
          requireMention: true, // default: true
          groupPolicy: "open",
          allowFrom: ["*"],     // per-group sender filter
          // Forum topic routing:
          topics: {
            "42": { agentId: "coder", requireMention: false }
          }
        }
      },
      groupAllowFrom: [...],   // sender filter for all groups (NOT group ID list!)
      streaming: "partial",    // off | partial | block | progress
      actions: {
        sticker: false,        // sticker send/search
        sendMessage: true,
        deleteMessage: true,
        reactions: true,
      },
      replyToMode: "off",      // off | first | all
      linkPreview: true,
      // Per-account override: accounts: { main: { ... } }
    },
    discord: {
      enabled: true,
      token: "...",             // or env: DISCORD_BOT_TOKEN, or SecretRef
      guilds: {
        "SERVER_ID": {
          channels: { "*": { requireMention: true } }
        }
      }
      // Discord supports thread-bound sessions (`:thread:<threadId>`)
    }
  }
}
```

### Access Control Layers

Three gates control who can talk to the bot:

1. **DM policy** (`dmPolicy`): `pairing` (default) → unknown senders get a one-time code.
   `allowlist` → only explicit numeric IDs. `open` → anyone.
2. **Group policy** (`groupPolicy`): which groups are allowed + which senders within groups.
3. **Mention gating** (`requireMention`): even in allowed groups, require `@bot` mention.

**Common gotchas:**
- `allowFrom` takes **numeric IDs**, not `@usernames`. Run `openclaw doctor --fix` to resolve old username entries.
- `groupAllowFrom` is a **sender filter** (which users can trigger in groups), NOT a group ID list. Group IDs go under `groups`.
- Pairing codes expire after **1 hour**. Max 3 pending per channel.
- Pairing-store approvals do NOT carry over to group sender auth (security boundary since v2026.2.25).
- `groupPolicy: "allowlist"` with no `groups` configured = all groups blocked (fail-closed).
- Telegram privacy mode: bots only see group messages if privacy mode is disabled OR bot is admin. Toggle via BotFather `/setprivacy`, then remove + re-add bot.

### Session Key Shapes

Session keys determine context isolation:

| Source | Key shape | Notes |
|---|---|---|
| DM (default) | `agent:main:main` | All DMs share one session unless `dmScope` changed |
| DM (isolated) | `agent:main:<channel>:<senderId>` | When `dmScope: "per-channel-peer"` |
| Group | `agent:main:<channel>:group:<groupId>` | Each group = separate session |
| Telegram topic | `agent:main:telegram:group:<groupId>:topic:<threadId>` | Forum topics isolated |
| Discord thread | `agent:main:discord:channel:<channelId>:thread:<threadId>` | Thread-bound sessions |
| Cron | `agent:main:cron:<jobId>` | Fresh session per run |
| Subagent | `agent:main:subagent:<uuid>` | Isolated |

**DM scope** (`session.dmScope`): `main` (default, shared) → `per-peer` → `per-channel-peer` (recommended for multi-user).

### Outbound: Chunking & Streaming

Replies can be long. OpenClaw chunks them per channel limits:

| Channel | Chunk limit | Notes |
|---|---|---|
| Telegram | 4,000 chars | HTML parse mode, auto-retry as plain text on parse failure |
| WhatsApp | ~4,096 chars | Baileys-managed |
| Discord | 2,000 chars | `maxLinesPerMessage: 17` (soft cap to avoid UI clipping) |
| Slack | 4,000 chars | Block kit format |

**Two streaming layers** (separate, not alternatives):
- **Block streaming:** sends completed blocks as the model writes (coarse chunks, not token-by-token). Off by default.
- **Preview streaming (Telegram/Discord/Slack):** edits a temporary message while generating. Telegram default: `partial`.

### Delivery Pipeline

```
Agent reply → Chunker (min/max bounds, code fence safety)
  → Coalescer (optional: merge fragments, reduce "single-line spam")
  → Channel adapter formats (HTML for TG, embeds for Discord, etc.)
  → Delivery queue (~/.openclaw/delivery-queue/)
  → Channel API (Telegram Bot API, Discord Gateway, etc.)
```

**If messages aren't delivering**, check in order:
1. `openclaw channels status --probe` — is the channel connected?
2. `openclaw logs --follow` — look for send errors
3. `~/.openclaw/delivery-queue/` — are messages stuck?
4. Channel config: is the right account/token configured?
5. For Telegram: check `api.telegram.org` reachability (DNS/firewall)

### File Sends

Channels that support file attachments (Telegram, Discord, WhatsApp) require files staged to
`~/.openclaw/media/` first. The `message` tool's `filePath` only accepts paths under this directory.
Pattern: copy file to media dir → send → clean up.

### Reactions & Actions

Channel actions (react, delete, edit messages) are gated per-channel:
- `channels.<provider>.actions.<action>`: `true`/`false`
- Reaction scope: `messages.ackReactionScope` controls when the bot reacts vs replies.
  Values: `none`, `dm`, `group`, `group-mentions`, `all`.

### Per-Channel Debugging Quick Reference

| Channel | Status command | Common failure | Fix |
|---|---|---|---|
| Telegram | `openclaw channels status --probe` | Privacy mode blocks group messages | BotFather `/setprivacy` → remove + re-add bot |
| Telegram | Check logs for `BOT_COMMANDS_TOO_MUCH` | Too many skill/custom commands for TG menu | Reduce commands or disable native menus |
| Discord | `openclaw channels status --probe` | Missing Message Content Intent | Enable in Discord Developer Portal → Bot → Privileged Intents |
| WhatsApp | `openclaw channels status --probe` | Silent dead state / reconnect loops | Re-login. Reconnect attempts can trigger 48-72h bans |
| Slack | `openclaw channels status --probe` | Socket mode connected but no replies | Verify app token + bot token + required scopes |
| All | `openclaw pairing list <channel>` | DM sender not approved | Approve pairing code or add to allowlist |

### OpenClaw Docs for Channels

The official docs have extensive per-channel references. On the gateway host:

```
<openclaw-package>/docs/channels/telegram.md     # Telegram deep dive
<openclaw-package>/docs/channels/discord.md      # Discord setup + guild config
<openclaw-package>/docs/channels/whatsapp.md     # WhatsApp (Baileys) + QR pairing
<openclaw-package>/docs/channels/slack.md        # Slack Bolt SDK setup
<openclaw-package>/docs/channels/troubleshooting.md  # Per-channel failure signatures
<openclaw-package>/docs/channels/channel-routing.md  # Session key routing rules
<openclaw-package>/docs/channels/pairing.md      # DM pairing + node pairing
<openclaw-package>/docs/channels/groups.md       # Group policy + mention gating
<openclaw-package>/docs/concepts/messages.md     # Message flow + debouncing
<openclaw-package>/docs/concepts/streaming.md    # Streaming + chunking internals
```

Find the package path: `find / -path "*/openclaw/docs/channels/index.md" 2>/dev/null`

---

## Common "Where Is It?" Lookup Table

| You're looking for... | Check here |
|---|---|
| Why the agent ignores a rule | Is the rule in SOUL.md (main only) or AGENTS.md (main + subagents)? |
| Why a skill doesn't fire | `skills/<name>/SKILL.md` frontmatter `description` — is it specific enough? |
| Why a cron job stopped running | `~/.openclaw/cron/jobs.json` → check `enabled` field (silent disable) |
| What model is being used | `openclaw.json` → `agents.defaults.model.primary` + session overrides in `sessions.json` |
| Why compaction lost context | `openclaw.json` → `agents.defaults.compaction.memoryFlush.softThresholdTokens` — scaled for model? |
| Why the agent can't run a command | `~/.openclaw/exec-approvals.json` → is the binary in the allowlist? |
| Where API keys are | `~/.openclaw/.env`, `~/.openclaw/agents/<id>/agent/auth-profiles.json`, `openclaw.json` plugins section |
| Why messages aren't delivering | `~/.openclaw/delivery-queue/`, channel config in `openclaw.json`, `openclaw channels status --probe`, gateway logs |
| Why bot doesn't reply in groups | Telegram: privacy mode? BotFather `/setprivacy`. All: `groupPolicy`, `requireMention`, `groups` config |
| Why DM sender is blocked | `openclaw pairing list <channel>`, check `dmPolicy` + `allowFrom` (numeric IDs, not @usernames) |
| Where pairing/allowlist state lives | `~/.openclaw/credentials/<channel>-allowFrom.json` and `<channel>-pairing.json` |
| Why Telegram shows wrong bot commands | `BOT_COMMANDS_TOO_MUCH` — too many skill/custom commands. Reduce or disable native menus |
| Where the full conversation history is | `~/.openclaw/agents/<id>/sessions/<sessionId>.jsonl` |
| Why memory search returns bad results | `~/.openclaw/memory/<agentId>.sqlite` — may be stale. Delete to force reindex. |
| What the default SOUL.md should look like | OpenClaw package: `docs/reference/templates/SOUL.md` |
| Why the gateway won't start | Port conflict → `EADDRINUSE`. Check: `lsof -i :18789` or `ss -tlnp \| grep 18789` |
| Where channel-specific state lives | `~/.openclaw/telegram/`, `~/.openclaw/credentials/` |
| Why a subagent doesn't know the rules | Subagents only get AGENTS.md + TOOLS.md. Not SOUL.md, IDENTITY.md, USER.md, or MEMORY.md. |
| How to see what the model actually receives | `/context list` or `/context detail` in chat |
| Where cron job output went | `~/.openclaw/cron/runs/<jobId>.jsonl` |
| Why config change didn't take effect | Hot-reload mode: safe changes apply live, infrastructure changes need restart. Check `openclaw.json` `gateway.mode` |
