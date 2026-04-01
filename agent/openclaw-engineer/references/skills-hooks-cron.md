# Skills, Hooks, Cron & Lobster — Deep Reference

## Skill Architecture

Skills follow the **AgentSkills specification** (shared with Claude Code, Cursor, GitHub Copilot).

### Directory Structure
```
skill-name/
├── SKILL.md          (required — YAML frontmatter + markdown body)
├── references/       (optional — docs loaded on demand)
├── scripts/          (optional — executable code)
└── assets/           (optional — templates, output files)
```

### Three-Level Progressive Disclosure
1. **Metadata** (name + description + path) — always in system prompt (~24 tokens/skill)
2. **SKILL.md body** — loaded only when LLM decides to read it (keep under 500 lines)
3. **references/scripts/assets** — loaded on demand from SKILL.md instructions

### Frontmatter Requirements
```yaml
---
name: my-skill-name         # lowercase, hyphens only. Cannot contain "claude" or "anthropic"
description: >
  What it does + when to use + trigger phrases.
  Third person only. Include synonyms. Add negative triggers for overlap.
metadata:
  openclaw:
    os: ["macos", "linux"]          # optional OS filter
    requires:
      bins: ["ffmpeg"]              # required binaries on PATH
      env: ["OPENAI_API_KEY"]       # required environment variables
    always: true                    # skip gating, always include (use sparingly)
    install:                        # installer specs
      brew: { packages: ["ffmpeg"] }
---
```

**No XML angle brackets (`< >`) in frontmatter** — security restriction.
**No README.md** or auxiliary documentation inside skill folders.
Use `{baseDir}` in SKILL.md body to reference the skill folder path.

### Description Quality (Most Common Skill Problem)

The description is the ONLY trigger mechanism. The model only sees descriptions at session start.
"When to use" in the body is invisible at routing time.

**Must include:**
- What the skill does
- When to trigger (specific contexts and user phrases)
- Trigger phrases and synonyms
- Negative triggers to prevent overlap with similar skills

**Style:** Third person ("Processes files..." not "I can help..."). Be slightly "pushy" — Claude
undertriggers skills by default. Include edge cases and indirect phrasings.

**Bad:** "Helps with data visualization"
**Good:** "Creates interactive data visualizations from CSV, JSON, or database queries. Use
whenever the user mentions charts, graphs, dashboards, plots, data visualization, metrics
display, or wants to see data visually — even if they don't explicitly say 'visualization'.
Do NOT use for static tables or simple number lookups."

### Skill Precedence
workspace skills (`<workspace>/skills/`) > managed skills (`~/.openclaw/skills/`) > bundled skills

Additional directories via `skills.load.extraDirs`.

### Skill Token Overhead

~24 tokens per skill in the metadata list. At 15+ skills, metadata alone can push compaction
within minutes. Only install skills the agent actually needs.

### ClawHub (Public Registry)
- `clawhub.ai` — 5,700+ community skills, embeddings-based search
- **ClawHavoc incident:** 341 malicious skills found (12% of registry), later ~800 (~20%)
- VirusTotal integration added (v2026.2.6) — not a silver bullet for prompt injection
- Installation: CLI (`clawhub install <slug>`), conversation, or direct URL
- Publishing requires GitHub account ≥1 week old. 3+ unique reports = auto-hidden

**Vetted curated list:** `github.com/VoltAgent/awesome-openclaw-skills` (5,400+ entries)

---

## Hooks

Hooks are TypeScript handlers fired on lifecycle events. They can inject content, transform
data, or log activity.

### Structure
```
~/.openclaw/hooks/<hook-name>/
├── HOOK.md       (required — frontmatter with name, description, events)
└── handler.ts    (required — event handler function)
```

### HOOK.md Frontmatter
```yaml
---
name: my-hook
description: "What this hook does"
metadata:
  openclaw:
    emoji: "🔧"
    events: ["agent:bootstrap", "tool_result_persist"]
---
```

### Available Events

| Event | When | Sync/Async |
|---|---|---|
| `agent:bootstrap` | Before workspace files inject (session start) | Async |
| `message:received` | After each incoming user message | Async |
| `tool_result_persist` | After tool execution, before result stored | **Sync** (can transform) |
| `command:new` | `/new` issued | Async |
| `command:reset` | `/reset` issued | Async |
| `command:stop` | `/stop` issued | Async |
| `gateway:startup` | Gateway starts | Async |

**Plugin lifecycle hooks (additional):** `before_model_resolve`, `before_prompt_build`,
`before_tool_call`/`after_tool_call`, `before_compaction`/`after_compaction`,
`message_received`/`message_sending`/`message_sent`, `session_start`/`session_end`

Context engine plugins get: `bootstrap`, `ingest`, `assemble`, `compact`, `afterTurn`,
`prepareSubagentSpawn`, `onSubagentEnded`

### Handler Pattern
```typescript
export default function handler(event) {
  // agent:bootstrap — inject virtual files into context
  if (event.type === 'agent' && event.action === 'bootstrap') {
    event.context.bootstrapFiles.push({
      path: 'MY_REMINDER.md',
      content: '...',
      virtual: true,  // doesn't appear on disk
    });
    return;
  }

  // tool_result_persist — transform tool output (SYNC, must return cleanly)
  if (event.message) {
    const text = extractText(event.message);
    if (containsError(text)) {
      const newMessage = JSON.parse(JSON.stringify(event.message));
      newMessage.content.push({ type: 'text', text: '<error-detected>...</error-detected>' });
      return { message: newMessage };
    }
  }
}
```

### Key Rules
- **Sync hooks** (`tool_result_persist`) can return transformed data — be careful
- **Async hooks** fire-and-forget
- Don't throw errors in handlers — swallow and log to avoid breaking main flow
- Gateway restart needed after enabling/disabling hooks
- Virtual files injected via `agent:bootstrap` don't appear on disk
- Hooks run with agent permissions — keep them minimal
- Priority ordering: `{ priority: 10 }` — lower numbers run first
- Disable prompt mutation per plugin: `plugins.entries.<id>.hooks.allowPromptInjection: false`

### The agent:bootstrap Hook (Powerful)
Fires before workspace bootstrap files are injected. Hooks can mutate `context.bootstrapFiles`,
enabling dynamic injection of additional files without modifying core workspace files. The
built-in `bootstrap-extra-files` hook uses this to inject files matching glob patterns.

### CLI Commands
```bash
openclaw hooks list                 # List all hooks + status
openclaw hooks info <name>          # Details
openclaw hooks enable <name>        # Enable
openclaw hooks disable <name>       # Disable
openclaw hooks install <path|npm>   # Install hook pack
openclaw hooks update               # Update installed
openclaw hooks check                # Check eligibility
```

---

## Cron System

Gateway-built-in, persists to `~/.openclaw/cron/jobs.json` (survives restarts).

### Schedule Types
- **`at`**: One-shot ISO 8601 timestamp
- **`every`**: Fixed interval in milliseconds
- **`cron`**: Standard 5-field cron expression with optional IANA timezone

Recurring top-of-hour expressions get deterministic per-job stagger of up to 5 minutes.

### Execution Modes
- **Main session** (`sessionTarget: "main"`): Enqueues system event, optionally wakes heartbeat
- **Isolated** (`sessionTarget: "isolated"`): Fresh session in `cron:<jobId>`, no prior context

### Delivery Modes
- `announce`: Delivers via outbound channel adapters
- `webhook`: POSTs to HTTP URL
- `none`: No external output

### Failed Job Behavior
Retry with exponential backoff: **30s → 1m → 5m → 15m → 60m**

**CRITICAL:** Failed jobs silently set `enabled: false` with no retry notification. Monitor
cron state actively. Check `~/.openclaw/cron/jobs.json` regularly.

### The OR-Logic Trap

When BOTH day-of-month AND day-of-week are specified, cron uses **OR** (not AND).

`0 5 1-7 * WED` fires on days 1-7 **OR** any Wednesday — NOT "first Wednesday only."

**Fix:** Use fixed dates, or add an in-task day check:
```bash
# In the cron job task: check if today is actually the first Wednesday
[ "$(date +%u)" = "3" ] && [ "$(date +%d)" -le 7 ] || exit 0
```

### Cron CLI
```bash
openclaw cron list                          # List all jobs
openclaw cron edit <jobId> --enabled false   # Toggle
openclaw cron run <jobId>                   # Manual trigger
openclaw cron delete <jobId>                # Remove
```

---

## Heartbeat System

Runs periodic agent turns on a configurable timer (default 30m, 1h with Anthropic OAuth).

Each tick: Gateway sends heartbeat prompt → agent reads HEARTBEAT.md → evaluates → replies
with alert or `HEARTBEAT_OK`.

- `HEARTBEAT_OK` responses are silently dropped (stripped if remaining content ≤300 chars)
- Empty HEARTBEAT.md (only blank lines/headers) → heartbeat run skipped entirely
- `activeHours` restricts to time window (default: 08:00-22:00 user timezone)

### Production Recommendation
Disable native heartbeat and use isolated cron heartbeat instead:
```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "0m",          // disable native heartbeat
        lightContext: true,    // if keeping native, only inject HEARTBEAT.md
      }
    }
  }
}
```
Then create a cron job for the heartbeat cadence. This avoids loading full conversation history.

### Cost by Model
- Opus heartbeat every 30m: ~$7.20/month
- Haiku heartbeat every 30m: ~$0.15/month

---

## Lobster Workflow Engine

OpenClaw's native workflow engine using `.lobster` YAML files.

### Capabilities
- Steps with `id`, `command` (shell) or `lobster` (sub-workflow)
- Inter-step data piping: `$stepId.stdout`/`$stepId.json`
- Approval gates: `approval: required` (halts until approved)
- Resume tokens for halted workflows
- Loops with `max`/`condition` support
- Safety constraints: timeouts, output caps, sandbox checks

### Integration
Exposed as a single tool call. **Optional plugin tool** — not enabled by default.

---

## Plugin System

Plugins are TypeScript modules loaded in-process via **jiti** — they are NOT sandboxed and
share the trust boundary of core code.

### Plugin API (`OpenClawPluginApi`)
`registerTool()`, `registerHook()`, `registerHttpHandler()`, `registerHttpRoute()`,
`registerChannel()`, `registerGatewayMethod()`, `registerCli()`, `registerService()`,
`registerProvider()`, `registerCommand()`

### Plugin Slots (Exclusive — Only One Per Category)
- `plugins.slots.contextEngine`
- `plugins.slots.memory`

### Discovery Order
config paths → workspace extensions → global extensions → bundled extensions
