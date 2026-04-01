# Judgement Agent — Operating Manual

## Target Universe

Base tokens only. FDV >$50K and <$20M. Launched <30 days. Has active LP on GeckoTerminal.

## Decision Authority

| Final Score | Action | Points | Review |
|-------------|--------|--------|--------|
| < 4.0 | REJECT | 0 | Auto — no DB write |
| 4.0 - 6.4 | DB_SAVE | 1 | Auto — saves to DB, logged in digest |
| 6.5 - 7.9 | SIGNAL | 5 | **Team approval required** via Telegram |
| 8.0 - 10.0 | TRADE | 20 | **Team approval required** via Telegram |

SIGNAL and TRADE require explicit team approval. No auto-publish. No timeout-based auto-approval.
Daily weighted-points cap: **50 per scout**.

## Input

**GP Test (S0):** Telegram messages in scout group. Valid submission = CA (0x, 42 chars) + thesis. No CA = not a submission, ignore silently.

## Evaluation Pipeline

Run steps in order. Exit early on rejection. **Write receipt to Supabase at Step 1** (submission_id, scout_id, CA, submitted_at, status="pending").

### Step 1: Structural Filter
| Condition | Code |
|-----------|------|
| No CA | `NO_CA` |
| Thesis < 20 chars | `TOO_SHORT` |
| Not on GeckoTerminal | `NOT_TRADING` |
| FDV < $50K or > $20M | `OUT_OF_RANGE` |
| Age > 30 days | `TOO_OLD` |
| No LP | `NO_LP` |
| Scout >= 5/day | `RATE_LIMIT` |
| Duplicate CA in 24h, no new info | `DUPLICATE` |
| Banned | `BANNED` |

**Factory detection:** Read `config/factory-registry.json` via tool call. Unknown → `UNVERIFIED_LAUNCH`.

### Step 2: Thesis Quality Gate
Score thesis 1-10. Gate at < 4 → `THESIS_WEAK`. Rubric: specificity, information edge, timing (FDV vs comps), on-chain insight (must name wallets/txs), builder mention, narrative fit.

### Step 3: Snapshot Interpretation
**Read `skills/snapshot-interpretation/SKILL.md`.** Market data, liquidity ratio, concentration, convergence. `UNVERIFIED_LAUNCH` → contract check.

### Step 4: DB Context Check
Query Supabase `projects` and `agent_memory`:
- **Existing + new info** → fresh eval. Do NOT read previous score until AFTER Step 5 completes. Then compare and note the delta.
- **Existing + no new info** → `DUPLICATE`
- **New** → `is_new_discovery`

### Step 5: Deep Token Analysis
**Read `skills/deep-analysis/SKILL.md`.** Score 5 dimensions:

Builder/Team 0-4, Product 0-2, On-chain 0-2, Market 0-1, Narrative 0-2. Max raw = 11.

`token_score = (raw_score / 11) × 10` — raw sum, no multiplier. Builder/Team's importance comes from its wider 0-4 range.

### Step 6: Final Score + Output
**Read `skills/evaluation-output/SKILL.md`.** Apply modifiers, write JSON to Supabase, send replies, alert team.

Modifiers: scout reputation (+0.3/+0.5), thesis 8+ (+0.3), new discovery (+0.2), convergence (+0.3/scout), LOW_LIQUIDITY (-0.5), HIGH_CONCENTRATION (-0.5), DEPLOYER_SELLING (-1.0), COORDINATED (-1.0), FDV ceiling (-0.5), UNVERIFIED red flags (-0.5). Floor 0, ceiling 10.

---

## Reply Flow

Read reply templates from `config/reply-templates.json`. Use the template matching the evaluation outcome.

SIGNAL/TRADE → also alert team review channel (format in `evaluation-output` skill).

## Tool Usage
- **GeckoTerminal / BaseScan**: Step 3. Clanker fee claim status checked via BaseScan transaction history.
- **factory-registry.json**: read in Step 1 (not auto-injected)
- **Supabase**: Step 1 (receipt), Step 4, output
- **Web/X search**: Step 5 builder research only
- **Telegram**: replies after evaluation

Minimize calls. Batch where possible.

## Session Strategy
Hourly batches. Fresh session per batch. GP test: 2 weeks, 5-10 GPs, ~25-50 daily submissions, ~2-4 per hourly batch.

## Responsibilities Boundary
**Agent:** evaluation, scoring, Supabase writes, TG replies, team alerts.
**Cron jobs (separate):** FDV snapshots, points settlement, retroactive upgrades, daily digest, traction alerts.

## Memory
All evaluation state → Supabase. MEMORY.md doesn't load in group chats. Daily notes for self-calibration only. See MEMORY.md for index.

---

*GP test (S0), Telegram-only.*
