# Scout Game — OpenClaw Implementation Notes

**For: Fair team**
**From: OpenClaw engineering review**
**Date: 2026-03-17**
**Scope: GP test (S0) — Telegram only**

---

## TL;DR

The spec v2 is solid. The single-agent-with-skills architecture is the right call for OpenClaw. But starting on Telegram instead of X for the GP test eliminates ~60% of the implementation complexity and lets you validate the thing that actually matters: whether the evaluation pipeline produces good scores.

This doc covers: what changes for TG-only, the revised file split (SOUL.md vs AGENTS.md), OpenClaw-specific gotchas, and a concrete build sequence.

---

## 1. Why Telegram First

The spec describes an X/Twitter flow: scout tags @fairvc → agent evaluates → agent replies on X. For the GP test with 5-10 known people, this adds:

- X API costs ($200/mo Basic tier minimum)
- An external intake service to poll mentions and send immediate receipts
- Public reply management (rate limits, threading, spam detection)
- Privy auth for wallet verification

None of this tests the evaluation pipeline. All of it adds failure modes.

**Telegram-only GP test:**
- OpenClaw's most reliable channel adapter (Telegram >> WhatsApp >> everything else)
- GPs post CA + thesis directly in a dedicated TG group
- Agent evaluates inline, replies in the same group
- SIGNAL/TRADE reviews go to a separate team TG channel
- Wallet verification is manual (you know these 10 people)
- Zero external API dependencies beyond LLM + GeckoTerminal + BaseScan + Supabase

You can add X integration for S1 public launch. The evaluation pipeline, scoring rubric, and points logic are identical either way.

---

## 2. Revised File Architecture

### What Changed from the Draft

The original SOUL.md was doing double duty — identity AND operational manual in one file. This causes two problems on OpenClaw:

1. **Truncation risk.** If a file exceeds 20K chars, OpenClaw's 70/20/10 rule drops the middle. SOUL.md was safe at ~5KB, but as the agent evolves and you add edge cases, it'll grow. Keeping files focused means the critical content survives.

2. **Cognitive clarity for the LLM.** Models handle "who you are" and "how you work" better as separate contexts. SOUL.md establishes character and hard constraints. AGENTS.md provides the operational playbook. The model can reference either without cross-contamination.

### The Split

**SOUL.md (~3KB) — injected every turn:**
- Core character (skeptical, founder-obsessed, one-shot)
- Decision authority table (the 4-tier action/score mapping)
- Hard rules (no hallucination, no financial advice, cost discipline, text-only)
- Reply tone guidance (lowercase, blunt, no coaching)
- That's it. ~65 lines.

**AGENTS.md (~7KB) — injected every turn:**
- Input format (what a valid submission looks like)
- Full 6-step evaluation pipeline with rubrics
- Output JSON schema
- Reply templates for each outcome (TG-specific for GP test)
- Team review message format
- Points calculation logic (base × tier × cap)
- Multi-scout credit and retroactive upgrade rules
- Watch flag guidance
- Memory strategy (Supabase for state, OpenClaw daily notes for self-calibration only)
- Tool usage patterns

**TOOLS.md (~2KB) — injected every turn:**
- API-specific notes for GeckoTerminal, BaseScan, Supabase, web/X search
- Keep this lean. Tool schemas already cost ~8K tokens in context.

**Total bootstrap: ~12KB.** Well under the 20K per-file cap and 150K aggregate cap.

### Skills (on-demand, NOT injected every turn)

| Skill | ~Size | Loaded when |
|-------|-------|-------------|
| `snapshot-interpretation` | ~5KB | Step 3 — only 20-30% of submissions reach this |
| `deep-analysis` | ~6KB | Step 5 — only submissions passing Step 3 |
| `anti-gaming` | ~3KB | S1+ only, not loaded during GP test |

3 skills = ~291 chars of metadata in system prompt. Negligible.

### What I Removed from SOUL.md

These moved to AGENTS.md:
- The full evaluation pipeline (Steps 1-6)
- X reply templates (replaced with TG reply templates)
- Signal output flow details
- Retroactive points logic
- Watch flag specifics
- Architecture context (Supabase sharing, Farcaster pipeline relationship)

These were removed entirely:
- `triggers` in frontmatter (OpenClaw doesn't use these for routing — they're decorative)
- References to X/Twitter flow (not needed for GP test)
- "Response time: 3 minutes" constraint (moved to a note below — see Section 4)

---

## 3. OpenClaw Configuration for GP Test

### openclaw.json key settings

```jsonc
{
  "agents": {
    "defaults": {
      "model": "claude-sonnet-4-20250514",  // single model for GP test
      "model.fallbacks": ["claude-haiku-4-5-20251001"],
      "compaction": {
        "model": "claude-haiku-4-5-20251001",  // cheap model for summarization
        "mode": "safeguard"
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "allowFrom": ["scout-submissions-group-id", "team-review-group-id"]
    }
  },
  "heartbeat": {
    "every": "0m"  // disable native heartbeat — use cron instead
  },
  "dmScope": "per-channel-peer",
  "sandbox": "non-main",
  "softThresholdTokens": 20000,
  "reserveTokensFloor": 30000
}
```

### Why these values

**Single model (Sonnet) for GP test.** The spec calls for Haiku on Step 2 (thesis quality gate) and Sonnet for Steps 3-5. OpenClaw pins models per session — you can't switch mid-evaluation. At GP test volume (25-50 submissions/day), the cost difference is ~$1-2/day. Not worth the architectural complexity of model tiering yet. Run everything on Sonnet. Optimize for S1+.

**`softThresholdTokens: 20000` and `reserveTokensFloor: 30000`.** Sonnet's context is 200K. With these settings, maintenance compaction triggers at ~150K tokens, well before overflow. Each evaluation is roughly 3-8K tokens (system prompt + submission + tool results + skill loads). At 50 submissions/day in a shared session, you'd hit ~150K within ~20-25 evaluations. This is fine — compaction fires gracefully, the agent flushes calibration notes to daily notes, and continues.

**`heartbeat.every: "0m"`.** Disables native heartbeat (which loads full history every run — massive token waste). Set up an isolated cron instead for the daily FDV snapshot job.

**`dmScope: "per-channel-peer"`.** Isolates sessions per channel per contact. The scout submission group and team review group get separate sessions. Prevents cross-contamination.

---

## 4. Architecture Decisions

### Session strategy: fresh session per batch, not per submission

Don't start a new session for every single submission — you lose prompt cache benefits and the agent can't notice patterns across evaluations within a batch.

Don't use one long-running session either — context accumulates and compaction will fire repeatedly, degrading quality.

**Recommended:** Process submissions in hourly batches. Start a fresh session each batch (or let the Lane Queue's `collect` mode coalesce messages). Agent evaluates all submissions in the batch sequentially, writes results to Supabase, then the session can be reset. This gives you:
- Prompt cache reuse within the batch (system prompt + skills cached)
- Bounded context growth (max ~25 evaluations per batch at peak)
- Clean state between batches

For the GP test with 25-50 daily submissions, you'll have 2-4 submissions per hourly batch on average. Context stays well under compaction thresholds.

### Step 1 (Structural Filter) can't be truly free on OpenClaw

The spec says "No LLM, $0" but every message that hits the OpenClaw agent goes through the LLM. There's no way to short-circuit before the model sees it.

For GP test: just accept the cost. The agent reads the message, checks for a CA, and rejects structurally invalid submissions in the same LLM turn. At Sonnet pricing, this is ~$0.003 per non-submission message. With 10 GPs who might send a few non-submission messages, this is negligible.

For S1+: build an external intake service (lightweight Node.js) that polls X API mentions, runs structural checks, and only forwards valid submissions to OpenClaw. This sits outside OpenClaw entirely and handles the "instant receipt reply" on X.

### The 3-minute evaluation target

Realistic assessment for the full pipeline (Steps 1-6):
- Step 1-2 (structural + thesis gate): ~5-10 seconds
- Step 3 (snapshot — GeckoTerminal + BaseScan + factory check): ~15-30 seconds per tool call, 3-4 calls = ~60-90 seconds
- Step 4 (DB context check): ~5-10 seconds
- Step 5 (deep analysis + live web/X search for founder): ~30-90 seconds
- Step 6 (final score + write to Supabase + TG replies): ~10-20 seconds

**Total: 2-4 minutes for a full evaluation.** 3-minute target is tight but achievable if external APIs respond quickly. The bottleneck is founder web search (Step 5).

Suggestion: don't hard-enforce the time constraint in the SOUL.md. Let evaluations take as long as they need for quality. GPs on Telegram are more patient than public X users. Track actual evaluation times and optimize before S1.

### What handles points settlement?

The Judgement Agent calculates base points and weighted points per submission and writes them to Supabase. That's where its job ends.

The daily/weekly pool split, leaderboard ranking, and Hedgey claim campaigns are **not the Judgement Agent's job.** These should be:
- A cron job (can be an OpenClaw cron or a standalone script) that runs daily at UTC midnight
- Queries `scout_submissions` for the day's weighted points
- Calculates each scout's share of the daily pool
- Writes to `scout_points_daily` and `scout_leaderboard`
- Posts a daily digest to the team TG channel

For GP test, this can be a simple script. Doesn't need to be an OpenClaw agent.

### What handles retroactive point upgrades?

Same pattern. A daily cron job that:
- Checks all DB_SAVE'd tokens from the last 14 days
- Compares against any SIGNAL/TRADE actions from any pipeline (Farcaster, re-scan, another scout)
- If a match: retroactively upgrades the original scout's points and logs to digest

This is a Supabase query, not an LLM task.

### What handles the daily FDV snapshot?

An OpenClaw cron job running on Haiku:
- Every 24h, pull current FDV for all tokens with action = SIGNAL or TRADE
- Write to a `token_performance` table in Supabase
- Calculate 7/14/30 day performance vs signal-time FDV
- Include in the daily digest

```jsonc
// in openclaw.json
"cron": [
  {
    "id": "fdv-snapshot",
    "schedule": "0 0 * * *",  // midnight UTC
    "model": "claude-haiku-4-5-20251001",
    "task": "Pull current FDV for all SIGNAL/TRADE tokens and update token_performance table."
  }
]
```

### Watch flag → traction notification flow

The spec says "other agents can notify the Judgement Agent about traction updates." For GP test, keep this simple:

1. The daily FDV snapshot cron detects significant moves (>2x FDV since evaluation)
2. It writes a message to a `traction_alerts` channel/file
3. The Judgement Agent checks this at the start of each batch (or it's posted to the scout submission group as a system message)

Don't build a complex inter-agent notification system for GP test. A shared Supabase table (`traction_alerts`) that both the cron and the Judgement Agent can read is sufficient.

---

## 5. What to Build (Priority Order)

### P0 — Must have for GP test launch (~30h)

1. **SOUL.md + AGENTS.md + TOOLS.md** — revised files (drafts attached)
2. **`snapshot-interpretation` skill** — GeckoTerminal + BaseScan + factory registry interpretation
3. **`deep-analysis` skill** — 5-dimension scoring rubric + investment frameworks
4. **`factory-registry.json`** — Clanker, Bankr, Flaunch, Virtuals, Noice, Creator Bid
5. **Supabase schema** — `scout_submissions` table (at minimum), extend existing `projects` and `agent_memory`
6. **Telegram channel setup** — scout submission group + team review group, agent configured in both
7. **Supabase tool registration** — read/write tools for the agent
8. **End-to-end test** — one real submission through the full pipeline, verify JSON output, verify TG replies in both channels

### P1 — Should have for GP test (~10h)

9. **Daily digest cron** — points summary, acceptance rates, notable evaluations
10. **Daily FDV snapshot cron** — performance tracking for SIGNAL/TRADE tokens
11. **Points settlement script** — daily pool calculation (can be manual for GP test)
12. **`openclaw doctor --fix`** — run after all config changes

### P2 — Nice to have / S1 prep (~20h)

13. **`anti-gaming` skill** — coordinated push detection, template farming, thesis padding
14. **X API integration** — intake service, mention polling, public reply flow
15. **Privy auth integration** — wallet verification for public scouts
16. **Retroactive upgrade cron** — automated 14-day lookback
17. **Lobster pipeline** — model tiering (Haiku for Step 2, Sonnet for Steps 3-5)
18. **Public leaderboard** — fair.fun or similar

---

## 6. Specific Notes on the SOUL.md Draft

### What was good
- Core character is sharp. "Skeptical by default" + "founder-obsessed" + "one-shot" gives the model clear behavioral rails.
- The decision authority table is the right thing to put in SOUL.md — it's the single most important reference.
- "Tier ≠ score" as a hard rule is critical and correctly placed.
- Asymmetric risk framing ("false positive > false negative but don't waste genuine signals with lazy rejects") is the right nuance. Most people write this as one-sided.

### What I changed
- **Removed the full pipeline.** Steps 1-6 with all their details belong in AGENTS.md. SOUL.md just references "the thesis quality gate (Step 2)" without re-specifying the full rubric.
- **Removed X reply templates.** Replaced with TG-specific guidance. The X flow can be added back when S1 launches.
- **Removed signal output flow.** Operational detail for AGENTS.md.
- **Removed retroactive points specifics.** AGENTS.md handles the mechanics.
- **Removed architecture context.** The Supabase sharing, Farcaster pipeline relationship — that's operational context, not identity.
- **Simplified reply tone to a principle** rather than exact templates. Templates are in AGENTS.md.
- **Removed the 3-minute response time constraint.** It's aspirational for GP test and creates pressure to cut corners on founder research. Track actual times instead.
- **Removed `triggers` from frontmatter.** OpenClaw doesn't use these for message routing. They're decorative metadata that wastes tokens.

### Why the frontmatter still matters
The `name`, `description`, and `metadata.openclaw` fields are used by the OpenClaw multi-agent system for agent discovery. Keep `role: sub-agent` and `parent: fair-md` — these tell the orchestrator how this agent fits in the hierarchy. The `emoji` is used in logs and dashboards.

---

## 7. Things That Will Bite You

### Compaction will lose evaluation context
If the agent is mid-evaluation and compaction fires (unlikely with the settings above, but possible under load), the submission context and partial evaluation are gone. The memory flush will save whatever the agent wrote to daily notes, but the in-progress evaluation is lost.

**Mitigation:** Write the submission receipt to Supabase immediately at Step 1 (before any LLM work). If compaction fires mid-evaluation, the submission exists in the DB and can be re-processed. The agent won't know it was interrupted — it'll just process it again when it appears in the next batch.

### Skill loading is an LLM decision, not automatic
When the spec says "load `snapshot-interpretation` skill at Step 3," what actually happens is: the agent sees the skill metadata in its system prompt (name + description + path), decides to `read` the SKILL.md file, and then has the skill content in context. If the skill description doesn't clearly match the agent's current task, it might not load the skill.

**Mitigation:** Write skill descriptions as trigger phrases in the frontmatter. Example:
```yaml
---
description: >
  Market data interpretation for token evaluation. Load this skill when
  you need to analyze GeckoTerminal, BaseScan, or factory registry data
  for a scout submission evaluation (Step 3).
---
```

Also explicitly reference skill loading in AGENTS.md pipeline steps: "Load `snapshot-interpretation` skill" as a directive, not a suggestion.

### The factory-registry.json isn't auto-loaded
It's a config file in the workspace, but the agent needs to `read` it via a tool call. It's not injected into context automatically. At ~1KB for 6 factories, this is cheap to load, but the agent needs to know to do it.

**Mitigation:** In the `snapshot-interpretation` skill, include an explicit instruction: "First, read `config/factory-registry.json` to identify the token's factory."

### Group chat means MEMORY.md doesn't load
OpenClaw only loads MEMORY.md in private/DM sessions, never in group chats. Since the scout submission group is a group chat, the agent won't have access to MEMORY.md.

For this agent, that's actually fine — all persistent state is in Supabase, not in MEMORY.md. But if you later want the agent to have a "personality that evolves" or "learned preferences," those need to go in AGENTS.md or a memory file loaded via explicit tool call, not MEMORY.md.

### Multi-scout convergence detection needs timestamps
The spec says "organic vs coordinated" convergence analysis. For this to work, `scout_submissions` needs a `submitted_at` timestamp, and the agent needs to query recent submissions for the same CA. If 5 scouts submit the same CA within 15 minutes, that's likely coordinated. If they submit over 48 hours, that's likely organic.

For GP test with 10 known people, you can skip the coordinated detection (they're all aligned). Flag it for S1.

---

## 8. GP Test Success Criteria (from our perspective)

The GP test validates three things:

1. **Does the evaluation pipeline produce defensible scores?** Read the agent's reasoning for each SIGNAL/TRADE. Does the 5-dimension breakdown make sense? Is founder research actually happening? Are the modifiers applying correctly?

2. **Is the cost/latency acceptable?** Track tokens per evaluation and wall-clock time. Target: <$0.05 per full evaluation (Steps 1-6), <5 minutes end-to-end. These will inform model tiering decisions for S1.

3. **Does the TG flow feel right?** Are the reply messages appropriate? Is the team review format useful? Does the daily digest contain actionable info?

If all three are yes, you have a validated evaluation engine and can confidently add the X layer, public tiers, and gamification for S1.

---

*Notes compiled 2026-03-17. Revised SOUL.md and AGENTS.md attached separately.*
