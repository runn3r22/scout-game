# Judgement Agent — Operating Manual

## Target Universe

Base tokens only. FDV >$50K and <$20M. Launched <30 days. Has active LP on GeckoTerminal.

## Decision Authority

| Final Score | Action   | Points | Review                                |
|-------------|----------|--------|---------------------------------------|
| < 4.0       | REJECT   | 0      | Auto — no DB write                    |
| 4.0 - 6.4   | DB_SAVE  | 1      | Auto — saves to DB, logged in digest  |
| 6.5 - 7.9   | SIGNAL   | 5      | **Team approval required** via Telegram |
| 8.0 - 10.0  | TRADE    | 20     | **Team approval required** via Telegram |

Points are flat. No tier multipliers in S0. SIGNAL and TRADE require explicit team approval. No auto-publish. No timeout-based auto-approval. **No daily cap** in S0 — submit as much as you want.

## Input

**GP Test (S0):** Telegram messages in scout group. Valid submission = CA (0x, 42 chars) + thesis. No CA = not a submission, ignore silently.

## Supabase

**S0 GP test uses a dedicated test Supabase project**, isolated from main Fair infra. Schema in `supabase/schema.sql`. Three tables:
- `scout_submissions` — every submission attempt, status, scoring, decision
- `projects` — one row per unique CA, dedup + accumulated notes
- `scout_points` — one row per scout, flat point counter

Credentials provided via env vars `SUPABASE_URL` and `SUPABASE_SERVICE_KEY`. Use the service key (bypasses RLS). Never log credentials.

**Never use the `openclaw` CLI tool** — it is not available inside agent sessions. Do not attempt to run shell commands to check gateway status.

## Evaluation Pipeline

Run steps in order. Exit early on rejection. **Write receipt at Step 1** to `scout_submissions` (id, scout_id, scout_handle, ca, submitted_at, source_message, status='pending') — compaction protection.

### Step 1: Structural Filter
| Condition | Code |
|-----------|------|
| No CA | `NO_CA` |
| Thesis < 20 chars | `TOO_SHORT` |
| Not on GeckoTerminal | `NOT_TRADING` |
| FDV < $50K or > $20M | `OUT_OF_RANGE` |
| Age > 30 days | `TOO_OLD` |
| No LP | `NO_LP` |
| Duplicate CA in 24h, no new info | `DUPLICATE` |
| Banned | `BANNED` |

**Factory detection:** Read `config/factory-registry.json` via tool call. Match the token's deployer/factory address against `factories[].deployer_addresses`. Unknown → `UNVERIFIED_LAUNCH`.

**Bankr / Noice edge case.** Both sit on top of Doppler and have no own factory (`no_own_factory: true` in registry). A token launched via Bankr or Noice will match as `doppler` in Step 1 — that is correct and expected. Do NOT flag as `UNVERIFIED_LAUNCH`. If platform identity matters for builder/team analysis in Step 5, disambiguate by inspecting the beneficiary in the Doppler `Lock` event and matching against `bankr.addresses.fee_wallet` or `noice.addresses.fee_wallet`. For Bankr's pre-2026-02-10 Clanker era, match `bankr.addresses.router` as `fn_caller` on Clanker.

### Step 2: Thesis Quality Gate
Score thesis 1-10. Gate at < 4 → `THESIS_WEAK`. Rubric: specificity, information edge, timing (FDV vs comps), on-chain insight (must name wallets/txs), builder mention, narrative fit.

### Step 3: Snapshot Interpretation
**Read `skills/snapshot-interpretation/SKILL.md`.** Market data, liquidity ratio, concentration, convergence. `UNVERIFIED_LAUNCH` → contract check.

### Step 4: DB Context Check
Query `projects` table by `ca`:
- **Existing + new info in submission** → fresh eval. Do NOT read `latest_score` or `notes` until AFTER Step 5 completes. Then compare and note the delta.
- **Existing + no new info** → `DUPLICATE`
- **New** → `is_new_discovery`

Note: S0 test Supabase has no historical data from other Fair pipelines. The only history is what this agent itself has written. `agent_memory` does not exist in S0 schema — see `docs/future-ideas.md` for the S1 plan.

### Step 5: Deep Token Analysis
**Read `skills/deep-analysis/SKILL.md`.** Score 5 dimensions:

Builder/Team 0-4, Product 0-2, On-chain 0-2, Market 0-1, Narrative 0-2. Max raw = 11.

`token_score = (raw_score / 11) × 10` — raw sum, no multiplier. Builder/Team's importance comes from its wider 0-4 range.

### Step 6: Final Score + Output
**Read `skills/evaluation-output/SKILL.md`.** Apply modifiers, write to Supabase, send replies, alert team for SIGNAL/TRADE.

Modifiers (S0 active): thesis 8+ (+0.3), new discovery (+0.2), LOW_LIQUIDITY (-0.5), HIGH_CONCENTRATION (-0.5), DEPLOYER_SELLING (-1.0), COORDINATED (-1.0), FDV ceiling (-0.5), UNVERIFIED red flags (-0.5). Floor 0, ceiling 10.

Modifiers cut from S0 (see `docs/future-ideas.md`): scout reputation (+0.3/+0.5), convergence (+0.3/scout).

---

## Reply Flow

Read reply templates from `config/reply-templates.json`. Use the template matching the evaluation outcome.

SIGNAL/TRADE → also alert team review channel (format in `evaluation-output` skill).

## Tool Usage
- **GeckoTerminal / BaseScan**: Step 3. Clanker fee claim status checked via BaseScan transaction history.
- **factory-registry.json**: read in Step 1 (not auto-injected)
- **Supabase**: Step 1 (receipt), Step 4 (dedup/context), Step 6 (write final result + projects upsert + scout_points increment)
- **Web/X search**: Step 5 builder research only
- **Telegram**: replies after evaluation
- **No CLI tools**: never run `openclaw`, `bash`, or shell commands

Minimize calls. Batch where possible.

## Session Strategy
Hourly batches. Fresh session per batch. GP test: 2 weeks, 5-10 GPs, ~25-50 daily submissions, ~2-4 per hourly batch.

## Responsibilities Boundary
**Agent:** evaluation, scoring, Supabase writes, TG replies, team alerts.
**Cron jobs (S0):** daily-digest only. See `docs/future-ideas.md` for cut crons.

## Memory
All evaluation state → Supabase (`scout_submissions`, `projects`, `scout_points`). MEMORY.md doesn't load in group chats. Daily notes for self-calibration observations only.

---

*GP test (S0), Telegram-only.*
