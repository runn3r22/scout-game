---
name: evaluation-output
description: >
  Output formatting for scout evaluations. Load this skill when you need
  to write evaluation results to Supabase, format the team review message,
  or calculate scout points (Step 6 output).
user-invocable: false
---

# Evaluation Output (Step 6 Output)

After calculating the final score, write to Supabase, send replies, alert the team if needed.

S0 GP test scope. No tier multipliers, no daily cap, no signal performance tracking, no retroactive upgrade. See `docs/future-ideas.md` for what was cut.

---

## Output JSON Schema

Every evaluation produces this internal shape (mapped onto Supabase columns below):

```json
{
  "submission_id": "uuid",
  "evaluated_at": "ISO 8601",

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

  "snapshot": {
    "fdv_usd": 200000,
    "liquidity_usd": 24000,
    "liquidity_ratio": 0.12,
    "volume_24h_usd": 85000,
    "holders": 412,
    "age_days": 3
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
      { "reason": "high thesis quality (8+)", "delta": 0.3 },
      { "reason": "new discovery", "delta": 0.2 }
    ],
    "final_score": 8.7,
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
    "intel_summary": "2-3 sentence briefing for projects.notes"
  },

  "scout_output": {
    "points_awarded": 20
  },

  "signal_brief": {
    "ticker": "TOKEN",
    "one_line_thesis": "AI inference marketplace with working product, strong team",
    "key_insight": "team previously built protocol with $40M TVL, smart money accumulating",
    "builder_summary": "2-3 sentence builder/team profile",
    "fdv_at_signal": 200000,
    "liquidity_ratio": 0.12
  },

  "flags": [],
  "reasoning": "3-5 sentence explanation"
}
```

---

## Supabase Writes

Three writes per completed evaluation. Run them in this order.

### 1. UPDATE `scout_submissions` (the row created in Step 1)

```
UPDATE scout_submissions SET
  status            = 'done',
  evaluated_at      = now(),
  factory           = <factory>,
  ticker            = <ticker>,
  snapshot_json     = <snapshot blob>,
  thesis_score      = <0-10>,
  token_score       = <0-10>,
  final_score       = <0-10>,
  modifiers_json    = <modifiers list>,
  action            = <REJECT|DB_SAVE|SIGNAL|TRADE>,
  reasoning         = <text>,
  points_awarded    = <0|1|5|20>,
  reject_code       = <NULL or code>
WHERE id = <submission_id>
```

For pure structural rejects (Step 1 fail), only set: status='done', reject_code, reasoning. Skip the rest.

### 2. UPSERT `projects` (skip on REJECT)

```
INSERT INTO projects (ca, ticker, factory, first_seen_at, first_scout_id,
                      first_submission_id, last_seen_at, submission_count,
                      latest_action, latest_score, latest_evaluated_at, notes, notes_updated_at)
VALUES (...)
ON CONFLICT (ca) DO UPDATE SET
  ticker              = EXCLUDED.ticker,
  factory             = EXCLUDED.factory,
  last_seen_at        = now(),
  submission_count    = projects.submission_count + 1,
  latest_action       = EXCLUDED.latest_action,
  latest_score        = EXCLUDED.latest_score,
  latest_evaluated_at = now(),
  notes               = projects.notes || E'\n\n[' || to_char(now(), 'YYYY-MM-DD HH24:MI') || '] ' || EXCLUDED.notes,
  notes_updated_at    = now()
```

`notes` accumulates: each DB_SAVE+ appends a timestamped intel summary. Read `notes` in Step 4 of the next submission for the same CA.

### 3. UPSERT `scout_points` (skip on REJECT — but still increment submission_count)

```
INSERT INTO scout_points (scout_id, scout_handle, total_points, submission_count,
                          accepted_count, signal_count, trade_count,
                          first_submission_at, last_submission_at)
VALUES (...)
ON CONFLICT (scout_id) DO UPDATE SET
  scout_handle       = EXCLUDED.scout_handle,
  total_points       = scout_points.total_points + EXCLUDED.total_points,
  submission_count   = scout_points.submission_count + 1,
  accepted_count     = scout_points.accepted_count + (CASE WHEN <not REJECT> THEN 1 ELSE 0 END),
  signal_count       = scout_points.signal_count + (CASE WHEN <SIGNAL or TRADE> THEN 1 ELSE 0 END),
  trade_count        = scout_points.trade_count + (CASE WHEN <TRADE> THEN 1 ELSE 0 END),
  last_submission_at = now()
```

For REJECT: still upsert with `total_points = 0`, increment `submission_count` only.

---

## Points Calculation

Flat. Per submission:

| Action   | Points |
|----------|--------|
| REJECT   | 0      |
| DB_SAVE  | 1      |
| SIGNAL   | 5      |
| TRADE    | 20     |

No tier multipliers. No daily cap. No first-submitter bonus. No convergence bonus. No retroactive upgrade. (See `docs/future-ideas.md` for what was cut.)

---

## Telegram Replies

Read templates from `config/reply-templates.json`. Use the template matching the outcome. Reply to the original submission message_id in the scout group.

## Team Review Message (SIGNAL / TRADE only)

When action = SIGNAL or TRADE, format and send to team review channel:

```
⚖️ SIGNAL — $TOKEN
Score: 7.3 (thesis: 7, token: 6.8)
Action: SIGNAL (5 pts)
Scout: @handle
FDV: $450K | Liq: $85K | Liq ratio: 19% | Age: 3d
Factory: Clanker (fees claimed)
Builder: [summary]
Key: [one-line insight]
On-chain: [notable on-chain signals]
Flags: none

APPROVE / EDIT / KILL
```

Team responds inline. No timeout — nothing auto-publishes. DB_SAVEs appear in daily digest only (no immediate alert).

---

## Memory

All evaluation state lives in Supabase. Do NOT use MEMORY.md for evaluation results — it doesn't load in group chats. Daily notes (`memory/YYYY-MM-DD.md`) are only for self-calibration observations across batches, not per-submission state.
