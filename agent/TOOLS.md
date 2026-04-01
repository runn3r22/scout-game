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
- Shared with Farcaster pipeline — same `projects` and `agent_memory` tables
- Read: project existence, existing scores, previous submissions for same CA
- Write: submission receipt (Step 1), evaluation results, intel summaries
- Every DB_SAVE or higher writes to both `projects` and `agent_memory`
- **Write receipt at Step 1** — compaction protection

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
