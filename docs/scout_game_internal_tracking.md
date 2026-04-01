# FAIR SCOUT GAME — Section 6: Internal Tracking System Design

---

## 6.1 What We Track

### Core Metrics

| Metric | Source | Update Frequency | Who Sees |
|--------|--------|-----------------|----------|
| Active scouts (submitted today) | `scout_submissions` | Hourly | Team + Public (count only) |
| Total submissions (today / season) | `scout_submissions` | Hourly | Team + Public |
| Acceptance rate (DB / signal / trade / rejected %) | `scout_submissions` | Hourly | Team only |
| Signals published (scout-sourced) | `scout_submissions` + signal feed | Real-time | Team + Public |
| Trades executed (scout-sourced) | `scout_submissions` + trade records | Real-time | Team + Public |
| Daily rewards distributed (tokens) | Points calculation engine | Daily | Team + Public (pool status) |
| Weekly rewards distributed (tokens) | Leaderboard calculation | Weekly | Team + Public |
| Sell pressure (FAIR sold by scout wallets) | On-chain monitoring (Dune) | Daily | Team only |
| Buy pressure (FAIR bought by registered scout wallets) | On-chain monitoring (Dune) | Daily | Team only |
| Net token impact (buy - sell) | Derived | Daily | Team only |
| Leaderboard rankings | Points calculation engine | Hourly | Team + Public |
| Pool remaining (tokens + % of allocation) | `scout_seasons` | Hourly | Team + Public |
| New scout signups | `scout_profiles` | Hourly | Team only |
| Reward per weighted point (dilution indicator) | Derived: daily pool ÷ total weighted points | Daily | Team only |

### Scout-Level Metrics

| Metric | Source | Purpose |
|--------|--------|---------|
| Submissions (total / accepted / rejected) | `scout_submissions` | Activity + quality tracking |
| Points earned (daily / weekly / season) | `scout_points_daily` | Reward calculation |
| Tier + current holdings | On-chain balance check | Tier verification |
| Win rate (% of submissions → signal or trade) | `scout_submissions` | Track record / reputation |
| Unique projects submitted | `scout_submissions` vs `projects` | Sourcing quality |
| Tokens earned (claimed / unclaimed) | `scout_rewards` | Reward tracking |
| Tokens sold after claim | On-chain (Dune) | Sell pressure per scout |

---

## 6.2 Database Schema

### New Tables (Added to Existing Supabase)

**⚠️ Schema subject to dev team review — flagged as open question**

```sql
-- Scout profiles
CREATE TABLE scout_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_address TEXT NOT NULL UNIQUE,
  x_handle TEXT NOT NULL,
  x_user_id TEXT,
  tier TEXT NOT NULL, -- 'T1', 'T2', 'T3', 'GP'
  token_balance BIGINT, -- last checked balance
  balance_checked_at TIMESTAMPTZ,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  is_banned BOOLEAN DEFAULT FALSE,
  ban_reason TEXT
);

-- Scout submissions
CREATE TABLE scout_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scout_id UUID REFERENCES scout_profiles(id),
  season_id UUID REFERENCES scout_seasons(id),
  tweet_id TEXT NOT NULL,
  tweet_url TEXT,
  tweet_content TEXT,
  project_ref UUID REFERENCES projects(id), -- NULL if new project
  project_existed BOOLEAN NOT NULL, -- was project in DB at submission time?
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  evaluated_at TIMESTAMPTZ,
  evaluation_time_ms INTEGER, -- time to evaluate
  evaluator_model TEXT, -- 'haiku-4.5' or 'sonnet-4.5'
  confidence_score NUMERIC(5,2), -- 0.00 - 100.00
  result TEXT NOT NULL, -- 'rejected', 'db_save', 'signal', 'trade'
  reasoning_summary TEXT, -- 1-2 sentence agent explanation
  base_points INTEGER NOT NULL DEFAULT 0,
  weighted_points NUMERIC(10,2) NOT NULL DEFAULT 0,
  source_type TEXT DEFAULT 'scout', -- 'scout', 'pipeline', 'both'
  duplicate_of UUID REFERENCES scout_submissions(id) -- if duplicate
);

-- Daily point snapshots
CREATE TABLE scout_points_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scout_id UUID REFERENCES scout_profiles(id),
  season_id UUID REFERENCES scout_seasons(id),
  date DATE NOT NULL,
  submissions_count INTEGER DEFAULT 0,
  accepted_count INTEGER DEFAULT 0,
  base_points INTEGER DEFAULT 0,
  weighted_points NUMERIC(10,2) DEFAULT 0,
  daily_pool_share NUMERIC(20,2) DEFAULT 0, -- tokens earned from daily pool
  UNIQUE(scout_id, season_id, date)
);

-- Weekly leaderboard
CREATE TABLE scout_leaderboard (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scout_id UUID REFERENCES scout_profiles(id),
  season_id UUID REFERENCES scout_seasons(id),
  week_number INTEGER NOT NULL,
  total_weighted_points NUMERIC(10,2) NOT NULL,
  rank INTEGER NOT NULL,
  weekly_pool_share NUMERIC(20,2) DEFAULT 0, -- tokens from weekly pool
  UNIQUE(scout_id, season_id, week_number)
);

-- Reward claims
CREATE TABLE scout_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scout_id UUID REFERENCES scout_profiles(id),
  season_id UUID REFERENCES scout_seasons(id),
  reward_type TEXT NOT NULL, -- 'daily', 'weekly'
  tokens_amount NUMERIC(20,2) NOT NULL,
  claim_status TEXT DEFAULT 'unclaimed', -- 'unclaimed', 'claimed', 'expired'
  hedgey_campaign_id TEXT, -- Hedgey claim campaign UUID
  claim_tx_hash TEXT,
  claimed_at TIMESTAMPTZ
);

-- Season metadata
CREATE TABLE scout_seasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_number INTEGER NOT NULL UNIQUE,
  name TEXT, -- 'S0: GP Test', 'S1: Public Launch'
  status TEXT DEFAULT 'upcoming', -- 'upcoming', 'active', 'settlement', 'completed'
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  pool_tokens NUMERIC(20,2) NOT NULL, -- total token allocation
  pool_remaining NUMERIC(20,2) NOT NULL,
  daily_pool_pct NUMERIC(5,2) DEFAULT 50.00,
  weekly_pool_pct NUMERIC(5,2) DEFAULT 50.00,
  multipliers_active BOOLEAN DEFAULT FALSE,
  parameters JSONB -- flexible store for tier thresholds, point values, etc.
);

-- Daily metrics snapshot (automated)
CREATE TABLE scout_daily_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_id UUID REFERENCES scout_seasons(id),
  date DATE NOT NULL UNIQUE,
  active_scouts INTEGER,
  total_submissions INTEGER,
  rejected_count INTEGER,
  db_save_count INTEGER,
  signal_count INTEGER,
  trade_count INTEGER,
  total_weighted_points NUMERIC(10,2),
  daily_pool_distributed NUMERIC(20,2),
  reward_per_point NUMERIC(10,4), -- dilution indicator
  new_signups INTEGER,
  cumulative_scouts INTEGER,
  fairvc_mentions INTEGER, -- from X API
  fairvc_followers INTEGER, -- from X API
  fair_price NUMERIC(12,8),
  fair_fdv NUMERIC(20,2)
);
```

---

## 6.3 Two Views: Admin vs Public

### Admin Dashboard (Team Only)

Accessible at `fair.xyz/admin/scout` (auth-gated to team wallets).

**Overview panel:**
- Season status: active / days remaining / pool status
- Today: active scouts, submissions, acceptance rate
- Trend: submissions/day sparkline, active scouts/day sparkline
- Alerts: any triggered conditions (see 6.5)

**Submissions feed:**
- Real-time feed of incoming submissions
- Each row: scout handle, tweet link, project, result, confidence score, points
- Filter by: result type, tier, date
- Click to expand: full evaluation reasoning

**Economics panel:**
- Buy pressure today / this season (from Dune)
- Sell pressure today / this season (from Dune)
- Net token impact
- Reward per point trend (dilution indicator)
- Pool utilization chart

**Scout management:**
- List of all scouts: wallet, handle, tier, submissions, acceptance rate, total points
- Sort/filter by any column
- Ban button (public phase only)
- Click scout → full submission history

**Leaderboard (internal view):**
- Same as public + sell pressure column + acceptance rate column

### Public Dashboard (Scouts + Anyone)

Accessible at `fair.xyz/scout`.

**My Profile (logged in scouts):**
- Tier, holdings, current points
- Submission history with results
- Tokens earned (claimable / claimed)
- Claim button (Hedgey integration)
- "You need X more FAIR for next tier" progression tracker

**Leaderboard:**
- Top scouts by weighted points this week
- Columns: rank, handle (optional — can be anonymous wallet), tier badge, points
- No financial details (no sell pressure, no exact token amounts for others)

**Season Info:**
- Days remaining
- Pool status (% distributed, bar chart)
- Total submissions / signals / trades this season
- "X scouts are competing this season"

**Signal Feed:**
- Scout-sourced signals that were published
- Each: project name, confidence level, scout attribution (if opted in), outcome
- No trade PNL details publicly

---

## 6.4 Processing Architecture

### Hourly Batch (Main Loop)

```
Every 60 minutes:

1. FETCH NEW MENTIONS
   X API → get @fairvc mentions since last check
   → Parse tweet content, extract project/token references
   → Match scout wallet via Privy (X handle → wallet)
   → Check tier (on-chain balance query)
   → Write to scout_submissions (status: 'pending')

2. EVALUATE
   For each pending submission:
   → Check duplicates (same project, already submitted by others?)
   → Check if project exists in DB (set project_existed flag)
   → Haiku triage: reject or pass? (~70-80% rejected here)
   → If passed: Sonnet deep evaluation → confidence score → result
   → Update scout_submissions with result, confidence, reasoning
   → If signal/trade level: push notification to team Telegram

3. CALCULATE POINTS
   For each evaluated submission:
   → base_points from result type (0/1/5/20)
   → weighted_points = base_points × tier_multiplier
   → Update scout_submissions
   → Update scout_points_daily (upsert for today)

4. UPDATE LEADERBOARD
   → Recalculate rankings from scout_points_daily
   → Update scout_leaderboard

5. SNAPSHOT
   → Write row to scout_daily_metrics (once per day, or update hourly)
   → Check alert conditions (Section 6.5)
```

### Daily Settlement

```
End of day (UTC midnight):

1. DAILY POOL DISTRIBUTION
   → Total weighted points today = SUM(scout_points_daily.weighted_points WHERE date = today)
   → Each scout's share = their weighted_points / total × daily_pool_allocation
   → Write to scout_rewards (reward_type: 'daily')
   → Update pool_remaining in scout_seasons

2. DAILY METRICS FINALIZATION
   → Finalize scout_daily_metrics row for today
   → Send daily digest to team Telegram bot
```

### Weekly Settlement

```
End of week:

1. WEEKLY LEADERBOARD PAYOUT
   → Rank scouts by total weighted_points for the week
   → Apply payout structure (25% / 18% / 13% / 10% / 10% / 4.8%×5)
   → Add any unused daily pool rollover
   → Write to scout_rewards (reward_type: 'weekly')

2. DEPLOY CLAIMS
   → Generate CSV: wallet, total_tokens (daily + weekly)
   → Upload to Hedgey API → create merkle tree → deploy claim campaign
   → Store hedgey_campaign_id in scout_rewards
   → Notify scouts: "your rewards are claimable"

3. WEEKLY REPORT
   → Auto-generate from scout_daily_metrics
   → Post leaderboard to @fairvc on X + Farcaster
```

---

## 6.5 Alerts (Telegram Bot)

### Alert Definitions

| Alert | Trigger | Severity | Message |
|-------|---------|----------|---------|
| Zero activity | 0 submissions in 6 hours during active season | ⚠️ Warning | "No submissions in 6h. Check if X API is working." |
| Spike activity | >5x average hourly submissions | ⚠️ Warning | "Submission spike: [n] in last hour (avg: [n]). Possible coordinated push." |
| Sybil pattern: same project | ≥5 different wallets submit same project within 15 min | 🔴 Alert | "Possible sybil: [n] wallets submitted [project] within 15 min." |
| Sybil pattern: identical text | ≥3 submissions with >80% text similarity | 🔴 Alert | "Copy-paste detected: [n] submissions with near-identical text." |
| Sybil pattern: new wallet spam | New scout (joined today) submits 5+ in first hour | ⚠️ Warning | "New scout [handle] submitted [n] times in first hour." |
| Reward dilution | Reward per weighted point drops below [threshold] | ℹ️ Info | "Reward dilution: [amount] tokens per point today (vs [amount] avg)." |
| Low engagement | Active scouts < 5 for 2 consecutive days | 🔴 Alert | "Active scouts dropped below 5 for 2 days. Consider intervention." |
| Trade-level signal | Scout submission reaches 80%+ confidence | ✅ Action | "Trade-level signal from @[handle]: [project]. Agent preparing memo. 5-min override window." |
| Signal publish | Scout submission triggered signal publish | ✅ Action | "Signal publishing from scout source: [project]. 5-min override window." |
| Season ending | 48h / 24h / 6h before season end | ℹ️ Info | "Season [n] ends in [time]. [n] scouts active, [n] tokens distributed." |

### Alert Routing

All alerts → team Telegram group (existing bot).

Trade-level and signal publish alerts → also push to you + Luke individually (higher urgency, override window).

---

## 6.6 On-Chain Monitoring (Dune)

### Queries Needed

| Query | What It Tracks | How |
|-------|---------------|-----|
| Scout buy pressure | FAIR token purchases by wallets in `scout_profiles` | Track transfers TO scout wallets on Uniswap/Aerodrome pools |
| Scout sell pressure | FAIR token sales by scout wallets | Track transfers FROM scout wallets to DEX routers |
| Claim activity | Scouts claiming rewards via Hedgey contracts | Track claim transactions on Hedgey contract |
| Post-claim behavior | What scouts do after claiming (hold / sell / tier up) | Track scout wallet balance changes after claim tx |
| Net scout impact | Buy pressure - sell pressure per day | Derived from above |

### Dashboard Layout (Dune)

**Public Dune dashboard** (link from scout dashboard):
- Season leaderboard (top 10)
- Total signals / trades from scouts
- Pool status

**Internal Dune dashboard** (team only):
- Buy/sell pressure charts (daily)
- Net token impact trend
- Post-claim sell rate (% of rewards sold within 24h / 7d)
- Scout wallet balance distribution (how many at each tier)

---

## 6.7 GP Test vs Public — What's Different

| Component | GP Test (S0) | Public (S1+) |
|-----------|-------------|-------------|
| **Admin dashboard** | Minimal: submissions feed + leaderboard + pool status | Full: all panels from 6.3 |
| **Public dashboard** | Not needed — GPs use admin view | Full scout dashboard (profile, leaderboard, claims, season info) |
| **Alerts** | Essential only: zero activity, trade-level signal, season ending | All alerts from 6.5 |
| **Dune queries** | Skip — 10 GPs, manual monitoring sufficient | Full on-chain monitoring |
| **Sybil detection** | Skip — GPs are known entities | Active: same project spam, copy-paste, new wallet spam |
| **Ban system** | Not needed | Available in admin dashboard |
| **Claim UI** | Can be manual (direct transfer or simple Hedgey link) | Embedded claim on site (Hedgey contracts + custom UI) |
| **Daily metrics cron** | Yes — needed for post-test analysis | Yes |
| **Submissions feed** | Yes — core feedback loop | Yes |
| **Points calculation** | Yes but flat (no multipliers) | Yes with tier multipliers |

### Build Priority for Test

Must build:
1. X API mention monitoring → `scout_submissions` table
2. Evaluation pipeline (Sonnet, confidence scoring, result assignment)
3. Points calculation (flat for test)
4. Basic admin view (submissions feed + leaderboard)
5. `scout_daily_metrics` cron job
6. Telegram alerts (trade-level signal + zero activity)

Can skip for test:
- Public dashboard
- Embedded claim UI (manual transfer to 10 GPs)
- Dune on-chain monitoring
- Sybil detection
- Ban system
- Tier multiplier logic

---

## 6.8 Implementation Effort Estimate

| Task | Effort | Priority | Needed For |
|------|--------|----------|-----------|
| Supabase schema (all tables) | 2-3h | P0 | Test |
| X API mention polling service | 4-6h | P0 | Test |
| Evaluation pipeline (parse → triage → deep eval) | 8-12h | P0 | Test |
| Points calculation engine | 3-4h | P0 | Test |
| Admin dashboard (basic: feed + leaderboard) | 6-8h | P0 | Test |
| Daily metrics cron job | 2h | P0 | Test |
| Telegram alert integration | 2-3h | P0 | Test |
| Privy auth integration | 4-6h | P1 | Public |
| Public scout dashboard | 12-16h | P1 | Public |
| Tier multiplier logic | 2h | P1 | Public |
| Hedgey claim integration (API + custom UI) | 8-12h | P1 | Public |
| Sybil detection rules | 4-6h | P1 | Public |
| Ban system (admin action) | 2h | P1 | Public |
| Dune queries + dashboards | 6-8h | P2 | Post-S1 |
| Post-season report script | 3-4h | P2 | Post-test |

**Total for test launch: ~27-38h dev time**
**Total for public launch (additional): ~32-44h dev time**
**Total for full system: ~59-82h dev time**

---

*Next section: Final Document Compilation →*
