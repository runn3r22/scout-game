# OpenClaw Skills System

> Source: github.com/openclaw/openclaw/docs/tools/skills.md

---

## How Skills Work

Skills extend the agent's capabilities. Only **metadata** (name + description + path) is injected into the system prompt (~97 chars per skill). The full `SKILL.md` content loads only when the agent decides to use it.

This is the key mechanism for keeping the system prompt lean while giving the agent access to detailed reference material.

---

## Directory Structure & Loading Precedence

1. **Workspace skills**: `<workspace>/skills/` (highest priority)
2. **Managed/local skills**: `~/.openclaw/skills/`
3. **Bundled skills** (shipped with install, lowest priority)

Additional skill folders configurable via `skills.load.extraDirs` in `~/.openclaw/openclaw.json`.

---

## SKILL.md YAML Frontmatter Format

```yaml
---
name: skill-identifier
description: Brief description of what the skill does
homepage: https://example.com          # optional
user-invocable: true                   # optional, default true
disable-model-invocation: false        # optional, default false
command-dispatch: tool                 # optional, enables direct tool dispatch
command-tool: tool-name                # optional, specifies which tool
command-arg-mode: raw                  # optional, forwards unprocessed args
---

# Skill body — full instructions, reference material, etc.
# This content is loaded ONLY when the agent activates the skill.
```

The parser supports **single-line frontmatter keys only**, and `metadata` must be a **single-line JSON object**.

---

## Metadata Gating Rules

```json
{
  "openclaw": {
    "requires": {
      "bins": ["binary-name"],
      "anyBins": ["alt1", "alt2"],
      "env": ["ENV_VAR"],
      "config": ["openclaw.json.path"]
    },
    "primaryEnv": "ENV_VAR_NAME",
    "emoji": "...",
    "os": ["darwin", "linux", "win32"],
    "always": true
  }
}
```

---

## Config Overrides in openclaw.json

```json
{
  "skills": {
    "entries": {
      "skill-name": {
        "enabled": true,
        "apiKey": { "source": "env", "provider": "default", "id": "VAR_NAME" },
        "env": { "VAR_NAME": "value" },
        "config": { "customKey": "customValue" }
      }
    }
  }
}
```

Environment injection is scoped to the agent run, not a global shell environment, and only applies if the variable is not already set.

---

## Skill Loading Behavior

- OpenClaw snapshots eligible skills when a session starts and reuses that list for subsequent turns
- Hot reloading can be enabled via `skills.load` config when `SKILL.md` files change
- Skills are activated by the agent's decision — it reads the description and decides when to load the full content

---

## Warning: Skill Metadata Overhead

Even metadata adds up fast. Running **15+ skills** means the metadata alone can push context toward compaction thresholds. Only install skills the agent actually needs for its role.

For the Judgement Agent: 3 skills (snapshot-interpretation, deep-analysis, anti-gaming) = ~291 chars of metadata overhead. Well within budget.
