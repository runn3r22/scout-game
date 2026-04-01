# FAIR SCOUT GAME — Token Economics v4

---

## 0. Core Design

- DB save = agent learning. Signal = attention auction (whales push bags). Trade = the alpha.
- **Points system:** scouts earn points per action. Points accumulate daily and weekly.
  - Daily: points earned today → daily pool split proportionally by points
  - Weekly: cumulative points over the week → weekly pool split by leaderboard rank
- Unused daily pool rolls into weekly pool.
- **Multiple submitters on same project ALL get rewarded** (signal + trade). For DB saves, only new information not already in DB gets rewarded.
- Holdings affect signal weight (probability agent notices) AND point multiplier (more points per action).
- Static rewards model only. Ship fast, iterate after test.
- ⚠️ Agent evaluation time TBD — discuss on call

---

## 1. Parameters

| Parameter | Test (GP only) | Public |
|-----------|---------------|--------|
| Duration | 1 week | 2 weeks |
| Participants | 10 GPs | Broader (3 tiers) |
| Pool | 1% = 1B tokens | 1% = 1B tokens (increase if economics positive) |
| Multipliers | None (flat) | Tier-based |
| Min hold | 250M (GP) | 2M (Tier 1) |

### FDV Scenarios

| FDV | Price/token | 1B pool value |
|-----|-----------|--------------|
| $1.2M | $0.000012 | $12,000 |
| $2.4M | $0.000024 | $24,000 |
| $6M | $0.000060 | $60,000 |

---

## 2. Holding Weight: Priority + Reward

### How Holdings Affect the Pipeline

**Signal weight (probability of agent attention):** Holdings increase the WEIGHT of your submission — meaning agent is more likely to notice and process it. This is NOT a blocking queue. A Tier 1 scout who submits first still gets processed — but a GP's submission on the same project carries more weight in the agent's attention model. Think of it as signal strength, not queue position.

Both a small and large holder can submit the same project. Agent sees both. But the GP-weighted signal has higher probability of being evaluated deeply.

**Reward multiplier:** Higher tiers earn more tokens per accepted submission.

**Combined effect:** Whales' signals carry more weight AND earn bigger rewards. Smaller scouts can absolutely win — especially on obscure/early finds where they're the only submitter.

### Tier Structure (Public Phase)

| Tier | Min Hold | Entry at $1.2M | Entry at $2.4M | Entry at $6M | Signal Weight | Reward Mult |
|------|---------|---------------|---------------|-------------|--------------|------------|
| Tier 1 | 2M | $24 | $48 | $120 | Base | 1.0x |
| Tier 2 | 10M | $120 | $240 | $600 | Enhanced | 1.5x |
| Tier 3 | 50M | $600 | $1,200 | $3,000 | High | 3.0x |
| GP | 250M | $3,000 | $6,000 | $15,000 | Maximum | 5.0x |

Future idea: PNL Track Record (verified FOMO/Clicker/DEX) as additional multiplier — post-MVP.

**⚠️ TRANSPARENCY NOTE:** Signal weight mechanic must be clearly documented and visible to all participants. Scouts need to understand exactly how holdings affect their chances. Publish the formula, show examples. If this feels opaque or unfair, trust breaks immediately. Consider: public page/doc explaining "how signal weight works" with concrete examples per tier.

### Why This Attracts Whales

A GP-tier scout submitting a signal that leads to a trade earns 6x what a Tier 1 scout gets. Plus their submission is evaluated first — meaning they capture the discovery bonus on popular projects. For a whale already holding $FAIR, this is free alpha income on top of their position.

### Why Smaller Scouts Still Play

- Entry is $24. Low risk.
- If they earn rewards and HOLD, they climb tiers → better multiplier next season
- Obscure finds that whales miss still get rewarded at full base rate
- The system rewards QUALITY over SIZE — a Tier 1 scout with a trade-level signal earns more than a GP with a DB save

---

## 3. Points System & Reward Table

### How Points Work

1. Scout submits via Twitter tag → agent evaluates
2. If accepted: scout earns **base points** for the action type
3. Points are **multiplied by tier** → weighted points
4. **Daily:** all weighted points earned that day → daily pool (50%) split proportionally
5. **Weekly:** all weighted points earned that week → weekly pool (50%) split by leaderboard rank
6. Unused daily pool rolls into weekly pool
7. 1 point = 1 token when converting pool to payouts (proportional share)

### Points Per Action

| Agent Action | Base Points | Rationale |
|-------------|------------|-----------|
| Rejected | 0 | No value |
| Saved to DB (new info only) | 1 pt | Agent learned something |
| Signal Published | 5 pts | Agent published to feed |
| Trade Executed | 20 pts | Agent deployed capital |

### Points With Tier Multiplier

| Action | Tier 1 (1.0x) | Tier 2 (1.5x) | Tier 3 (3.0x) | GP (5.0x) |
|--------|-------------|-------------|-------------|---------|
| DB save | 1 pt | 1.5 pts | 3 pts | 5 pts |
| Signal | 5 pts | 7.5 pts | 15 pts | 25 pts |
| Trade | 20 pts | 30 pts | 60 pts | 100 pts |

### ⚠️ Reward Model Clarification: Proportional, Not Fixed

Rewards are NOT fixed token amounts per action. The pool is split proportionally by weighted points.

**How it actually works:**
- Daily pool (50% of season allocation ÷ days) is divided among all scouts proportional to their weighted points earned that day
- Weekly pool (50% + unused daily) is divided by leaderboard rank
- More scouts = each individual gets fewer tokens per point (dilution)
- Fewer scouts = each individual gets more tokens per point (concentration)

**Pool cannot drain early.** The total payout per day is capped by the daily pool allocation. High activity doesn't overspend — it dilutes per-scout rewards.

**Illustrative earnings (NOT fixed rates):** The per-tier earnings estimates in Sections 4-5 assume specific activity levels and scout counts. Actual payouts depend on total weighted points generated that day/week. These estimates are for modeling purposes only.

---

## 4. Test Season (1 week, 10 GPs, 1B pool, flat rewards)

### Expected Volume

| Action | Per week |
|--------|---------|
| DB saves | ~100 |
| Signals | 7-10 (likely less — duplicate projects) |
| Trades | ~3 |
| Rejected | ~80-120 |

### Pool Spend (Illustrative — Proportional Model)

Under proportional model, these are not actual spends but estimated point-weighted distributions assuming these activity levels:

| Action | Count | Weighted pts generated | Approx share of daily pool |
|--------|-------|----------------------|--------------------------|
| DB saves | 100 | 100 pts | ~16% |
| Signals | 8 | 40 pts | ~6% |
| Trades | 3 | 60 pts | ~10% |
| **Total weighted pts** | | **200 pts** | |

Daily pool (50%): 500M tokens ÷ 7 days = ~71.4M/day. Split proportionally among all scouts by their share of total weighted points that day.

### GP Earnings (test, no multipliers)

| GP Profile | Actions | Daily tokens | Weekly bonus (est.) | Total | $ at $1.2M |
|-----------|---------|-------------|-------------------|-------|-----------|
| Top | 15 DB + 3 Sig + 2 Trade | 72.5M | 209M (25%) | 281M | $3,370 |
| Good | 12 DB + 1 Sig + 1 Trade | 36M | 125M (15%) | 161M | $1,930 |
| Average | 8 DB | 4M | 84M (10%) | 88M | $1,050 |
| Low | 3 DB | 1.5M | 40M (5%) | 41.5M | $498 |

### Sell Pressure (Test)

| Dump % | Tokens | $ | vs FDV |
|--------|--------|---|--------|
| 30% (realistic) | 255M | $3,060 | 0.26% |
| 10% (likely — GPs are aligned) | 85M | $1,020 | 0.09% |

Negligible.

---

## 5. Public Season (2 weeks, 1B pool, 3 tiers)

### Volume Estimates

Multiple scouts can submit the same project. If agent acts on it (signal or trade), ALL submitters get rewarded. For DB saves, only new info not already stored gets rewarded.

This means signals/trades generate MORE total points (5 submitters × signal points each), which is good — it validates conviction across scouts.

| Action | 50 scouts | 100 scouts | 200 scouts |
|--------|----------|-----------|-----------|
| DB saves (unique new info) | 200 | 350 | 500 |
| Signals (unique projects) | 10-15 | 15-20 | 20-30 |
| Signal submitters total | 30-50 | 50-80 | 80-120 |
| Trades (unique projects) | 4-6 | 6-10 | 8-12 |
| Trade submitters total | 10-20 | 20-35 | 30-50 |
| Rejected | 500+ | 1,200+ | 2,500+ |

### Pool Distribution (2 weeks, 50 scouts, mixed tiers — Illustrative)

Assumption: 50% Tier 1, 25% Tier 2, 15% Tier 3, 10% GP.
Weighted avg multiplier: (0.5 × 1.0) + (0.25 × 1.5) + (0.15 × 3.0) + (0.1 × 5.0) = **1.82x**

Under proportional model, daily pool is always fully distributed among active scouts. More activity = more points = more dilution per point, but pool never overspends.

Daily pool: 500M ÷ 14 days = ~35.7M tokens/day. Split by weighted point share.

### Example: 5 Scouts Submit Same Project → Signal Published

One project, 5 submitters within an hour: 2 GPs, 1 Tier 3, 1 Tier 2, 1 Tier 1. First submitter was Tier 2.

Agent evaluates, publishes signal. ALL 5 get Signal points:

| Scout | Tier | Mult | Base pts | Weighted pts | Token reward | $ at $1.2M |
|-------|------|------|----------|-------------|-------------|-----------|
| GP #1 | GP | 5.0x | 5 | 25 | 25M | $300 |
| GP #2 | GP | 5.0x | 5 | 25 | 25M | $300 |
| Tier 3 | T3 | 3.0x | 5 | 15 | 15M | $180 |
| Tier 2 (first!) | T2 | 1.5x | 5 | 7.5 | 7.5M | $90 |
| Tier 1 | T1 | 1.0x | 5 | 5 | 5M | $60 |
| **Total** | | | | **77.5** | **77.5M** | **$930** |

Everyone gets rewarded. Tier 2 submitted first but GPs earn most per submission due to multiplier. Discovery bonus (post-MVP) would give Tier 2 an extra bonus for being first.

### Public Phase: Estimated Earnings Per Tier (2 weeks, at $1.2M FDV)

Assumptions: active scout submits 1-2 subs/day. Acceptance rates vary by quality.

**Tier 1 Scout (2M tokens, $24 entry, 1.0x)**

| Activity Level | Accepted Actions | Daily pts | Weekly pts | Daily $ | Weekly bonus | Total 2wks |
|---------------|-----------------|----------|-----------|---------|-------------|-----------|
| Casual (1/day) | 5 DB, 0-1 Sig | ~5-10 | ~35-70 | $3-5/day | $50-100 | **~$90-170** |
| Active (2/day) | 10 DB, 1-2 Sig | ~10-20 | ~70-140 | $5-10/day | $100-200 | **~$170-340** |
| Lucky (signal→trade) | 8 DB, 2 Sig, 1 Trade | ~30+ | ~210+ | $15+/day | $200+ | **~$500+** |

ROI on $24 entry: casual = 4-7x, active = 7-14x, lucky = 20x+

**Tier 2 Scout (10M tokens, $120 entry, 1.5x)**

| Activity Level | Daily $ | Weekly bonus | Total 2wks |
|---------------|---------|-------------|-----------|
| Casual | $4-7/day | $75-150 | **~$130-250** |
| Active | $8-15/day | $150-300 | **~$260-510** |
| Lucky | $22+/day | $300+ | **~$750+** |

ROI on $120: casual = 1-2x, active = 2-4x, lucky = 6x+

**Tier 3 Scout (50M tokens, $600 entry, 3.0x)**

| Activity Level | Daily $ | Weekly bonus | Total 2wks |
|---------------|---------|-------------|-----------|
| Casual | $9-15/day | $150-300 | **~$275-510** |
| Active | $15-30/day | $300-600 | **~$510-1,020** |
| Lucky | $45+/day | $600+ | **~$1,500+** |

ROI on $600: casual = 0.5-0.9x, active = 0.9-1.7x, lucky = 2.5x+

**GP (250M tokens, $3,000 entry, 5.0x)**

| Activity Level | Daily $ | Weekly bonus | Total 2wks |
|---------------|---------|-------------|-----------|
| Casual | $15-25/day | $250-500 | **~$460-850** |
| Active | $25-50/day | $500-1,000 | **~$850-1,700** |
| Lucky | $75+/day | $1,000+ | **~$2,500+** |

ROI on $3,000: casual = 0.15-0.28x, active = 0.28-0.57x, lucky = 0.8x+
(GP entry is high — ROI comes from token appreciation, not just rewards)

### Key Takeaway Per Tier

| Tier | Entry | 2-wk earnings (active) | ROI on entry | Primary value |
|------|-------|----------------------|-------------|--------------|
| T1 | $24 | $170-340 | 7-14x | Accessible, high ROI, recruit masses |
| T2 | $120 | $260-510 | 2-4x | Sweet spot: good ROI + meaningful $ |
| T3 | $600 | $510-1,020 | 0.9-1.7x | Serious players, break-even+ |
| GP | $3,000 | $850-1,700 | 0.3-0.6x | Whales: ROI from token price, not rewards |

---

## 6. Price Impact Analysis

### Real Pool Data

FAIR/WETH on Uniswap V3 (Base): ~50 ETH in pool.
ETH ≈ $2,000 → Pool liquidity ≈ **$100K** (ETH side).

For concentrated liquidity V3, active range liquidity matters most. Assuming ~60-70% of liquidity is active around current price → effective liquidity ≈ $60-70K.

### Price Impact Formula (simplified)

```
Price impact ≈ Buy amount / (2 × Active liquidity)
```

| Buy Pressure | Impact (at $65K active liq) | New FDV (from $1.2M) |
|-------------|---------------------------|---------------------|
| $5,000 | ~3.8% | $1.25M |
| $10,000 | ~7.7% | $1.29M |
| $18,000 | ~13.8% | $1.37M |
| $50,000 | ~38.5% | $1.66M |
| $100,000 | ~77% | $2.12M |

### Scenario: Game Attracts Scouts

| New scouts (2 wks) | Avg buy | Total buy $ | Price impact | New FDV |
|--------------------|---------|-----------|-------------|---------|
| 30 | $120 (Tier 1) | $3,600 | ~2.8% | $1.23M |
| 50 | $180 (mix) | $9,000 | ~6.9% | $1.28M |
| 100 | $200 (mix) | $20,000 | ~15.4% | $1.38M |
| 200 | $300 (mix) | $60,000 | ~46% | $1.75M |
| 500 | $400 (mix) | $200,000 | ~154% → 2-2.5x | $2.4-3M |

**At thin V3 liquidity, scout adoption directly moves price.** 100 scouts = ~15% price increase. 500 scouts = 2x+. This IS the flywheel:

```
Scouts buy to enter → price up →
Existing scouts hold rewards (worth more) →
Less sell pressure → price holds →
More attention → more scouts → repeat
```

### Breaking Point

Max sell pressure from rewards: 1B pool × $0.000012 × 70% sell = $8,400 over 2 weeks.
Need buy pressure > $8,400 → need ~47 new scouts at avg $180 buy.
Below that → slow bleed. Above that → flywheel.

---

## 7. Weekly Leaderboard

250M tokens per week (50% of weekly allocation, or more with daily rollover).

### Scoring

Cumulative weighted points earned during the week. Same point values as daily (DB=1, Signal=5, Trade=20), weighted by signal weight from holdings.

### Payout Structure

| Rank | % of Weekly Pool | At 250M base | At ~400M (with rollover) |
|------|-----------------|-------------|------------------------|
| #1 | 25% | 62.5M ($750) | 100M ($1,200) |
| #2 | 18% | 45M ($540) | 72M ($864) |
| #3 | 13% | 32.5M ($390) | 52M ($624) |
| #4-5 | 10% each | 25M ($300) | 40M ($480) each |
| #6-10 | 4.8% each | 12M ($144) | 19.2M ($230) each |

### GP Earnings Range (test week)

| GP Type | Daily earned | Weekly bonus | Total/week |
|---------|-------------|-------------|-----------|
| Top performer | ~$1,500 | $750-1,200 | **~$2,250-2,700** |
| Average active | ~$350 | $144-230 | **~$494-580** |
| Low activity | ~$80 | $144-230 | **~$224-310** |
| Inactive | $0 | $0 | $0 |

### Post-MVP Weekly Bonuses (flagged)

| Bonus | Mechanic |
|-------|---------|
| Earlyness | Early-season participants get +15% multiplier (permanent for S1) |
| Discovery | First to submit project agent later acts on = +10 bonus pts |
| Streak | Useful info every day (7/7) = +15 bonus pts |

---

## 7. Scout Incentive to Hold Rewards

### Why Sell Is Worse Than Hold

| Action | Immediate | Next season |
|--------|-----------|-------------|
| Sell all rewards | Get $ now | Stay same tier, same multiplier |
| Hold all rewards | No $ now | Move up tier → higher multiplier → earn more next season |

### Example: Tier 1 Scout Earns 10M Tokens Over Season

| Choice | Holdings after | Tier | Next season multiplier | Next season earning potential |
|--------|---------------|------|----------------------|---------------------------|
| Sell all | 2M (original) | Tier 1 | 1.0x | Same as before |
| Hold all | 12M (2M + 10M earned) | **Tier 2** | **1.5x** | **50% more earnings** |
| Hold + buy 38M more | 50M | **Tier 3** | **3.0x** | **Triple earnings** |

**The carrot:** Hold one season of rewards → auto-upgrade to Tier 2. Hold + invest a bit more → Tier 3 at 3x. Each step up is a meaningful jump.

### Tier Upgrade Math

| From → To | Tokens needed | Cost at $1.2M | Benefit |
|-----------|-------------|--------------|---------|
| Tier 1 → Tier 2 | 8M more | $96 | 1.5x rewards + enhanced weight |
| Tier 2 → Tier 3 | 40M more | $480 | 3.0x rewards + high weight |
| Tier 3 → GP | 200M more | $2,400 | 5.0x rewards + maximum weight |

Realistic path: Tier 1 scout plays 2-3 seasons, holds rewards, buys small amounts → reaches Tier 2. Then holds 4-5 seasons → approaches GP.

---

## 8. Bear / Normal / Bull (Public, 2 weeks)

### At FDV $1.2M, 1% pool ($12,000)

| Metric | Bear | Normal | Bull |
|--------|------|--------|------|
| New scouts | 20 | 50 | 200 |
| Avg buy per scout | $100 | $180 | $300 |
| **Total buy pressure** | **$2,000** | **$9,000** | **$60,000** |
| Rewards paid | $8,000 | $10,000 | $12,000 |
| Sell % | 70% | 50% | 30% |
| **Sell pressure** | **$5,600** | **$5,000** | **$3,600** |
| **Net** | **-$3,600** | **+$4,000** | **+$56,400** |
| Price impact (at $50K liq) | -3.6% | +4% | +56% 🚀 |

### At FDV $2.4M, 1% pool ($24,000)

| Metric | Bear | Normal | Bull |
|--------|------|--------|------|
| New scouts | 20 | 50 | 200 |
| Avg buy | $200 | $360 | $600 |
| **Buy pressure** | **$4,000** | **$18,000** | **$120,000** |
| Sell pressure (70/50/30%) | $11,200 | $10,000 | $7,200 |
| **Net** | **-$7,200** | **+$8,000** | **+$112,800** |

### At FDV $6M, 1% pool ($60,000)

| Metric | Bear | Normal | Bull |
|--------|------|--------|------|
| New scouts | 20 | 50 | 200 |
| Avg buy | $500 | $900 | $1,500 |
| **Buy pressure** | **$10,000** | **$45,000** | **$300,000** |
| Sell pressure | $28,000 | $25,000 | $18,000 |
| **Net** | **-$18,000** | **+$20,000** | **+$282,000** |

### Takeaway

Bear is always negative — that's what bear means. The question is: how fast does pool drain and can we survive until conditions improve?

At 1% pool: bear burns $3,600-$18,000 per 2-week season depending on FDV. At $1.2M that's 0.3% of FDV per season — survivable for many seasons. At $6M it's still only 0.3%.

**Safety valve for future:** Dynamic rate reduction (parked for post-test). In bear, auto-reduce rewards to extend pool life.

---

## 9. Early Adopter Incentive

### Earlyness = Starting Early in the Game

Season 1 scouts get natural advantages:
- Fewer competitors → bigger share of pool
- Lower entry cost → cheaper to reach higher tiers
- Pioneer reputation (post-MVP: permanent +15% multiplier for S1 participants)

### Discovery Bonus (post-MVP)

First scout to submit a project that agent acts on:

| Action | Discovery bonus |
|--------|----------------|
| DB save | +250K tokens |
| Signal | +2.5M tokens |
| Trade | +12.5M tokens |

Only first submitter (by priority queue — whales first). Incentivizes original finds.

---

## 10. Sybil Check

### Tier 1 (2M = $24 entry)

| Action | Reward | Break-even subs |
|--------|--------|----------------|
| DB save | $6 | 4 accepted |
| Signal | $60 | <1 |

At 70-80% reject rate: 4 accepted = ~15-20 submissions. Marginal but low $ upside. Agent quality filter is the real defense.

### Tier 2 ($120 entry, 1.5x)

Need ~13 accepted DB saves or ~2 signals to break even. Quality filter blocks low-effort.

### Tier 3 ($600 entry, 3.0x)

Need ~33 accepted DB saves or ~3 signals. Not farmable at scale.

### GP ($3,000 entry)

Economically irrational to sybil.

---

## 11. Risk Flags

| Risk | Trigger | Response |
|------|---------|----------|
| Reward dilution (too many scouts) | Reward per point drops below motivating threshold (< $0.50/day for active T1 scout) | Increase pool allocation for next season or add bonus pools |
| Pool underused | <30% of points capacity generated after week 1 | Increase promotion, review if tiers are too restrictive |
| Whale dominates | >35% weekly points | Cap individual at 25% of weekly pool |
| Scout death spiral | <10 active scouts + falling price | Pause season, preserve remaining pool |
| Sybil at Tier 1 | Suspicious multi-wallet patterns | Ban + raise Tier 1 minimum |

---

## 12. ⚠️ PARKED ITEMS

| Item | Status | Blocker |
|------|--------|---------|
| P&L-linked rewards | Parked | Legal review |
| PNL Track Record multiplier | Future idea | Not MVP — add as extra tier bonus later |
| Agent evaluation time | TBD | Call discussion |
| Dynamic rate reduction | Post-test | Add if bear conditions persist |
| Discovery bonus | Post-MVP | Needs duplicate detection |
| Streak bonus | Post-MVP | Retention mechanic |
| Pioneer multiplier | Post-MVP | S1 permanent bonus |

---

## 13. Summary

| Decision | Choice |
|----------|--------|
| Model | Proportional points system. Pool splits by weighted points. No fixed token amounts per action. |
| Split | 50% daily / 50% weekly. Unused daily → weekly |
| Holdings | Affect priority (signal weight) AND reward (tier multiplier) |
| Test | 1 week, 10 GPs, 1% pool, flat rewards, no multipliers |
| Public tiers | T1: 2M ($24) 1.0x / T2: 10M ($120) 1.5x / T3: 50M ($600) 3.0x / GP: 250M ($3K) 5.0x |
| Pool | Start 1%. Increase when economics positive. Pool cannot drain early — proportional model caps daily spend |
| Bear safety | Proportional model auto-adjusts: fewer scouts = higher per-scout reward. More scouts = dilution but more buy pressure |
| Price impact | 50 scouts ≈ +9% price. 200 scouts ≈ +48%. Flywheel kicks in |
| Scout retention | Hold rewards → tier up → higher earnings next season |
