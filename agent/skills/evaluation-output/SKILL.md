---
name: evaluation-output
description: >
  Output formatting for scout evaluations. Load this skill when you need
  to write the evaluation JSON to Supabase, format the team review message,
  or calculate scout points (Step 6 output).
user-invocable: false
---

# Evaluation Output (Step 6 Output)

After calculating the final score, produce the output JSON, write to Supabase, send replies, and alert the team if needed.

---

## Output JSON Schema

Every evaluation produces this exact schema (written to Supabase `scout_submissions`):

```json
{
  "submission_id": "string",
  "evaluated_at": "ISO 8601",
  "snapshot_fdv_usd": 200000,

  "extracted": {
    "ca": "0x...",
    "ticker": "TOKEN",
    "chain": "base",
    "scout_thesis": "1-2 sentence summary"
  },

  "filter_result": {
    "passed_structural": true,
    "structural_reject_reason": null,
    "token_factory": "clanker",
    "unverified_launch": false,
    "thesis_score": 7,
    "thesis_reject": false
  },

  "token_analysis": {
    "builder_team_score": 3,
    "product_score": 1,
    "onchain_score": 2,
    "market_score": 1,
    "narrative_score": 2,
    "raw_score": 9,
    "normalized_score": 8.2,
    "modifiers": [
      { "reason": "scout track record (score: 6)", "delta": 0.5 },
      { "reason": "high thesis quality", "delta": 0.3 }
    ],
    "final_score": 9.0,
    "scenarios": [
      { "case": "bull", "probability": 0.35, "description": "..." },
      { "case": "base", "probability": 0.45, "description": "..." },
      { "case": "bear", "probability": 0.20, "description": "..." }
    ],
    "kill_conditions": ["dev goes quiet >3 days", "liquidity drops below $50K"]
  },

  "decision": {
    "action": "TRADE",
    "reject_reason": null,
    "requires_team_approval": true,
    "is_new_discovery": true,
    "adds_new_info": true,
    "new_info_summary": "what's new",
    "worth_watching": true,
    "watch_conditions": "revisit if TVL crosses $5M"
  },

  "scout_output": {
    "base_points": 20,
    "weighted_points": 100.0,
    "tier_multiplier": 5.0,
    "daily_points_remaining": 0,
    "is_first_submitter": true,
    "first_submitter_bonus": 1.5
  },

  "db_write": {
    "to_projects": true,
    "to_agent_memory": true,
    "intel_summary": "2-3 sentence briefing note",
    "source_type": "scout"
  },

  "signal_brief": {
    "ticker": "TOKEN",
    "one_line_thesis": "AI inference marketplace with working product, strong team",
    "key_insight": "team previously built protocol with $40M TVL, smart money accumulating",
    "builder_summary": "2-3 sentence builder/team profile for comms agent",
    "scout_handles": ["@scout1", "@scout2"],
    "fdv_at_signal": 200000,
    "liquidity_ratio": 0.12
  },

  "flags": [],
  "reasoning": "3-5 sentence explanation"
}
```

---

## Team Review Message (Telegram)

When action = SIGNAL or TRADE, format and send to team review channel:

```
⚖️ SIGNAL — $TOKEN
Score: 7.3 (thesis: 7, token: 6.8)
Action: SIGNAL (5 pts)
Scout: @handle (GP)
FDV: $450K | Liq: $85K | Liq ratio: 19% | Age: 3d
Factory: Clanker (fees claimed)
Builder: [summary]
Key: [one-line insight]
On-chain: [notable on-chain signals]
Flags: none
Scouts to credit: @scout1 (first), @scout2

APPROVE / EDIT / KILL
```

Team responds inline. No timeout — nothing auto-publishes.

DB_SAVEs appear in daily digest only (no immediate team alert).

---

## Points Calculation

Base points: REJECT 0 | DB_SAVE 1 | SIGNAL 5 | TRADE 20

GP test: all scouts are GP tier (5.0x). `weighted_points = base_points × 5.0`

Daily cap: 50 weighted points per scout per day. If cap exceeded, evaluation still runs but points capped at remaining allowance.

Multi-scout credit: all organic scouts get points for highest action. First submitter gets 1.5x base points before multiplier.

Retroactive upgrade: DB_SAVE → escalated within 14 days → auto-upgrade points (action already team-approved). First submitter 1.5x. Logged in daily digest.

---

## Signal Performance Tracking

Checked at **1 day, 7 days, 14 days** from signal.

- Token up >100% from signal FDV: **+1 point**
- Each additional 100% gain: **+1 point** (200% = +2, 300% = +3)
- Token down >50%: **-2 points**
- Calculate from: (a) last checkpoint AND (b) original signal FDV

Cumulative `signal_score` feeds into Step 6 modifier (+0.3 or +0.5). Score < 0 = no modifier.

Trade performance: only evaluated on exit. 70% win rate target.

---

## Memory Write (DB_SAVE+)

Write `intel_summary` to Supabase `agent_memory`:

> "YOLO Finance (DeFi yield optimizer on Base). Team: @yolodev (prior $8M TVL project) + @designer (ex-Aave). Clanker launch, fees claimed. 12 days old, $2.1M FDV, $380K liq (18% ratio). Scout claimed whale accumulation — confirmed: 3 smart money wallets buying. Working product, 340 users. AI+DeFi narrative fit. Revisit if TVL crosses $5M. [2026-03-16]"

**Do NOT use MEMORY.md** — it doesn't load in group chats. All state → Supabase.

OpenClaw daily notes (`memory/YYYY-MM-DD.md`) — only for self-calibration observations.
