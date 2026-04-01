# FAIR SCOUT GAME — Section 4: Governance & Retention

---

## 4.1 Who Controls What

### Decision Authority

All scout game parameters are controlled by the core team (you + Luke). No on-chain governance, no DAO votes, no GP committee. Fast iteration > decentralization at this stage.

### Parameter Table

| Parameter | Who Decides | Can Change Mid-Season? | Communication Required |
|-----------|------------|----------------------|----------------------|
| Reward pool size (% of supply) | Core team | No — locked at season start | Announce before season |
| Tier thresholds (2M/10M/50M/250M) | Core team | No — locked at season start | Announce before season |
| Tier multipliers (1x/1.5x/3x/5x) | Core team | No — locked at season start | Announce before season |
| Daily/weekly pool split (50/50) | Core team | No | Announce before season |
| Season duration | Core team | Can extend, not shorten | 48h notice if extending |
| Base point values (1/5/20) | Core team | No | Announce before season |
| Submission rate limits (per day) | Core team | Yes — anti-abuse measure | Immediate, explain reason |
| Confidence thresholds (60%/80%) | Core team | Yes — tuning | No announcement needed (internal) |
| Evaluation model (Haiku/Sonnet) | Core team | Yes — optimization | No announcement needed (internal) |
| Emergency pause | Core team | Yes — any time | Immediate announcement with reason |
| Ban individual scout (sybil/abuse) | Core team | Yes — any time | Private notice to scout |

### Mid-Season Change Rules

**Hard lock (never change mid-season):**
- Pool size, tier thresholds, multipliers, point values, season duration (can't shorten)
- These are the "rules of the game" — changing them mid-play destroys trust

**Soft adjustable (can change with notice):**
- Rate limits (anti-abuse, announce reason)
- Season extension (if momentum is strong, announce 48h before original end)

**Internal tuning (no announcement):**
- Agent evaluation parameters (confidence thresholds, model selection)
- These are invisible to scouts — they only see outcomes (accepted/rejected)

---

## 4.2 Season Structure

### Continuous Seasons, No Gaps

Seasons run back-to-back. When S1 ends, S2 starts within 1-3 days. The gap is for:
- Running post-season analysis (Section 3.7 playbook — 2-3 hours)
- Adjusting parameters if needed
- Deploying new claim campaign on Hedgey for the new season's pool
- Announcement post with S1 results + S2 parameters

### Season Template

| Phase | Duration | What Happens |
|-------|----------|-------------|
| Pre-season | 1-3 days | Announce parameters, open signups for new scouts, deploy reward pool |
| Active season | 2 weeks (public) | Submissions, evaluations, daily payouts, weekly leaderboard |
| Settlement | 1 day | Final point calculations, weekly leaderboard payout, claim campaign live |
| Analysis | 1 day | Post-season report (automated + qualitative review) |
| Transition | 1 day | Parameter adjustments, next season setup |
| → Next season | — | Loop |

### What Resets Between Seasons

| Element | Resets? | Notes |
|---------|---------|-------|
| Points | Yes — fresh start | Everyone starts at 0 |
| Leaderboard | Yes — clean slate | Previous season archived, visible in history |
| Tier status | No — based on current holdings | If scout sold tokens and dropped tier, that's reflected |
| Submission history | No — cumulative | Builds scout track record over time |
| Reward pool | New allocation | Could be same 1% or adjusted based on economics |
| Scout profiles | No — persistent | Wallet, handle, join date carry over |
| Reputation score (future) | No — cumulative | Grows across seasons |

### Season Numbering & Identity

Each season gets a number and can get a theme for marketing purposes:
- S0: GP Test (1 week, closed)
- S1: Public Launch (2 weeks)
- S2, S3, ...: Ongoing

Seasons are the heartbeat of engagement. The reset creates urgency ("this season ends in 3 days"), the leaderboard creates competition, the continuity creates loyalty.

---

## 4.3 Retention Mechanics

### Layer 1: Tier Progression (Already Designed)

From the economics doc — the core retention loop:
- Earn rewards → hold them → tier up → earn more next season
- Tier 1 scout earns 10M tokens → holds → becomes Tier 2 → 1.5x multiplier
- Each tier up is a meaningful jump in earnings potential

This is the primary retention mechanic. It works because it costs nothing extra (just hold what you earned) and the benefit is concrete and visible.

### Layer 2: Leaderboard Competition

Weekly leaderboard with top 10 payouts. Creates:
- Public recognition (name/handle visible)
- Financial incentive (top scout gets 25% of weekly pool)
- Social proof (being #1 is bragging rights in CT)
- Streak motivation ("I was #3 last week, can I get #1 this week?")

The leaderboard should be visible on the dashboard AND shared as a public post by @fairvc at end of each week. This turns internal competition into external content.

### Layer 3: Track Record Reputation (Post-MVP)

Over time, each scout builds a visible track record:
- Total submissions accepted
- Signals that led to trades
- Win rate on scout-sourced trades
- Seasons active
- Current streak (consecutive seasons active)

This becomes a **Scout Score** — visible on their profile, on the leaderboard, and eventually usable as social proof outside the game ("I'm a verified Fair scout with 80% signal accuracy").

Reputation is the thing that can't be bought. A whale can buy GP tier, but they can't buy a track record of profitable signals. This creates a status hierarchy independent of holdings.

### Layer 4: Hold Duration Multiplier (Option)

**Concept:** Scouts who have held $FAIR for longer periods get a bonus multiplier on top of their tier multiplier. Rewards diamond hands, not just bag size.

**Possible structure:**

| Hold Duration | Bonus Multiplier | Stacks With Tier |
|--------------|-----------------|-----------------|
| < 30 days | 1.0x (no bonus) | — |
| 30-90 days | 1.1x | T2 (1.5x) → effective 1.65x |
| 90-180 days | 1.2x | T3 (3.0x) → effective 3.6x |
| 180+ days | 1.3x | GP (5.0x) → effective 6.5x |

**Pros:**
- Rewards loyalty, not just wealth — a Tier 1 scout who held for 6 months gets 1.3x vs a new Tier 1 at 1.0x
- Discourages "buy before season, sell after rewards" pattern
- Aligned with diamond hands culture (already tracked in FAIR analytics)
- Simple to implement: check earliest $FAIR acquisition date on-chain

**Cons:**
- Adds complexity to an already multi-layered point system
- Could feel unfair to new scouts ("I can never catch up to someone who held longer")
- On-chain hold duration tracking needs careful implementation (what counts as "held" if they moved between wallets?)

**Recommendation:** Flag for Season 2 or 3. Don't add to MVP — the tier system alone provides sufficient retention mechanics. Introduce when we have data on whether scouts are dumping rewards immediately (if yes, hold multiplier becomes more urgent).

### Layer 5: Seasonal Recognition (Post-MVP)

Non-financial rewards that create status:

| Recognition | Criteria | Value |
|------------|---------|-------|
| "S1 Pioneer" badge | Participated in Season 1 | Permanent tag on profile, potential future multiplier |
| "Alpha Hunter" | ≥3 trade-level signals in one season | Visible badge, recognition in @fairvc posts |
| "Consistent Scout" | Active every day of season (submitted ≥1/day) | Streak badge |
| "First Blood" | First scout to submit a project that led to a trade | One-time recognition |

These cost nothing to implement (just UI badges) but create collectors mentality and social status.

---

## 4.4 Handling Edge Cases

### Scout Drops Tier Mid-Season

Scout held 10M (Tier 2) at season start. Sells tokens mid-season, drops to 3M (Tier 1).

**Rule:** Tier is checked at time of each submission. If holdings dropped, new submissions use the lower tier multiplier. Points already earned at higher tier are not retroactively adjusted.

**Rationale:** Real-time tier checking prevents gaming (borrow tokens → submit → return). Simple to implement — just check balance at evaluation time.

### Scout Gets Banned

Confirmed sybil or abuse. What happens to their points?

**Rule:** Banned scout's points are removed from daily/weekly pool calculations. Remaining pool is redistributed among legitimate scouts. Tokens in unclaimed rewards are returned to pool.

### Season Extension

Mid-season, participation is much higher than expected. Pool is draining fast.

**Options (in order of preference):**
1. Let it drain — season ends when pool runs out (creates urgency, rewards early activity)
2. Extend season by adding more tokens to pool (requires announcement, sets precedent)
3. Reduce point values mid-season (breaks trust — avoid)

**Rule:** Option 1 by default. Option 2 only if pool runs out before 70% of season duration.

### Disputed Evaluation

Scout believes their submission was wrongly rejected.

**Rule:** No appeals process in MVP. Agent's decision is final. Post-MVP: add a "dispute" button that flags the submission for manual review by team. Cap at 3 disputes per scout per season to prevent abuse.

---

## 4.5 Parameter Evolution Roadmap

How parameters likely evolve across seasons:

| Parameter | S0 (Test) | S1 (Public) | S2-S3 | S4+ |
|-----------|-----------|-------------|-------|-----|
| Duration | 1 week | 2 weeks | 2 weeks | 2 weeks (or longer if stable) |
| Pool | 1% (1B) | 1% (1B) | 1-2% (based on economics) | Dynamic based on treasury performance |
| Tiers | GP only (flat) | 4 tiers (T1-GP) | 4 tiers (tuned thresholds if needed) | + Hold duration multiplier |
| Points | 1/5/20 | 1/5/20 | Adjust based on acceptance rate data | + Discovery bonus, streak bonus |
| Reputation | None | None | Track record visible | Scout Score as multiplier |
| Recognition | None | None | S1 Pioneer badge | Full badge system |
| Evaluation | Single model | Single model | Two-tier (Haiku + Sonnet) | + Scout reputation affects signal weight |

---

*Next section: GTM Plan →*
