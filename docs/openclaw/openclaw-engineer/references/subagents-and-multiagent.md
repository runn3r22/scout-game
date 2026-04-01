# Subagents & Multi-Agent Architecture — Deep Reference

## What a Subagent IS and IS NOT

**IS:** A separate session (`agent:<agentId>:subagent:<uuid>`) spawned from an existing session.
Runs in the same Gateway process with isolated session state/transcript. When finished, announces
result back to the requester chat channel. Default: one-shot (`mode: "run"`).

**IS NOT:** A separate process or container (unless sandboxed). Not a separate personality by
default — inherits same agentId unless you specify `agentId`. Not persistent by default —
auto-archived after `archiveAfterMinutes` (default: 60).

## Context Injection: What Subagents See

| File | Main Session | Subagent |
|---|---|---|
| AGENTS.md | Auto-injected | Auto-injected |
| TOOLS.md | Auto-injected | Auto-injected |
| SOUL.md | Auto-injected | NOT injected |
| IDENTITY.md | Auto-injected | NOT injected |
| USER.md | Auto-injected | NOT injected |
| MEMORY.md | Auto-injected (private) | NOT injected |
| HEARTBEAT.md | Auto-injected | NOT injected |
| Skill list | Injected | Injected (same agent's skills) |

**Implication:** Subagents have no personality, no user context, no memory. They know HOW to
operate (AGENTS.md + TOOLS.md) but not WHO they are or WHO they serve.

**If you need a subagent to follow specific rules:** put them in AGENTS.md (which IS injected)
or explicitly tell it to `read` a specific file in the task prompt.

Skills are snapshotted at session start — installing a skill after spawning won't be visible.
`label` is display-only; use `agentId` to actually run under a different agent's workspace.

## Tool Policy by Depth

| Depth | Session tools | Other tools | Notes |
|---|---|---|---|
| 0 (main) | All | All | Full access |
| 1 (subagent, maxSpawnDepth=1) | None | All others | Default leaf behavior |
| 1 (orchestrator, maxSpawnDepth≥2) | sessions_spawn + management | All others | Can manage children |
| 2 (sub-subagent) | None, sessions_spawn always denied | All others | Always leaf |

Default `maxSpawnDepth: 1` — subagents CANNOT spawn subagents unless you increase this.

## sessions_spawn Parameters

| Param | Required | Default | Notes |
|---|---|---|---|
| `task` | Yes | — | The task prompt |
| `label` | No | — | Display name only (NOT agentId) |
| `agentId` | No | Same as caller | Different agent requires `allowAgents` |
| `model` | No | Inherits or `subagents.model` | Override model for this run |
| `thinking` | No | Inherits or `subagents.thinking` | Thinking level override |
| `runTimeoutSeconds` | No | `subagents.runTimeoutSeconds` or 0 | Abort after N seconds |
| `mode` | No | `"run"` | `"run"` = one-shot, `"session"` = persistent |
| `sandbox` | No | `"inherit"` | `"require"` rejects unless sandboxed |
| `cleanup` | No | `"keep"` | `"delete"` archives immediately |
| `attachments` | No | — | Inline files materialized into child workspace |

### Model Resolution Order
1. Explicit `sessions_spawn.model` parameter (highest priority)
2. Per-agent `agents.list[].subagents.model`
3. Global `agents.defaults.subagents.model`
4. Caller's model (inherited)

## Announce & Completion Flow

1. Subagent completes → OpenClaw runs an **announce step** inside the subagent session
2. Announce reply is posted to the requester chat channel
3. If subagent replies `ANNOUNCE_SKIP`, nothing is posted

Announce payload includes: result text, status (completed/failed/timed out), runtime stats
(duration, tokens, cost), sessionKey, transcript path.

**`sessions_yield`**: After spawning subagents, use this to end your current turn and wait for
results. The subagent completion arrives as your next message.

### Nested Announce Chain (Depth 2)
```
Depth-2 worker → announces to depth-1 orchestrator
Depth-1 orchestrator synthesizes → announces to main
Main agent → delivers to user
```
Each level only sees announces from its direct children.

## Cost Control Best Practices

### 1. Use cheaper models for subagents (biggest win)
```json5
{
  agents: {
    defaults: {
      subagents: {
        model: "google/gemini-2.5-flash-lite",
        thinking: "off",  // mechanical tasks don't need deep reasoning
      }
    }
  }
}
```

### 2. Restrict subagent tool surface (free token savings)
Tool schemas count toward context. Each unnecessary tool wastes tokens.
```json5
{
  tools: {
    subagents: {
      tools: {
        deny: ["message", "browser", "nodes", "canvas", "gateway", "cron"]
      }
    }
  }
}
```

### 3. Keep task prompts narrow + force concise output
- Include exact tool commands (subagents have no tribal knowledge)
- "Return 5 bullets + source URLs. Max 200 tokens."
- DON'T say "use bird" — say `bird search "query" -n 10`

### 4. Set timeouts
```json5
{
  agents: {
    defaults: {
      subagents: {
        runTimeoutSeconds: 900,  // 15 min default cap
      }
    }
  }
}
```

### 5. Control concurrency
```json5
{
  agents: {
    defaults: {
      subagents: {
        maxConcurrent: 4,         // prevent fan-out cost spikes
        maxChildrenPerAgent: 5,   // per-agent cap
      }
    }
  }
}
```

## Multi-Agent Architecture Patterns

### Pattern A: Main chat + specialized workers (most common)
```json5
{
  agents: {
    list: [
      { id: "main", default: true, workspace: "~/.openclaw/workspace",
        subagents: { allowAgents: ["researcher", "coder"] } },
      { id: "researcher", workspace: "~/.openclaw/workspace-researcher",
        tools: { allow: ["group:web", "read", "session_status"] } },
      { id: "coder", workspace: "~/.openclaw/workspace-coder",
        tools: { profile: "coding" } }
    ]
  }
}
```

### Pattern B: Force delegation via tool deny
Main agent CAN'T do web search → MUST spawn websearch agent.
```json5
{
  agents: {
    list: [
      { id: "main", tools: { deny: ["group:web"] },
        subagents: { allowAgents: ["websearch"] } },
      { id: "websearch",
        tools: { allow: ["group:web", "session_status"] } }
    ]
  }
}
```

### Pattern C: Dispatch agent for cron + orchestration
Separate main (interactive) from dispatch (background).
```
Main agent → DMs, interactive spawns
Dispatch agent → all cron jobs, background orchestration
  Workers write to inbox/ (never MEMORY.md directly)
  Dispatch is the single writer to canonical files
```

### Pattern D: Orchestrator pattern (depth 2)
```json5
{
  agents: {
    defaults: {
      subagents: {
        maxSpawnDepth: 2,
        maxChildrenPerAgent: 5,
        maxConcurrent: 8
      }
    }
  }
}
```
Flow: Main → Orchestrator (depth 1) → Workers A, B (depth 2) → Workers announce to Orchestrator → Orchestrator synthesizes and announces to Main.

Stopping a depth-1 orchestrator cascades to all depth-2 children.

## Workspace Isolation Options

### Default: shared workspace (subagents can read/write everything)
Subagent CAN read/write SOUL.md, MEMORY.md — it just doesn't auto-inject them.

### Pattern A: Separate agent workspaces
```json5
{
  agents: {
    list: [
      { id: "main", workspace: "~/.openclaw/workspace-main" },
      { id: "worker", workspace: "~/.openclaw/workspace-worker" }
    ]
  }
}
```
Requires `allowAgents: ["worker"]` on parent.

### Pattern B: Sandbox (OS-level isolation)
```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",          // sandbox all non-main sessions
        scope: "agent",
        workspaceAccess: "none"    // strongest: can't see host workspace
      }
    }
  }
}
```
- `"none"` → subagent works in `~/.openclaw/sandboxes/...`
- `"ro"` → can read but not write parent workspace
- Side effect: memory flush is SKIPPED when workspace isn't writable

## Common Subagent Pitfalls

| Problem | Cause | Fix |
|---|---|---|
| Subagent ignores SOUL.md rules | SOUL.md not injected for subagents | Put rules in AGENTS.md |
| Subagent can't spawn children | maxSpawnDepth=1 (default) | Increase or remove delegation logic from prompts |
| Subagent "doesn't know" skills | Using `label` instead of `agentId` | Use `agentId` + ensure `allowAgents` |
| Subagent writes where it shouldn't | Shared workspace, no restrictions | Sandbox or restrict tools |
| "TRACKED" items never implemented | Summary without file changes | Never use TRACKED — use IMPLEMENTED or DEFERRED |
| Subagent hallucinates from philosophy files | No tribal knowledge, treats observations as rules | Only use subagents for mechanical tasks |
| Same proposal repeats nightly | No memory of prior rejections | Flag recurring proposals as potentially invalid |

## When to Use Multi-Agent vs Single Agent

**Single agent (cheaper, shared context):** Sequential tasks, shared context needed between steps,
single-user systems, judgment-heavy work requiring tribal knowledge.

**Multi-agent (2-3x more tokens from inter-agent overhead):** Parallel independent tasks needing
different model strengths, strict domain isolation requirements, fan-out research patterns.

**Rule of thumb:** If you can describe the workflow as a sequence of steps a single person would
do, use one agent. If you'd naturally assign different people to work in parallel, use multi-agent.

## Monitoring & Debugging Subagents

```
/subagents list                  — list active runs
/subagents info <id>             — metadata, status, session id
/subagents log <id>              — transcript
/subagents log <id> tools        — tool call history
/subagents steer <id> <message>  — inject guidance mid-run
/subagents kill <id>             — stop specific subagent
/subagents kill all              — stop all
/context detail                  — token breakdown (in any session)
```

Transcripts live at path shown in announce payload. Use `sessions_history(sessionKey)` to
fetch programmatically. Archived transcripts renamed (not deleted): `*.deleted.<timestamp>`.
