---
name: snapshot-interpretation
description: >
  Market data interpretation for token evaluation. Load this skill when
  you need to analyze GeckoTerminal, BaseScan, or factory registry data
  for a scout submission evaluation (Step 3).
user-invocable: false
---

# Snapshot Interpretation (Step 3)

**First:** Read `config/factory-registry.json` to identify the token's factory (if not already done in Step 1).

Then read GeckoTerminal snapshot and BaseScan data. Build a picture of the token's current market state. This informs your deep analysis — it is not a scoring step on its own, and no single metric is an automatic reject.

---

## Liquidity — `pool_liquidity_usd` and `liquidity_ratio`

`pool_liquidity_usd` is the full USD value of the liquidity pool (ETH side + token side combined).

| Range | Assessment |
|-------|-----------|
| < $10K | Extreme rug risk. Flag `LOW_LIQUIDITY`, note in analysis. |
| $10K - $50K | Thin but tradeable for small positions. |
| $50K - $200K | Normal for early micro-cap. |
| > $200K | Healthy for this stage. |

Do NOT read only the ETH/WETH side — GeckoTerminal reports pool total.

### Liquidity Ratio — `liquidity_ratio` (`pool_liquidity_usd / fdv_usd`)

FDV alone is unreliable on thin liquidity. The liquidity ratio tells you how much of that FDV is actually realizable.

| Ratio | Interpretation |
|-------|---------------|
| < 2% | **Untradeable at size.** FDV is meaningless — any real sell pressure collapses the price. Extreme caution. |
| 2% - 5% | Thin. Tradeable for small positions only. Price impact on $5K+ trades will be significant. |
| 5% - 15% | Normal for early Base tokens. Reasonable for our position sizes. |
| > 15% | Healthy. Strong LP support relative to market cap. |

**Key insight:** A token with $500K FDV and $5K liquidity (1% ratio) is fundamentally different from $500K FDV and $75K liquidity (15% ratio). Always report both FDV and liquidity ratio in reasoning.

---

## Age — `age_days`

- Tokens under 1 day old are **common** in our flow — do NOT flag this automatically.
- Very fresh tokens have higher uncertainty (no holder history, no volume baseline).
- Note the age in your reasoning. Treat it as context, not a penalty.
- Age < 1 day + no verifiable founder = much harder to score well on Dimension 1.

---

## Holder Concentration — `top10_holders_pct` (from BaseScan)

LP tokens must be excluded — LP holders are providing liquidity, not concentrating supply.

- top10 > 70% excluding LP: flag `HIGH_CONCENTRATION`, note in market structure
- `deployer_wallet_balance_pct` > 15%: flag `DEPLOYER_HOLDING_LARGE`, check sell activity
- Deployer at 0% or near 0%: check whether tokens were distributed (good) or dumped (bad)

---

## Volume

- High volume relative to FDV (e.g., 600K volume on 150K FDV) is **normal and often bullish** for micro-caps — it means real trading interest.
- Do NOT flag high volume as suspicious by default.
- Flag volume only if the pattern is anomalous:
  - Perfectly alternating buy/sell blocks with no price movement = **wash trading signature**
  - Volume spike with price pinned flat (no movement despite large flow)

---

## Timing — How to Read Price Change

- Do NOT use `price_change_24h_pct` as a timing disqualifier. A +600% move does not mean "too late."
- **Correct timing assessment:** compare current FDV against comparable projects' FDV trajectory.

| Situation | Assessment |
|-----------|-----------|
| Token at $150K FDV, up 600% today, comparables at $2M-$10M FDV | May still be early |
| Token at $1.5M FDV, up 5% today, comparables at $800K | May already be expensive |

The question is always: **what is the realistic FDV ceiling vs where we are now?**

Flag timing concern only if current FDV is already within 30% of the comparable ceiling.

---

## Token Factory — `snapshot.token_factory` + `snapshot.factory_fees_claimed`

Token factory is detected via `factory-registry.json` config file. Known factories: Clanker, Bankr, Doppler, Noice, Flaunch, Virtuals. New launchpads are added by updating the config — no code changes needed.

If `token_factory` matches a known factory: this is a known Base launch mechanic. Not inherently bullish or bearish — plenty of legitimate tokens launch this way, and plenty of bots do too.

### Clanker tokens — check `factory_fees_claimed`:

| State | Assessment |
|-------|-----------|
| Fees claimed (`true`) | Creator is actively engaging with and monetizing the project. Green signal — bots and abandoned launches don't claim fees. Note in Dimension 1. |
| Fees unclaimed + `age_days` >= 7 | Possible bot launch, abandoned project, or absent founder. Flag `CLANKER_FEES_UNCLAIMED`. Reduce Dimension 1 by 0.5 unless scout provides direct evidence founder is active. |
| Fees unclaimed + `age_days` < 1 | Too early to be meaningful. Ignore. Don't penalize. |

### Doppler / Bankr / Noice tokens
No fee-claim mechanism. Treat as context only. Bankr and Noice match as `doppler` in detection (they have no own factory) — that is correct and NOT a red flag. If you need to know which downstream platform launched it for builder analysis, inspect Lock event beneficiary against fee_wallet addresses in `factory-registry.json`.

### `token_factory = "unknown"` → `UNVERIFIED_LAUNCH`

When the deployer address doesn't match any known factory in `factory-registry.json`, flag `UNVERIFIED_LAUNCH` and perform basic contract analysis:

**Check for red flags:**
- **Mint functions:** Can the owner mint new tokens? Uncapped mint = rug risk.
- **Owner privileges:** Pausable? Blacklist functions? Transfer restrictions?
- **Proxy upgradeability:** Is the contract upgradeable? Owner can swap logic at any time.
- **Hidden fees:** Transfer tax functions, dynamic fee adjustments.
- **Renounced ownership:** Has the contract been renounced? Renounced + no mint = safer.

**Assessment:**
- No red flags found → note `UNVERIFIED_LAUNCH` in reasoning, no penalty.
- Red flags found → flag specific issues, apply -0.5 modifier via `UNVERIFIED_LAUNCH + contract red flags`.
- Cannot read contract (unverified on BaseScan) → note as risk factor, score conservatively.

**Important:** ~90% of tokens in our flow come from known factories with locked LP. This check only applies to the ~10% of custom-deployed tokens.

---

*Multi-scout convergence and coordinated-push detection are cut from S0 (closed group of 10 known GPs makes both signals statistically meaningless). See `docs/future-ideas.md` → S0 Simplification Log for restore instructions.*
