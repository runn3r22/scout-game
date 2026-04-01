# OpenClaw System Prompt Architecture

> Source: docs.openclaw.ai/concepts/system-prompt + GitHub openclaw/openclaw

---

## How the System Prompt is Assembled

OpenClaw builds a custom system prompt for every agent run. The prompt is assembled from fixed sections:

1. **Tooling** — current tool list + short descriptions
2. **Safety** — advisory guardrails (not enforcement — enforcement is via tool policies, sandbox, allowlists)
3. **Skills** — on-demand skill loading instructions (metadata only: name + description + path, ~97 chars/skill)
4. **Self-Update** — how to run `config.apply` and `update.run`
5. **Workspace** — working directory + bootstrap files
6. **Documentation** — local docs paths
7. **Sandbox** — sandboxed runtime info when enabled
8. **Current Date & Time**
9. **Runtime** — environment details
10. **Reasoning visibility** — whether chain-of-thought is exposed

---

## Prompt Modes

| Mode | Use Case | Includes | Excludes |
|------|----------|----------|----------|
| **Full** (default) | Primary agents | All sections | Nothing |
| **Minimal** | Sub-agents | Tooling, Safety, Workspace, Sandbox, Date/Time, Runtime, injected context | Skills, Memory Recall, Self-Update, Model Aliases, User Identity, Reply Tags, Messaging, Silent Replies, Heartbeats |
| **None** | Bare identity | Base identity line only | Everything else |

When `promptMode=minimal`, extra injected prompts are labeled "Subagent Context" instead of "Group Chat Context."

---

## Bootstrap File Injection

Eight bootstrap files are injected into every turn's context:

| File | Every Turn (Primary) | Sub-Agent |
|------|---------------------|-----------|
| `AGENTS.md` | Yes | Yes |
| `SOUL.md` | Yes | **No** |
| `TOOLS.md` | Yes | Yes |
| `IDENTITY.md` | Yes | **No** |
| `USER.md` | Yes | **No** |
| `HEARTBEAT.md` | Heartbeat runs only | No |
| `BOOTSTRAP.md` | First run only | No |
| `MEMORY.md` | Private sessions only | No |

**Sub-agent sessions only inject `AGENTS.md` and `TOOLS.md`** — all other bootstrap files are filtered out to keep context small.

### Token Limits

| Setting | Default | Purpose |
|---------|---------|---------|
| `bootstrapMaxChars` | 20,000 chars | Per-file cap |
| `bootstrapTotalMaxChars` | 150,000 chars (~50K tokens) | Total cap across all files |
| `bootstrapPromptTruncationWarning` | `"once"` | `off` / `once` / `always` |

Files exceeding per-file cap are truncated: **70% from top, 20% from bottom, 10% truncation marker**. The middle is silently dropped.

### Bootstrap Hook

Internal hooks can intercept bootstrap injection via `agent:bootstrap` hook to mutate or replace injected files (e.g., swapping `SOUL.md` for an alternate persona).

---

## The 7KB Rule

Aim for all bootstrap files combined to total under ~7KB. One production user cut response times from 10 minutes to normal by reducing from 47,000 to 16,000 characters.

---

## Key Insight for Judgement Agent

- **SOUL.md must stay under 150 lines / 5KB** — it's injected every turn
- **Heavy reference material → skills** — loaded on-demand, not injected
- **Sub-agents only get AGENTS.md + TOOLS.md** — so the pipeline config must be in AGENTS.md
