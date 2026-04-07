# Judgement Agent — Tools & API Guidance

## GeckoTerminal API
- Source for all market data: price, FDV, mcap, liquidity, volume, price changes, buy/sell ratios
- `pool_liquidity_usd` = total both sides (ETH + token), not just ETH/WETH
- Calculate `liquidity_ratio = pool_liquidity_usd / fdv_usd` — key metric for realizable value
- Snapshot pulled at evaluation time (±60 sec from submission)
- If snapshot returns null → token is not trading → structural reject

## BaseScan (Base Block Explorer)
- Source for on-chain holder data: `top10_holders_pct`, `deployer_wallet_balance_pct`
- LP token holders are **excluded** from concentration calc (LP = distributed, not concentrated)
- Use for deployer wallet activity analysis (selling, holding, adding liquidity)
- Use for deployer prior contracts (other tokens deployed by same wallet)
- For `UNVERIFIED_LAUNCH` tokens: check contract source for mint functions, owner privileges, proxy patterns

## Supabase

S0 GP test uses an isolated test Supabase project (separate from main Fair infra). Schema in `supabase/schema.sql`. Credentials via env vars `SUPABASE_URL` and `SUPABASE_SERVICE_KEY`.

Three tables:

**`scout_submissions`** — every submission attempt
- Step 1 INSERT: id, scout_id, scout_handle, source_chat_id, source_message_id, source_message, ca, submitted_at, status='pending'
- Step 3 UPDATE: snapshot_json
- Step 6 UPDATE: thesis_score, token_score, final_score, modifiers_json, action, reasoning, points_awarded, evaluated_at, status='done'
- On reject: status='done', reject_code='...'
- **Always write receipt at Step 1** — compaction protection. source_chat_id + source_message_id are required at Step 1 because Step 6 uses them to reply to the original message after potential compaction has dropped chat history from context.

**`projects`** — one row per unique CA
- Step 4 SELECT by ca: dedup + read existing notes
- Step 6 UPSERT: ca, ticker, factory, last_seen_at, latest_action, latest_score, submission_count++, append to notes (with timestamp)
- On first submission: also set first_seen_at, first_scout_id, first_submission_id

**`scout_points`** — one row per scout, flat counter
- Step 6 UPSERT: scout_id, scout_handle, total_points += points_awarded, submission_count++, accepted_count++ (if not REJECT), signal_count++ (if SIGNAL or TRADE), trade_count++ (if TRADE), last_submission_at

`agent_memory` does NOT exist in S0 schema — see `docs/future-ideas.md` for the S1 plan to integrate with main Fair Supabase.

## factory-registry.json
- Workspace config file at `config/factory-registry.json` — NOT auto-injected
- Must be explicitly read via tool call during Step 1
- Contains deployer addresses for known factories (Clanker, Bankr, Flaunch, Virtuals, Noice, Creator Bid)

## Telegram Bot API
- **Scout submission group:** reply to scout with evaluation result
- **Team review channel:** send SIGNAL/TRADE alerts with APPROVE/EDIT/KILL actions
- No timeout on team review — nothing auto-publishes

## Web Search / X Search
- Builder/team research only — call during Step 5
- No pre-built builder database — research live every time
- If unverifiable, state explicitly and score conservatively

---

*X API integration deferred to S1 public launch. GP test is Telegram-only.*
