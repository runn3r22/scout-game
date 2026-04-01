---
name: deep-analysis
description: >
  Deep token analysis for scout evaluation. Load this skill when you need
  to score a token across 5 dimensions (builder/team, product, on-chain,
  market, narrative) and calculate the final score (Steps 5-6).
user-invocable: false
---

# Deep Token Analysis (Steps 5-6)

Apply the builder-first framework across 5 dimensions. Cross-reference scout's claims against snapshot data, your knowledge, and any web search results.

---

## Dimension 1: Builder / Team (0-4 points) — Most Important (widest range)

Assess the people behind this token — solo dev, team, or collective.

**Evaluate:**
- Identity: X handles, backgrounds, prior projects (solo dev or team — both valid)
- Social graph: builders and deployers in followers vs bots and degens
- Activity: posting frequency, shipping updates, engagement quality
- Track record: prior projects, outcomes, exits, rugpulls
- Time horizon: building long-term or extracting short-term?
- Team breadth: dev + designer + community lead > solo anon
- Advisors or backers with credibility

**Red flags (each reduces score):**
- Completely anonymous with no history or product
- Multiple prior rug pulls or abandoned projects
- Only posts about price, never shipping updates
- Very new accounts created days before token launch
- Deployer wallet selling immediately after launch
- `CLANKER_FEES_UNCLAIMED` on a token >= 7 days old

**Green flags (each supports score):**
- Named, verifiable individuals with prior successful projects
- Long account history with organic followers
- Active shipping: code commits, product updates, user support
- Known builders in their social graph
- Deployer wallet not selling; staking; adding liquidity
- Clanker token with fees already claimed
- Multiple visible contributors (not just one person)

**Scoring (0-4, weighted 2x):**
- 0 = unidentifiable or clear red flags, no visible team
- 1 = anonymous but some building activity visible, solo
- 2 = pseudonymous builder(s), actively building, some verifiable history
- 3 = named builder(s) with verifiable track record OR strong pseudonymous team with significant prior project
- 4 = named team with proven track record, strong social graph, active shipping, long account history, multiple contributors

---

## Dimension 2: Product Reality (0-2 points)

- Live product vs roadmap/whitepaper only
- On-chain activity beyond token trading (contract interactions, real users)
- Measurable traction: TVL, users, integrations, revenue
- Meaningfully differentiated or a copy?

**Scoring:** 0 = vaporware / 1 = product in development, some on-chain activity / 2 = working product with real usage

---

## Dimension 3: On-chain Activity (0-2 points) — NEW

Evaluate verifiable on-chain signals beyond basic snapshot data.

**What to look for:**
- **Smart money accumulation**: wallets with proven track records (early buyers of previous winners) are buying this token. Named wallets or wallets with verifiable history.
- **Whale behavior patterns**: large wallets accumulating steadily (not one-time dump buys). Check buy/sell ratio from snapshot.
- **Deployer wallet history**: has this deployer launched successful projects before? What's the deployer's on-chain reputation?
- **Holder quality**: are top holders known builders, funds, or smart money? Or random/bot wallets?
- **Contract interactions**: beyond trading — are people using the product on-chain? Real contract calls, real users.
- **LP behavior**: is liquidity being added organically by multiple providers, or is it all from deployer?

**What counts as on-chain evidence:**
- Scout names specific wallet addresses with verifiable history
- Scout references specific transactions ("deployer sent 20 ETH to known wallet 3h ago")
- Scout identifies smart money wallets accumulating ("wallet 0x... that was early in [token that 10x'd] is buying")
- Unusual buy patterns with verifiable on-chain data

**What does NOT count:**
- "Whales are buying" with no addresses
- "Smart money is in" with no proof
- Volume numbers alone (volume ≠ on-chain insight)

**Scoring:**
- 0 = no verifiable on-chain signal, or on-chain data shows red flags (dumping, wash patterns)
- 1 = some positive on-chain signals (healthy buy/sell ratio, holder growth, some smart money)
- 2 = strong on-chain evidence (named smart money accumulating, deployer with proven history, real product usage on-chain)

---

## Dimension 4: Market Structure (0-1 point)

Most tokens in our flow launch via factories (Clanker, Bankr, etc.) with standardized structures. Market structure is less differentiated — evaluate briefly:

- **FDV vs comps**: closest comparable project. Cheap or stretched?
- **Liquidity ratio**: `pool_liquidity_usd / fdv_usd`. Under 2% = untradeable at size. 5-15% = normal. >15% = healthy.
- **Holder distribution**: top 10 concentration (LP excluded). Deployer wallet activity.
- **Buy/sell ratio**: net money flowing in or out?
- **Launch structure**: factory launch with locked LP > custom deploy with unknown structure

**Scoring:**
- 0 = dangerous (ultra-thin liquidity, high concentration, active dumping, suspicious structure)
- 1 = acceptable to strong (reasonable liquidity, fair distribution, healthy flow)

---

## Dimension 5: Narrative Fit (0-2 points)

- **Current meta**: what categories are in the hot-ball-of-money rotation? Does this fit?
- **Lifecycle position**: Thesis phase (early, buy) → Popularity (crowded but moving) → Exuberance (sell)
- **Attention state**: Niche → becoming favoured = max opportunity. Saturated = too late
- **Who's talking**: builders and analysts > "LFG" crowd
- **Discourse trend**: growing mentions or fading?

Best signals: new token, real product, fits live narrative that hasn't peaked, nobody's talking about it yet.

**Scoring:** 0 = no fit or narrative exhausted / 1 = fits a meta but crowded / 2 = strong fit with live, early narrative

---

## Dimension 6: Synthesis — Expected Value

With scores from dimensions 1-5, synthesize:

1. **Enumerate 2-3 scenarios** with rough probabilities:
   - Bull case: thesis plays out
   - Base case: most likely outcome
   - Bear case: fails

2. **Expected value direction**: asymmetric upside vs capped downside?

3. **Kill conditions**: what makes this trade dead?

4. **Timing**: BEFORE the run (early signal) or AFTER (chasing)?

---

## Final Score Calculation

**Token Score** = raw sum of dimension scores (no multiplier in formula):
- Builder/Team: 0-4 *(importance comes from wider range, not a formula multiplier)*
- Product Reality: 0-2
- On-chain Activity: 0-2
- Market Structure: 0-1
- Narrative Fit: 0-2
- **Max raw = 11**

Normalize to 0-10: `token_score = (raw_score / 11) * 10`

Example: Builder 3 + Product 1 + On-chain 1 + Market 1 + Narrative 1 = raw 7 → (7/11)*10 = 6.4 → DB_SAVE

Apply modifiers from AGENTS.md modifier table. Final Score = token_score + modifiers (floor 0, ceiling 10).

---

## Investment Frameworks

Apply these during dimension analysis.

### Metagame Theory
Bull-market crypto = video game with evolving meta. Biggest edge = knowing which narrative the money is rotating into.

- Name the current meta explicitly
- Identify lifecycle phase: Thesis → Popularity → Exuberance
- Buy in thesis phase. Sell in exuberance.
- Meta rooted in real problem = durable. Meta rooted in mimetic exuberance = burns fast.
- Best setup: real product + early narrative fit + nobody talking about it yet

### Attention Theory of Value
Price = f(attention). Only scarce resource in crypto = attention.

1. **Niche** (early, alpha) — best entry
2. **Becoming favoured** (buy zone, attention growing) — maximum opportunity
3. **Saturated** (attention peaks, ownership catches up) — exit zone
4. **Bagholders only** (stale, avoid)

Rule: buy the transition, not the destination.

### Probabilistic Thinking
- Enumerate 2-3 scenarios with probabilities
- Asymmetric risk/reward: large likely upside + small unlikely downside = good trade
- 80% chance of +3x and 20% chance of -50% = strong expected value
- Define exit plan and trigger events

### Incentive Mapping
- Is team aligned long-term or extracting short-term?
- Where are seed investors vs public price? Cliff unlocks incoming?
- Has deployer wallet been selling?
- Fair launch (no VC dump) is structurally advantaged

### Social Graph as Distribution
- 50 active deployers in followers > 5,000 dormant accounts
- Engagement quality > engagement volume
- 4-year-old account with organic connections cannot be faked
- Builders in replies = real signal. "LFG" accounts = noise
