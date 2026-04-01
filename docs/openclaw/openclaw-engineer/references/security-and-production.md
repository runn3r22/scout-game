# Security & Production Patterns — Deep Reference

## Gateway Architecture

When you run `openclaw gateway`, you start a single long-lived Node.js 22+ process that serves
as the sole control plane. There is no separate web server, database, or message broker.

- Binds to `ws://127.0.0.1:18789` (loopback-only by default)
- WebSocket RPC with TypeBox validation: Request, Response, Event frames
- Also serves Control UI and WebChat at `http://127.0.0.1:18789/`
- Exactly one Gateway per host (prevents WhatsApp session lock conflicts)

### Agent Loop Triggers
Five input vectors: inbound messages, heartbeats, webhooks (`/webhook/<path>`), cron jobs,
agent-to-agent messages. System events via `openclaw system event` force immediate wake.

### Auth Scopes
- `operator.admin`: Full config access
- `operator.write`: Agent runs and cron
- `operator.read`: Status queries
- `operator.approvals`: Exec approval grant/deny

---

## Known CVEs and Security Incidents

### CVE-2026-25253 (CVSS 8.8) — 1-Click RCE
Disclosed January 30, 2026. Control UI trusted `gatewayUrl` from query strings without
validation and auto-connected via WebSocket, sending the stored gateway token. Combined with
missing origin header validation, any website could steal the auth token and achieve remote
code execution. **30,000+ internet-exposed instances**, 5,194 verified vulnerable.
**Patched in v2026.1.29.** Ensure you're on this version or later.

### ClawHavoc — Malicious Skills Campaign
341 malicious skills found in ClawHub (12% of registry), primarily from a single campaign
delivering Atomic macOS Stealer (AMOS). Updated scans: **~800 malicious skills (~20%)**.
Cisco independently confirmed data exfiltration from third-party skills.

VirusTotal integration added (v2026.2.6) — scans all published skills, SHA-256 hash checks,
suspicious flagged, malicious blocked. Rescanned daily. Not a silver bullet against prompt
injection payloads embedded in natural language.

**Snyk finding:** 36% of skills contain some form of prompt injection.

---

## Security Hardening Checklist

### 1. Bind Gateway to Loopback Only
Default is already `127.0.0.1`, but verify. Never expose to `0.0.0.0` without a proxy.
135K+ instances are publicly accessible on the internet.

### 2. Protect Workspace Files
```bash
chmod 444 SOUL.md IDENTITY.md   # Prevent agent self-modification via prompt injection
```
Agent can still read these files but cannot rewrite its own personality or identity.

### 3. Use Tool Profiles for Untrusted Contexts
```json5
{
  tools: {
    profile: "minimal"    // session_status only
    // "coding": group:fs, group:runtime, group:sessions, group:memory, image
    // "messaging": group:messaging, sessions tools
    // "full": no restriction (default)
  }
}
```

### 4. Enforce Channel Access Control
```json5
{
  channels: {
    telegram: {
      dm: { policy: "allowlist", allowlist: [123456, 789012] },  // numeric IDs, NOT @usernames
      groups: { policy: "allowlist", requireMention: true }
    }
  }
}
```

### 5. Isolate DM Sessions
```json5
{
  session: {
    dmScope: "per-channel-peer"   // prevents cross-user data leakage
    // "main" = all DMs share one session (dangerous)
    // "per-peer" = isolate by sender
    // "per-channel-peer" = isolate by platform + sender (recommended)
  }
}
```

### 6. Sandbox Non-Main Sessions
```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",          // sandbox all non-main sessions
        workspaceAccess: "ro"      // or "none" for strongest isolation
      }
    }
  }
}
```

### 7. Set Explicit Tool Allow Lists
```json5
{
  tools: {
    allow: ["read", "write", "edit", "exec", "memory_search", "memory_get"],
    deny: ["browser", "gateway"]
  }
}
```
Deny always wins regardless of allow lists.

### 8. Set Provider-Level Spend Caps
Configure per-provider budget limits to prevent runaway costs from misconfigured heartbeats
or tool loops.

### 9. Run Security Audit
```bash
openclaw security audit --deep    # Full security scan — run before any network exposure
openclaw doctor --fix             # Diagnose and auto-fix common issues
```

### 10. Use Latest-Gen Models for Tool-Enabled Agents
Smaller/cheaper models are significantly less robust against prompt injection. Always use
latest-generation instruction-hardened models when the agent has tool access.

---

## Tool Execution: 9-Tier Deny-Wins Policy Stack

Every tool passes through 9 policy layers where each can only narrow permissions:
1. Profile policy
2. Provider tool profile
3. Agent allow/deny
4. Agent provider policy
5. Group policy
6. Sandbox policy
7. Subagent inheritance
8. Plugin allowlist
9. Tool group expansion

**If any layer denies a tool, it's blocked regardless of all other allowlists.**

### Tool Groups
| Group | Tools |
|---|---|
| `group:runtime` | exec, bash, process |
| `group:fs` | read, write, edit, apply_patch |
| `group:sessions` | sessions_list, sessions_history, sessions_send, sessions_spawn, session_status |
| `group:memory` | memory_search, memory_get |
| `group:web` | web_search, web_fetch |
| `group:ui` | browser, canvas |

### Exec Approvals
Location: `~/.openclaw/exec-approvals.json`

Three modes: `deny` (block all), `allowlist` (glob-matched binaries), `full` (skip approvals).

The `ask` field: `on-miss` (prompt for unlisted), `always` (prompt for everything), `off` (never).

Shell chaining (`&&`, `||`, `;`) allowed only if every segment satisfies allowlist. Redirections
and command substitution are rejected.

Safe bins that bypass allowlisting: `jq`, `grep`, `cut`, `sort`, `uniq`, `head`, `tail`, `tr`, `wc`.

---

## Docker Sandboxing

Three modes:
- `off`: No sandboxing
- `all`: Everything sandboxed
- `non-main` (default): Sandbox all non-main sessions

Workspace access levels:
- `"rw"`: Full read-write access
- `"ro"`: Write/edit/apply_patch disabled
- `"none"`: File tools route through Docker exec bridge

---

## Browser Automation

CDP (Chrome DevTools Protocol) in three modes:
- OpenClaw-managed Chromium (isolated profile)
- Extension relay (preserves existing Chrome auth)
- Remote CDP (cloud services via WebSocket)

Accessibility snapshots: AI-mode (numeric refs, Playwright-based) and role-mode (`e`-prefixed refs).
**CSS selectors intentionally not supported** for actions — only snapshot refs work.
Screenshots downscale to `imageMaxDimensionPx: 1200` by default.

---

## Auth Rotation & Model Failover

Auth profiles tried sequentially from `auth.order` array:
- HTTP 429 → rotate to next profile within same provider
- All profiles fail → fall to next model in `agents.defaults.model.fallbacks`
- Profiles **pinned per session** (not rotated per request) — keeps prompt caches warm
- Pinned profile resets on: `/new`, `/reset`, or compaction

**Known bug #25510:** Auto session override can bypass manual ordering.

Backoff schedule: **1 min → 5 min → 25 min → 1 hour cap** — resets after 24 hours without failure.

**Rate limits on one model trigger cooldown for the entire provider**, not just that model.

---

## Production Deployment Patterns

### OpenClaw Guardian (Auto-Repair Watchdog)
- Daily git commits of workspace files
- Auto-repair via `openclaw doctor --fix` (3 attempts)
- Auto-rollback to last stable commit on failure
- 300-second cooldown before resuming monitoring

### Version Control Best Practices
**Commit:** AGENTS.md, SOUL.md, USER.md, TOOLS.md, IDENTITY.md, MEMORY.md, `memory/*.md`
**Never commit:** `~/.openclaw/` config, session data, credentials

New workspaces are auto-initialized as git repos if git is installed.

### Self-Evolution Guardrails
**Safe:** Agent accumulates skills + domain knowledge.
**Unsafe:** Agent rewrites SOUL.md, changes model selection, modifies security policies.

Recommended:
- Git-track `~/.openclaw/` and workspace
- Human review gate for promoted learnings
- Weekly review of auto-promoted rules
- `chmod 444` on SOUL.md/IDENTITY.md

### Config Gotchas
- `config.patch` resolves `${VAR}` environment variable references and writes **plaintext
  secrets** back to disk (known issue #15932)
- Hot-reload modes: `hybrid` (default), `hot`, `restart`, `off`
  - `hybrid` hot-applies safe changes, auto-restarts for infrastructure changes

### Channel-Specific Notes

**Telegram (most reliable):**
- Built on grammY. Messages chunked at 4,000 chars.
- Stream modes: `partial` (default, edit-based), `block`, `off`
- DM policies: `pairing` (default), `allowlist` (numeric IDs, not @usernames), `open`, `disabled`
- Known bug: BOT_COMMANDS_TOO_MUCH when registering 100+ skill commands on startup

**WhatsApp (most problematic):**
- Uses Baileys library. Silent dead states, reconnect loops.
- Reconnect attempts can trigger 48-72 hour bans.
- Single session lock per host — can't run multiple agents.

**Discord:**
- Thread-bound sessions supported (only platform with this feature)
- Topic threads get their own session keys via `:topic:<threadId>` suffixes

### Monitoring Commands
```bash
openclaw doctor --fix              # diagnose + auto-fix
openclaw security audit --deep     # full security scan
/context list                      # see injected context files
/context detail                    # token breakdown
openclaw cron list                 # check cron job states
```
