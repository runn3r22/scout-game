# FAIR SCOUT GAME — Section 3: Outcomes, KPIs & What Success Looks Like

---

## 3.1 What This Gives Us (Priority Order)

### Priority 1: Better Token Sourcing

The entire point. Human scouts find alpha that algorithms miss. Scouts on X extend the agent's reach — different sources, different networks, different pattern recognition.

**What success looks like:** Agent receives scout-sourced signals that lead to profitable trades the autonomous pipeline would have missed. Even one trade per season that the pipeline wouldn't have found independently makes the mechanic valuable.

### Priority 2: Visibility on Winning Plays

If Fair becomes the default tag when someone finds alpha ("tag @fairvc on this"), every runner that scouts submit gives us visibility. When the token pumps, people see that Fair was tagged early. This is earned attention — not paid promotion.

**What success looks like:** @fairvc becomes a reflexive tag in crypto Twitter alpha circles. People tag us even without being scouts because they've seen others do it and seen that we actually act on good signals.

### Priority 3: Brand Awareness

The scout game is content. Every submission is a public tweet mentioning @fairvc. Every signal published is a demonstration of capability. The leaderboard creates competition, competition creates posts about the game, posts create awareness.

**What success looks like:** Growth in @fairvc mentions, followers, and engagement that correlates with scout activity. Non-scouts start following because they see the signal quality.

### Priority 4: New Token Buyers

Every scout must hold $FAIR. New scouts = new buyers. Tier progression incentivizes holding and buying more. The flywheel from the economics doc: more scouts → more alpha → better trades → token value up → attracts new scouts who must buy.

**What success looks like:** Net positive buy pressure from scout onboarding exceeds sell pressure from reward dumping (the break-even analysis from economics doc Section 6).

---

## 3.2 KPIs — Test Phase (1 week, 10 GPs)

The test is about mechanics validation, not growth. Does the system work? Do GPs engage? Is the signal quality useful?

### Primary KPIs

| KPI | Bear | Normal | Bull | Kill Signal |
|-----|------|--------|------|-------------|
| Active GPs (submitted ≥1) | 5/10 | 7/10 | 10/10 | <4/10 |
| Total submissions | 50 | 120 | 250+ | <30 |
| Acceptance rate (non-rejected) | 15% | 25% | 35% | <10% (signals too noisy) or >50% (bar too low) |
| Signals published | 2 | 5 | 10+ | 0 |
| Trades executed from scout signals | 0 | 1 | 3+ | — (not a kill signal for test) |
| GP satisfaction (qualitative) | "okay" | "useful" | "I found stuff I'd have missed" | "waste of time" |

### Secondary KPIs

| KPI | Target | Why It Matters |
|-----|--------|---------------|
| Time from submission to evaluation | <1 hour | UX — scouts need fast feedback |
| Duplicate submission rate | <30% | If higher, scouts overlap too much with each other / pipeline |
| Reward pool utilization | 20-60% | Under 20% = not enough activity. Over 60% = spending too fast |
| Technical issues / bugs | <3 blockers | System stability for public launch |
| False positives (agent acts on bad signal) | 0 | Critical — one bad trade from scout signal damages trust |

### Test Phase Success Definition

**Pass (go to public):** ≥6 GPs actively submitting, ≥3 signals published, no critical bugs, at least 1 GP says "this found something our pipeline missed."

**Conditional pass (tune and retest):** 4-5 GPs active, mechanics work but engagement low, need to adjust incentives or UX.

**Fail (rethink):** <4 GPs engage, submissions are mostly noise, or a scout-sourced signal leads to a bad trade.

---

## 3.3 KPIs — Public Season 1 (2 weeks, open tiers)

### Primary KPIs

| KPI | Bear | Normal | Bull | Kill Signal |
|-----|------|--------|------|-------------|
| Total scouts onboarded | 15 | 50 | 150+ | <10 |
| Scouts active (submitted ≥3 over season) | 8 | 30 | 100+ | <5 active |
| Tier distribution (T1/T2/T3/GP) | 80/15/5/0% | 50/25/15/10% | 40/25/20/15% | 95%+ at T1 only (no tier progression interest) |
| Submissions per day (avg) | 15 | 50 | 150+ | <5/day after day 3 |
| Signals published (total season) | 5 | 15 | 40+ | <3 |
| Trades from scout signals | 1 | 3 | 8+ | 0 over full season |
| Scout-sourced trade win rate | — | ≥40% | ≥60% | 0% (all losses) |
| New $FAIR buy volume from scouts | $1,500 | $9,000 | $45,000+ | <$500 |
| Net token impact (buy - sell pressure) | -$3,600 | +$4,000 | +$56,000 | Sustained negative with no signs of reversal |

### Sourcing Quality KPIs (Priority 1 specific)

| KPI | Target | How to Measure |
|-----|--------|---------------|
| Unique projects submitted (not already in DB) | ≥30% of submissions | Compare against `projects` table at time of submission |
| Scout signals → pipeline would have missed | ≥5 per season | Manual tag: was this project already on pipeline radar? |
| Time advantage (scout found it before pipeline) | ≥24h ahead on ≥3 projects | Compare scout submission timestamp vs first pipeline mention |
| Trade-level signal from scouts that pipeline didn't surface | ≥1 per season | The key metric — did scouts find alpha the agent wouldn't have found alone? |

### Visibility KPIs (Priority 2 specific)

| KPI | Bear | Normal | Bull |
|-----|------|--------|------|
| @fairvc mentions/week (organic, non-scout) | +10% | +30% | +100% |
| @fairvc follower growth during season | +50 | +200 | +1,000 |
| Non-scout tags (people tagging us who aren't in the game) | 5 | 20 | 100+ |
| "Tag @fairvc" screenshot/retweet moments | 0 | 2 | 10+ |

### Season 1 Success Definition

**Strong success:** ≥30 active scouts, ≥3 trade-level signals, at least 1 profitable trade from scout sourcing, net positive buy pressure. Immediate Season 2 with expanded pool.

**Moderate success:** 15-30 active scouts, signals published but few trades, buy pressure roughly neutral. Proceed to Season 2 with parameter adjustments (reward rates, tier thresholds, or pool size).

**Underperformance:** 10-15 scouts, submissions drop off after day 3-4, mostly T1 with no tier progression. Pause, survey scouts for feedback, redesign incentives before S2.

**Kill:** <10 active scouts OR 0 trade-level signals over full season OR net buy pressure deeply negative with no improvement trend. Redirect resources elsewhere.

---

## 3.4 Kill Criteria (When to Stop)

Clear red lines. If any of these trigger, pause the scout game and evaluate whether to continue.

| Kill Signal | Threshold | When to Evaluate | Action |
|------------|-----------|-----------------|--------|
| No interest | <10 scouts sign up for public S1 despite marketing push | End of day 3 | Pause. Reassess GTM or incentive structure |
| Dead game | Active scouts drops below 5 for 3 consecutive days | Mid-season | End season early, preserve remaining pool |
| Tier collapse | >90% of scouts at T1 with zero tier-ups after S1 | End of S1 | Tier thresholds or multipliers are wrong. Redesign |
| Zero sourcing value | 0 trade-level scout signals over 2 full seasons | End of S2 | Core thesis failed. Scouts aren't finding tradeable alpha. Kill or pivot to signal-only (no trade actions) |
| Net negative economics | Sell pressure from rewards consistently >2x buy pressure from new scouts | 2 consecutive seasons | Economics don't work at current FDV. Pause until conditions change or redesign reward model |
| Bad trades | Scout-sourced trades have <20% win rate over 2 seasons | End of S2 | Scout signals are net negative for the fund. Kill trade-level rewards, keep DB save + signal only |
| Agent exploitation | Confirmed prompt injection or confidence score gaming through scout submissions | Any time | Immediate pause. Fix evaluation pipeline before resuming |
| Platform risk | X account suspended or API access revoked | Any time | Activate Farcaster fallback (design for multi-platform from day one) |

---

## 3.5 Baseline Problem: No Current Benchmark

There's no existing baseline for autonomous pipeline performance (win rate, signal quality, alpha generation). This makes it hard to measure "did scouts improve the agent?"

### Solution: Establish Baseline During Test Phase

During the 1-week GP test, run both systems in parallel:
- **Autonomous pipeline** continues as normal (Farcaster ingestion → scoring → agents)
- **Scout channel** runs simultaneously

At end of test, compare:

| Metric | Autonomous Pipeline | Scout Channel |
|--------|-------------------|---------------|
| New projects discovered | ? | ? |
| Signals published | ? | ? |
| Trades recommended | ? | ? |
| Overlap (both found same project) | ? | — |
| Unique to scouts (pipeline missed) | — | ? |
| Unique to pipeline (scouts missed) | ? | — |

This gives the first real data point for "are scouts additive?" Even rough numbers are better than nothing.

### Ongoing Tracking (Post-Test)

Tag every signal and trade with its source:
- `source: pipeline` — found by autonomous Farcaster pipeline
- `source: scout` — submitted by scout
- `source: both` — pipeline had it, scout also submitted

Over time this builds a dataset showing the marginal value of the scout channel.

---

## 3.6 What "Winning" Looks Like — Narrative View

### After Test (Week 1)

The team can say: "We ran a 1-week test with 10 GPs. They submitted 120+ signals. The agent found 3 projects it hadn't seen before, published 5 signals, and executed 1 trade. The mechanic works. Going public."

### After Season 1 (Week 3-4)

The team can say: "50 scouts are actively scouring X for alpha and tagging @fairvc. We've published 15 scout-sourced signals. 3 led to trades, 2 profitable. @fairvc mentions are up 30%. 40 new wallets bought $FAIR to participate. The scout channel is producing alpha the pipeline misses."

### After 3 Seasons (Month 3-4)

The team can say: "@fairvc is becoming a default tag for CT alpha. We have 200 active scouts across tiers. Scout-sourced trades are performing on par with pipeline trades. The community is self-reinforcing — scouts compete to find the next runner, the leaderboard drives engagement, and every winning trade is public proof that the system works. The scout channel has become a core part of Fair's intelligence infrastructure, not just a marketing campaign."

### The Dream Outcome

Someone on CT posts: "found an interesting new project" → replies immediately fill with "tag @fairvc" → because people know that if Fair picks it up and trades it, it's validated. Fair becomes the quality seal for micro-cap discoveries. Scouts are the distributed research team. The token accrues value because the fund's alpha pipeline has a human layer no pure-AI competitor can replicate.

---

## 3.7 How We Analyze: Measurement Framework

### What to Set Up BEFORE Launch

If we don't build data collection into the system from day one, post-season analysis becomes manual archaeology. Everything below should be in place before the GP test starts.

### A. Data Collection (Built Into the System)

**1. Source tagging on every signal and trade**

Add `source_type` field to `projects`, `agent_memory`, and any signal/trade record:
- `pipeline` — found by autonomous Farcaster pipeline
- `scout` — submitted by a scout
- `both` — pipeline had it, scout also submitted

Add `project_existed_at_submission` boolean to `scout_submissions` — was this project already in DB when the scout submitted it? This is the single most important field for measuring scout additive value.

**2. Daily metrics snapshot table (`scout_daily_metrics`)**

Automated job, runs once per day, writes one row:

| Field | Source |
|-------|--------|
| date | system |
| active_scouts (submitted today) | `scout_submissions` count distinct wallet |
| total_submissions | `scout_submissions` count |
| rejected / db_save / signal / trade | `scout_submissions` grouped by result |
| pool_remaining | `scout_seasons` balance |
| new_signups_today | `scout_profiles` where created_at = today |
| cumulative_scouts | `scout_profiles` total count |
| fair_mentions (X) | X API mention count (if feasible) |
| fair_followers | X API follower count |

This table IS the analysis. After the season, export it → instant trendline of every metric by day.

**3. Evaluation log enrichment**

Every row in `scout_submissions` must store:
- `confidence_score` (0-100) — agent's assessment
- `evaluation_time_seconds` — time from submission to result
- `evaluator_model` — which model evaluated (Haiku triage vs Sonnet deep)
- `reasoning_summary` — 1-2 sentence agent explanation (useful for debugging quality)
- `duplicate_of` — reference to earlier submission of same project (if applicable)

**4. Trade outcome tracking (async update)**

For scout-sourced trades, add fields that get updated later:
- `trade_entry_price`, `trade_exit_price`
- `trade_pnl_percent`
- `trade_pnl_usd`
- `trade_status` (open / closed_profit / closed_loss / stopped_out)

These update over days/weeks as positions close.

### B. Pre-Launch Baseline Snapshot

Before GP test starts, record in a document or Supabase row:

| Metric | Value | Where to Get It |
|--------|-------|----------------|
| Total projects in DB | count(`projects`) | Supabase |
| Total agent_memory entries | count(`agent_memory`) | Supabase |
| Last 10 autonomous signals | list with dates | `communication_alerts` or signal feed |
| Last 10 autonomous trades | list with PNL if available | Trading records |
| @fairvc X followers | number | X API or manual |
| @fairvc avg mentions/week (last 4 weeks) | number | X API or manual |
| $FAIR price / FDV | number | DexScreener |
| Total $FAIR holders | number | BaseScan |

Same snapshot after test, after S1, after each season. Delta = impact.

### C. Post-Season Analysis Playbook

When a season ends, here's exactly what to do:

**Step 1: Export data (30 min)**
- Export `scout_daily_metrics` → CSV
- Export `scout_submissions` → CSV
- Export `scout_profiles` → CSV
- Export `scout_leaderboard` → CSV
- Take post-season baseline snapshot (same metrics as pre-launch)

**Step 2: Automated report (build once, reuse every season)**

Script or Dune dashboard that outputs:

```
SCOUT GAME — SEASON [X] REPORT

PARTICIPATION
- Scouts registered: [n]
- Scouts active (≥3 submissions): [n]
- Tier distribution: T1: [n] / T2: [n] / T3: [n] / GP: [n]
- Submissions total: [n] (avg [n]/day)
- Acceptance rate: [x]%

SOURCING QUALITY
- Unique new projects from scouts: [n]
- Projects scouts found before pipeline: [n] (avg [x]h advantage)
- Signals published (scout-sourced): [n]
- Trades executed (scout-sourced): [n]
- Scout trade win rate: [x]%
- Scout trade avg PNL: [x]%

ECONOMICS
- Pool allocated: [n] tokens ($[x])
- Pool spent: [n] tokens ($[x]) — [x]% utilization
- Reward sell pressure (estimated): $[x]
- New scout buy pressure: $[x]
- Net token impact: $[x]
- $FAIR price change during season: [x]%

ENGAGEMENT
- Day-over-day active scout trend: [chart/sparkline]
- Submissions per day trend: [chart/sparkline]
- Drop-off point: day [n] (where activity declined >30%)
- @fairvc mentions change: [x]%
- @fairvc follower change: [+n]

TOP PERFORMERS
- #1: [wallet/handle] — [n] points, [n] signals, [n] trades
- #2-5: [summary]

KILL CRITERIA CHECK
- [ ] Active scouts > 10? 
- [ ] Trade-level signals > 0?
- [ ] Net economics positive or neutral?
- [ ] No agent exploitation detected?
- [ ] No platform issues (X API, account health)?
→ VERDICT: [CONTINUE / TUNE / PAUSE / KILL]
```

**Step 3: Qualitative review (1 hour)**
- Read top 10 scout submissions that led to signals/trades — what made them good?
- Read top 10 rejected submissions — what patterns? Are rejects getting better over time?
- Talk to 3-5 scouts: what's working, what's frustrating, what would make them submit more?
- Compare scout-sourced signals vs pipeline signals side-by-side: quality difference?

**Step 4: Decision meeting (30 min)**
- Review automated report
- Check against KPIs from Section 3.2/3.3
- Check kill criteria from Section 3.4
- Decide: proceed to next season / adjust parameters / pause / kill
- If proceeding: document parameter changes for next season

### D. Tools

| Tool | Purpose | Already Have? |
|------|---------|:------------:|
| Supabase | All data storage, queries, exports | ✅ |
| Dune Analytics | Public-facing dashboards (pool status, leaderboard, trade performance) | ✅ |
| DuneSQL queries | Automated on-chain metrics (FAIR buys from scout wallets, claim activity) | ✅ |
| X API | Mention counts, follower tracking | ✅ |
| Python/JS script | Post-season report generation from Supabase exports | Build once |
| Spreadsheet | Quick scenario modeling, parameter tuning between seasons | — |
| Telegram bot | Automated daily digest to team (key metrics from `scout_daily_metrics`) | ✅ (existing team bot) |

### E. Effort Estimate

| Task | When | Time | Who |
|------|------|------|-----|
| Add `source_type` field to existing tables | Pre-launch | 1 hour | Dev |
| Create `scout_daily_metrics` table + cron job | Pre-launch | 2-3 hours | Dev |
| Ensure `scout_submissions` has all enrichment fields | Pre-launch | 1 hour | Dev |
| Take baseline snapshot | Day before test | 30 min | Anyone |
| Build post-season report script | During test week (low urgency) | 3-4 hours | Dev |
| Daily check of metrics during season | Ongoing | 5 min/day | Ops |
| Post-season full analysis | After each season | 2 hours | Lead |

Total pre-launch setup: ~5 hours of dev time. After that, analysis is mostly automated.

---

*Next section: Governance & Retention →*

