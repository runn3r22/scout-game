# OpenClaw Multi-Agent Configuration

> Sources: github.com/shenhao-stu/openclaw-agents, Medium multi-agent deployment guide

---

## Sub-Agent Spawning

- `sessions_spawn` creates child agents within a parent session
- The parent LLM decides when to spawn children (non-deterministic flow control)
- Sub-agent sessions get keys like `agent:<agentId>:subagent:<uuid>`
- **`maxSpawnDepth`** defaults to 1, maximum 2
  - Orchestrator pattern needs depth 2
  - Sub-agents at depth 2 cannot spawn further children

---

## Per-Agent Workspace Directory Structure

Each agent gets its own directory under `.agents/<agent_id>/`:

```
.agents/<agent_id>/
├── soul.md          — identity, personality, decision principles
├── agent.md         — model, tools, sandbox, inter-agent protocols
├── user.md          — user context, research profile, preferences
├── _soul_source.md  — agent-specific source (for first-run merge)
├── _soul_raw.md     — generic source
├── _user_source.md  — agent-specific user source
├── _user_raw.md     — template
├── _agent_source.md — config with model settings
└── BOOTSTRAP.md     — first-run instructions (auto-deleted after merge)
```

---

## Multi-Agent Setup Command

```bash
./setup.sh [--mode local|channel] [--channel CHANNEL]
  [--group-id GROUP_ID] [--group-map 'agent=groupid']
  [--model MODEL] [--model-map 'agent=model']
  [--require-mention true|false]
```

---

## Session Key Format

```
agent:<agentId>:<channel>:group:<groupId>
```

---

## Group Policy in openclaw.json

```json
{
  "channels": {
    "telegram": {
      "groupPolicy": "open",
      "groups": {
        "GROUP_ID": {
          "requireMention": true
        }
      }
    }
  }
}
```

Three policy levels:
- `"open"` — all groups allowed
- `"allowlist"` — only listed groups
- `"disabled"` — group messages dropped

---

## Per-Group Tool Restrictions

```json
{
  "tools": {
    "deny": ["exec", "write"]
  },
  "toolsBySender": {
    "id:123456789": { "alsoAllow": ["exec"] }
  }
}
```

---

## Inter-Agent Communication

- Each sub-agent has an **independent workspace** (no shared Docker sandbox)
- Agents communicate via `agentToAgent` tool in local mode
- In channel mode, agents operate in separate messaging groups

---

## Example: 9-Agent Research Team (Reference)

| ID | Name | Role |
|----|------|------|
| main | OpenClaw | System orchestrator, audit, arbiter |
| planner | Planner | Task decomposition, coordination |
| ideator | Ideator | Idea generation, novelty assessment |
| critic | Critic | Quality evaluation, anti-pattern detection |
| surveyor | Surveyor | Literature search, research gaps |
| coder | Coder | Algorithm implementation, experiments |
| writer | Writer | Paper writing, LaTeX formatting |
| reviewer | Reviewer | Internal peer review, rebuttal strategy |
| scout | Scout | Daily paper digest, trend monitoring |

---

## Application to Fair Architecture

```
Fair MD (orchestrator, maxSpawnDepth=2)
├── Judgement Agent (sub-agent, depth 1) — single Sonnet model, all steps
├── Research Agent (sub-agent, depth 1) — triggered by TRADE decisions
└── Farcaster Pipeline (existing autonomous pipeline)
```

This maps naturally to OpenClaw's spawn model:
- Fair MD spawns Judgement Agent per submission
- Judgement Agent runs all steps (thesis gate through deep analysis) in a single Sonnet session
- Model tiering (sub-agents per step) deferred to S1 via Lobster pipeline
