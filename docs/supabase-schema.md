# Supabase Schema — Scout Game

> Field spec for Luc. Shared DB with Farcaster pipeline.
> Existing tables (`projects`, `agent_memory`) may need new columns.

---

## scout_submissions (NEW)

Written at Step 1 (receipt) and updated after evaluation.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK, auto-generated |
| scout_handle | text | TG handle for GP test, X handle for S1 |
| scout_tier | text | T1/T2/T3/GP |
| ca | text | 0x-prefixed, 42 chars |
| ticker | text | Resolved from GeckoTerminal |
| chain | text | Default: "base" |
| thesis_text | text | Raw scout thesis |
| thesis_score | int | 1-10, from Step 2 |
| token_score | float | 0-10, normalized from 5 dimensions |
| final_score | float | 0-10, after modifiers |
| action | text | REJECT / DB_SAVE / SIGNAL / TRADE |
| reject_reason | text | Null if not rejected |
| base_points | int | 0 / 1 / 5 / 20 |
| weighted_points | float | base_points × tier_multiplier |
| is_new_discovery | bool | First time this CA appears |
| is_first_submitter | bool | First scout to submit this CA |
| token_factory | text | clanker/bankr/flaunch/virtuals/noice/creator_bid/unknown |
| flags | text[] | Array: LOW_LIQUIDITY, HIGH_CONCENTRATION, etc. |
| evaluation_json | jsonb | Full output JSON from agent |
| snapshot_fdv_usd | float | FDV at evaluation time |
| snapshot_liquidity_usd | float | Pool liquidity at evaluation time |
| submitted_at | timestamptz | When scout sent the message |
| evaluated_at | timestamptz | When evaluation completed |
| status | text | pending / evaluated / error |

**Indexes:** ca, scout_handle, submitted_at, action

---

## projects (EXISTING — may need columns)

Check if these columns exist. Judgement Agent reads/writes here for DB_SAVE+.

| Column | Type | Notes |
|--------|------|-------|
| ca | text | Contract address (should exist) |
| ticker | text | |
| chain | text | |
| source_type | text | "scout" / "farcaster" / etc. |
| latest_score | float | Most recent final_score |
| latest_action | text | Most recent action |
| latest_reasoning | text | Agent's 3-5 sentence explanation |
| worth_watching | bool | Watch flag |
| watch_conditions | text | Specific revisit conditions |
| first_seen_at | timestamptz | |
| last_evaluated_at | timestamptz | |

---

## agent_memory (EXISTING — may need columns)

Intel summaries written by the agent for DB_SAVE+.

| Column | Type | Notes |
|--------|------|-------|
| ca | text | Links to project |
| intel_summary | text | 2-3 sentence briefing note |
| source_type | text | "scout" |
| scout_handles | text[] | Who contributed intel |
| created_at | timestamptz | |

---

## token_performance (NEW)

Written by daily FDV snapshot cron. Tracks price performance for scout reputation.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK |
| ca | text | |
| signal_fdv_usd | float | FDV when SIGNAL/TRADE was issued |
| checkpoint_fdv_usd | float | FDV at last checkpoint |
| current_fdv_usd | float | Latest FDV |
| pct_change_from_signal | float | % change from original signal |
| pct_change_from_checkpoint | float | % change from last checkpoint |
| signal_points | int | Points earned at this checkpoint |
| checkpoint_day | int | 1 / 7 / 14 |
| checked_at | timestamptz | |
| submission_id | uuid | FK to scout_submissions |

---

## scout_points_daily (NEW — optional for GP test)

Written by daily points settlement cron.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK |
| scout_handle | text | |
| date | date | |
| total_weighted_points | float | Sum for the day (capped at 50) |
| submissions_count | int | |
| acceptance_rate | float | % that passed Thesis Quality Gate |
| retroactive_upgrades | int | Count of retro upgrades applied |

---

*Schema spec — hand to Luc for review against existing Farcaster tables.*
