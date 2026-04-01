# FAIR SCOUT GAME — Section 2: Tech Stack & Costs

---

## 2.1 Authentication: X Login + Wallet Connect

### Requirement

Scouts need to link their X (Twitter) account with their Base wallet. This proves:
- **Identity:** who is submitting (X handle)
- **Eligibility:** wallet holds minimum $FAIR for their tier
- **Tier:** wallet balance determines signal weight + reward multiplier

### Privy (Primary Recommendation)

Privy is already in the Fair ecosystem (used for OpenClaw agent wallets). Now owned by Stripe (acquired June 2025).

**What it does for us:**
- Social login (X/Twitter) + wallet connection in single flow
- Embedded wallets on Base for users who don't have one
- SOC 2 Type II certified, Consensys-audited
- React SDK — drops into existing Next.js Terminal Dashboard

**Pricing:**

| Tier | Cost | MAU Limit | Notes |
|------|------|-----------|-------|
| Developer (Free) | $0 | 0-499 MAU | Enough for GP test (10 users) |
| Core | $299/mo | 500-2,499 MAU | Covers public Season 1 (50-200 scouts) |
| Scale | $499/mo | 2,500-9,999 MAU | Growth phase |
| Enterprise | Custom | 10K+ | Signature-based pricing as low as $0.001/sig |

**For Scout Game scenarios:**
- Test phase (10 GPs): **$0** — free tier covers it
- Public S1 (50-200 scouts): **$299/mo** — Core tier
- Scale (500-1,000 scouts): **$499/mo** — Scale tier

**Post-acquisition concern:** Privy is now Stripe-owned. Potential for ecosystem lock-in. Stripe integration is a plus if we ever need fiat onramps, but adds dependency.

### Alternatives Evaluated

| Provider | Pricing | Pros | Cons | Status |
|----------|---------|------|------|--------|
| **Openfort** | Usage-based, free up to 1K MAU | Open-source (OpenSigner), native smart accounts, sub-100ms signing, no vendor lock-in | Smaller ecosystem, less name recognition | Best alternative if Privy lock-in concerns grow |
| **Turnkey** | $0.10/sig (free first 25), Pro discounts to $0.01/sig | Fastest TEE signing (50-100ms), built by ex-Coinbase Custody team, very programmable | Low-level — requires more engineering to build auth flow. No social login out of box | Good for agent wallets, overkill for scout onboarding |
| **Dynamic** | $200/mo for 2.5K MAU, $500/mo for 10K | Beautiful plug-and-play UI, 500+ wallet support | Acquired by Fireblocks (2025) — enterprise pivot likely, less indie-friendly | Pass — strategic uncertainty |
| **Thirdweb** | Free tier + usage-based | All-in-one (wallets + contracts + SDKs), self-hostable Engine | Can feel bloated for single-purpose auth, more opinionated stack | Worth considering if we also use their contract infra |
| **Web3Auth** | Free tier, paid from $149/mo | MPC social login pioneer | Acquired by MetaMask/Consensys — same lock-in concerns as Privy | Pass |

**Recommendation:** Start with Privy (free tier → Core). If vendor lock-in becomes a concern, Openfort is the cleanest migration path. Flag for re-evaluation after 6 months.

---

## 2.2 X API: Mention Monitoring & Cost Model

### What We Need

1. **Read mentions** of @fairvc — detect when scouts tag us
2. **Read tagged tweet content** — extract the signal (token, project, scout commentary)
3. **Read scout profile** — basic account info for anti-sybil checks
4. **Write responses** (optional) — confirm receipt, notify reward

### Current Setup

Fair already uses X API (via `x-research` skill) and Grok for X/Twitter data. The scout game adds a specific new pattern: real-time mention monitoring.

### Official X API Pricing (as of Feb 2026)

| Tier | Cost/mo | Read Limit | Write Limit | Search | Mention Monitoring |
|------|---------|-----------|-------------|--------|--------------------|
| Free | $0 | ~1 req/15min | 500 posts/mo | None | Impractical |
| Basic | $200 | 15,000 tweets/mo | 50,000 posts/mo | 7-day window | Viable for test |
| Pro | $5,000 | 1M tweets/mo | 300,000 posts/mo | Full archive | Comfortable at scale |
| Enterprise | $42,000+ | Custom | Custom | Full archive | Overkill unless 10K+ scouts |

**New: Pay-as-you-go (Feb 2026).** X launched consumption-based billing alongside fixed tiers. Closed beta expanded — developers pay per operation type. $500 voucher for beta participants. Auto top-up and spending caps available.

### Usage Model by Scout Count

**Assumptions per scout per day:**
- 1-3 submissions (mentions to read)
- Each submission = 1 mention read + 1 tweet content read + 1 profile check = ~3 API calls
- Agent response per accepted submission = 1 write call
- Acceptance rate: ~25% (from economics doc)

| Scouts | Mentions/day | API calls/day | API calls/month | Best Tier | Monthly Cost |
|--------|-------------|--------------|----------------|-----------|-------------|
| 10 (GP test) | 10-30 | 30-90 | 900-2,700 | Basic | **$200** |
| 50 | 50-150 | 150-450 | 4,500-13,500 | Basic | **$200** |
| 100 | 100-300 | 300-900 | 9,000-27,000 | Basic (tight) / Pay-as-you-go | **$200-400** |
| 200 | 200-600 | 600-1,800 | 18,000-54,000 | Pro or Pay-as-you-go | **$500-5,000** |
| 500 | 500-1,500 | 1,500-4,500 | 45,000-135,000 | Pro | **$5,000** |
| 1,000 | 1,000-3,000 | 3,000-9,000 | 90,000-270,000 | Pro | **$5,000** |

### Third-Party X API Alternatives

The $200 → $5,000 gap between Basic and Pro is brutal. Alternatives exist:

| Provider | Pricing | Coverage | Risk |
|----------|---------|----------|------|
| **TwitterAPI.io** | Pay-as-you-go, ~96% cheaper than official | Real-time tweets, profiles, search | ToS grey area, no official SLA |
| **Netrows** | $49/mo (10K credits), 26 X endpoints | Profiles, tweets, followers, engagement | Newer provider, test reliability first |
| **TweetAPI** | $17-197/mo (100K-2M requests) | Public tweet data | Third-party infrastructure, no write access |
| **Xpoz** | $20/mo for 1M results | Multi-platform (X, IG, TikTok, Reddit) | AI-native query interface, good for research |

**Recommendation for Scout Game:**
- **Test phase:** Official Basic ($200/mo). No risk, stable, sufficient volume.
- **Public S1 (50-100 scouts):** Official Basic still works. Monitor utilization.
- **If crossing 100+ scouts:** Evaluate pay-as-you-go pricing. If costs jump toward $5K, test TwitterAPI.io or Netrows as read-only supplement (official API for writes).
- **Architecture:** Abstract the X API layer (as noted in risks doc) so swapping providers is a config change, not a rewrite.

### Grok as Fallback

Already integrated (`grok-search` skill). Use for supplementary data when X API is rate-limited or for enrichment queries that don't need real-time. No additional cost if already on an X Premium subscription.

---

## 2.3 AI Evaluation Costs

### Per-Submission Cost Model

Each scout submission triggers an AI evaluation. The agent needs to:
1. Parse the tweet and extract signal
2. Check against existing DB (Supabase query — negligible cost)
3. Evaluate quality, assign confidence score
4. If signal/trade level: produce structured memo

**Model choice:** Claude Sonnet 4.5 (or 4.6) — same as Research Agent. Already in the stack.

**Current API pricing (Claude Sonnet 4.5):**
- Input: $3 / million tokens
- Output: $15 / million tokens
- With prompt caching: 90% savings on cached context (system prompt, PLAYBOOK, etc.)

### Token Estimates Per Evaluation

| Component | Input Tokens | Output Tokens | Notes |
|-----------|-------------|---------------|-------|
| System prompt + PLAYBOOK | ~4,000 | — | Cached after first call (cost: ~$0.0004/eval) |
| Tweet content + scout data | ~500 | — | Variable per submission |
| DB context (existing project data) | ~1,000 | — | Pulled from Supabase, injected into prompt |
| Evaluation reasoning + decision | — | ~800 | Quick reject, DB save, or signal assessment |
| **Full investment memo (trade-level only)** | ~2,000 more | ~3,000 | Only for 80%+ confidence (~5% of submissions) |

**Cost per evaluation type:**

| Evaluation Result | Input Tokens | Output Tokens | Cost (with caching) | % of Submissions |
|-------------------|-------------|---------------|--------------------|-----------------:|
| Quick reject | ~5,500 | ~200 | **~$0.004** | 70-80% |
| DB save | ~5,500 | ~800 | **~$0.013** | 15-20% |
| Signal publish | ~5,500 | ~1,500 | **~$0.024** | 3-5% |
| Trade memo | ~7,500 | ~4,000 | **~$0.065** | 1-3% |

**Weighted average cost per submission: ~$0.008** (heavily weighted toward rejects)

### Monthly AI Cost by Scout Count

| Scouts | Submissions/day | Submissions/month | Avg Cost/Sub | Monthly AI Cost |
|--------|----------------|-------------------|-------------|----------------|
| 10 (GP test) | 20-40 | 140-280 | $0.008 | **$1-2** |
| 50 | 75-200 | 2,100-5,600 | $0.008 | **$17-45** |
| 100 | 150-400 | 4,200-11,200 | $0.008 | **$34-90** |
| 200 | 300-800 | 8,400-22,400 | $0.008 | **$67-179** |
| 500 | 750-2,000 | 21,000-56,000 | $0.008 | **$168-448** |
| 1,000 | 1,500-4,000 | 42,000-112,000 | $0.008 | **$336-896** |

**Prompt caching is critical.** The PLAYBOOK + system prompt (~4K tokens) is the same for every evaluation. With 5-minute cache TTL, at 50+ scouts submitting throughout the day, cache hit rate should be 90%+. Without caching, costs are ~10x higher.

**Batch processing option:** If evaluations run every 30-60 minutes (as suggested in Section 1), batch API gives 50% discount. Combined with caching: further reduction.

**Optimization note:** Use Haiku 4.5 ($1/$5 per MTok) for initial triage (reject/pass-through) and Sonnet only for deeper evaluation. This could cut costs by ~60% since most submissions are rejects.

**Two-tier model (optimized):**

| Stage | Model | Cost/eval | When |
|-------|-------|-----------|------|
| Triage (reject/pass) | Claude Haiku 4.5 | ~$0.001 | Every submission |
| Deep evaluation | Claude Sonnet 4.5 | ~$0.02-0.065 | Only passed triage (~25%) |
| **Blended average** | — | **~$0.005** | — |

With two-tier model, 1,000 scouts = **$210-560/mo** in AI costs.

---

## 2.4 On-Chain: Reward Distribution & Smart Contracts

### Requirements

- Distribute $FAIR token rewards to scout wallets
- Daily pool payouts + weekly leaderboard payouts
- Scouts pay their own gas (Base L2 — cheap)
- Contracts must be audited, battle-tested, production-ready

### Approach: Claim-Based Distribution (Not Push)

**Critical design choice:** Don't push rewards to scouts. Let them claim.

**Why:**
- Push model = we pay gas for every payout. 50 scouts × 7 daily payouts × 2 weekly = hundreds of transactions per season. Even on Base (~$0.001/tx), the operational overhead and failure handling is significant
- Claim model = we publish merkle root on-chain. Scouts claim when they want. They pay gas. Single transaction per scout per claim
- Standard pattern: airdrop merkle trees. Well-audited, widely used

### Smart Contract Options (Audited, Ready-to-Deploy)

| Solution | What It Does | Audit Status | Base Support | Fit |
|----------|-------------|-------------|-------------|-----|
| **Hedgey Finance** | Token claims, vesting, lockups, airdrops ("Airstreams") | Consensys Diligence, 5+ audits | Yes (Base supported) | **Best fit** — already used in FAIR ecosystem for token locks |
| **Sablier** | Token streaming, vesting, airdrops | Multiple audits, battle-tested | Yes | Good for streaming rewards, but overkill for lump-sum claims |
| **Thirdweb Airdrop** | Merkle tree airdrops, claim pages | Audited, widely deployed | Yes | Simple airdrop, less flexibility for recurring seasons |
| **OpenZeppelin Merkle Distributor** | Basic merkle proof claims | Gold standard audit | Any EVM | Minimal, requires custom frontend. Good as building block |
| **Custom contract** | Whatever we want | Needs new audit ($5K-50K+) | — | **Avoid** — unnecessary risk and cost |

### Recommendation: Hedgey Finance

Already in the ecosystem. Supports:
- **Airstreams:** Batch token distribution with optional vesting/streaming
- **Claim pages:** Self-service, scouts claim their rewards
- **Batch operations:** Upload CSV of recipients + amounts, deploy claim
- **No-code UI:** Admin dashboard for managing distributions

**Workflow:**
```
End of day → Calculate points → Generate recipient list (wallet, amount)
         → Upload to Hedgey → Deploy claim contract
         → Scouts claim from dashboard or Hedgey UI
         → Repeat weekly for leaderboard payouts
```

**Gas costs (Base L2):**
- Deploy claim contract: ~$0.01-0.05
- Each scout claim: ~$0.001-0.005 (paid by scout)
- Admin uploads: negligible

**Our cost per season:** Essentially **$0** in gas (scouts pay claims). Hedgey platform is free to use (self-service).

### ⚠️ Open Question (Flag for Team)

The existing Supabase database structure and Hedgey integration need to be confirmed with the dev team. Questions:
- Does FAIR already have a Hedgey integration for the GP token locks?
- Can we reuse the same Hedgey setup for scout rewards, or do we need separate claim contracts?
- Who manages the Hedgey admin (multi-sig? single operator?)

---

## 2.5 Data Storage: Supabase

### Current State

Fair already runs on Supabase with these tables:
- `activity` — 2.3M+ Farcaster casts
- `projects` — 3,090+ discovered projects
- `agent_memory` — 2,700+ intelligence entries
- `high_signal_users` — 5,000+ curated users
- `communication_alerts`
- `research_assessments`

### New Tables for Scout Game

| Table | Purpose | Estimated Rows (S1) | Growth Rate |
|-------|---------|---------------------|-------------|
| `scout_profiles` | Wallet, X handle, tier, join date, total points, season stats | 50-200 | Per new scout |
| `scout_submissions` | Each submission: scout, tweet, project ref, timestamp, evaluation result, points | 5,000-20,000 per season | ~100-500/day at scale |
| `scout_points_daily` | Daily point snapshots per scout | 700-2,800 per season | Scouts × days |
| `scout_leaderboard` | Weekly rankings, payout amounts | 50-200 per week | Per scout per week |
| `scout_rewards` | Claim records: wallet, amount, claim tx, status | 200-800 per season | Per payout event |
| `scout_seasons` | Season metadata: dates, pool size, parameters, status | 1-2 | Per season |

### Storage Impact

The scout game tables are lightweight — mostly text, integers, and foreign keys. Conservative estimate:
- S1 (2 weeks, 200 scouts): ~50MB additional data
- After 1 year (12+ seasons): ~500MB-1GB

### Supabase Pricing

| Plan | Cost/mo | DB Storage | MAU (Auth) | Egress | Notes |
|------|---------|-----------|------------|--------|-------|
| Free | $0 | 500MB | 50K | 5GB | Pauses after 7d inactivity — **not for production** |
| Pro | $25/mo | 8GB | 100K | 50GB | + usage-based overages |
| Team | $599/mo | 8GB | 100K | 50GB | SSO, audit logs, team features |

**Fair is almost certainly already on Pro ($25/mo).** The scout game tables fit easily within existing storage. No tier upgrade needed.

**Additional costs if scaling:**
- Extra MAU (if using Supabase Auth): $0.00325 per user above 100K — irrelevant for scout game
- Extra storage: $0.125/GB — negligible
- Extra egress: $0.09/GB beyond 50GB — only relevant if dashboard gets heavy traffic

**Scout game incremental Supabase cost: ~$0/mo** (fits within existing Pro plan)

### ⚠️ Open Question (Flag for Team)

Adding tables to the existing Supabase instance needs dev team sign-off. Considerations:
- Row-level security policies for scout data
- Read replicas if leaderboard queries impact pipeline performance
- Backup strategy for reward calculations (financial data)

---

## 2.6 Frontend: Scout Dashboard

### Test Phase (MVP)

Minimal dashboard added to existing Terminal Dashboard (Next.js on Vercel):
- **My Profile:** Tier, wallet, current points, submission history
- **Leaderboard:** Current season rankings
- **Pool Status:** Remaining rewards, days left

This is a few pages added to an existing app. No new infrastructure.

### Public Phase

Full scout experience:
- Real-time leaderboard with animations
- Submission feed (what scouts are finding)
- Tier progression tracker
- Reward claim interface (link to Hedgey or embedded)
- Season history and stats
- Scout profiles (public, opt-in)

### Vercel Hosting

| Plan | Cost/mo | Includes | Notes |
|------|---------|----------|-------|
| Hobby (Free) | $0 | 100GB bandwidth, 1M function calls | Non-commercial only — **not suitable** |
| Pro | $20/user/mo | 1TB bandwidth, 10M function calls, $20 usage credit | **Required for commercial use** |

**Fair Terminal Dashboard is already on Vercel.** The scout dashboard is an addition to the same deployment.

**Incremental cost:** Likely **$0** if already on Vercel Pro. Additional bandwidth from scout traffic (50-200 users checking leaderboard) is minimal — well within existing quotas.

**If separate deployment needed:** $20/mo for one Pro seat.

---

## 2.7 Total Cost Model

### Scenario A: GP Test Phase (1 week, 10 scouts)

| Component | Monthly Cost | Notes |
|-----------|-------------|-------|
| Privy (auth) | $0 | Free tier (10 MAU) |
| X API (Basic) | $200 | Already subscribed? Then $0 incremental |
| AI evaluation | $1-2 | ~280 submissions, mostly rejects |
| Supabase | $0 | Existing Pro plan |
| Vercel | $0 | Existing deployment |
| Smart contracts (Hedgey) | $0 | Self-service, scouts pay gas |
| **TOTAL** | **$200-202** | Effectively $0-2 if X API already active |

### Scenario B: Public Season 1 (2 weeks, 50 scouts)

| Component | Monthly Cost | Notes |
|-----------|-------------|-------|
| Privy (auth) | $0-299 | Free if <500 MAU, Core if over |
| X API (Basic) | $200 | Sufficient at 50 scouts |
| AI evaluation | $17-45 | ~2K-5.6K submissions |
| Supabase | $0 | Existing plan |
| Vercel | $0 | Existing deployment |
| Smart contracts | $0 | Hedgey self-service |
| **TOTAL** | **$217-544/mo** | |

### Scenario C: Public Season (2 weeks, 200 scouts)

| Component | Monthly Cost | Notes |
|-----------|-------------|-------|
| Privy (auth) | $299 | Core tier |
| X API | $200-400 | Basic might be tight; pay-as-you-go as backup |
| AI evaluation | $67-179 | ~8K-22K submissions |
| Supabase | $0-25 | May need usage-based overages |
| Vercel | $0-20 | Traffic increase might require separate project |
| Smart contracts | $0 | Hedgey |
| **TOTAL** | **$566-923/mo** | |

### Scenario D: Growth Phase (ongoing, 500 scouts)

| Component | Monthly Cost | Notes |
|-----------|-------------|-------|
| Privy (auth) | $499 | Scale tier |
| X API | $5,000 | Pro tier required |
| AI evaluation (optimized two-tier) | $168-448 | Haiku triage + Sonnet deep eval |
| Supabase | $25-50 | Possible compute upgrade |
| Vercel | $20-40 | Additional bandwidth |
| Smart contracts | $0 | Hedgey |
| **TOTAL** | **$5,712-6,037/mo** | X API dominates costs |

### Scenario E: Full Scale (1,000+ scouts)

| Component | Monthly Cost | Notes |
|-----------|-------------|-------|
| Privy (auth) | $499-Custom | Scale or Enterprise |
| X API | $5,000 | Pro tier (still within 1M tweets) |
| AI evaluation (optimized) | $210-560 | Two-tier with batching |
| Supabase | $50-100 | Compute + storage growth |
| Vercel | $40-100 | Bandwidth scaling |
| Smart contracts | $0 | Hedgey |
| Monitoring/alerting tools | $50-100 | Sybil detection, pool monitoring |
| **TOTAL** | **$5,849-6,359/mo** | |

---

## 2.8 Cost Sensitivity Analysis

### What Drives Costs at Each Stage

```
Test (10 scouts):     X API ██████████████████████████████████████████ 99%
                      AI    █ 1%

Public (50 scouts):   X API ██████████████████████████████████ 68%
                      Privy ████████████████ 32% (if Core tier triggered)
                      AI    ██ ~5%

Growth (500 scouts):  X API █████████████████████████████████████████████████ 83%
                      Privy ████████ 8%
                      AI    ██████ 7%

Scale (1000 scouts):  X API █████████████████████████████████████████████████ 80%
                      Privy ████████ 8%
                      AI    ██████ 9%
```

**X API is the dominant cost at every stage.** This validates the risks doc recommendation: abstract the API layer for provider swaps.

### Break-Even Analysis vs. Reward Pool

| Scenario | Infra Cost/Season | Reward Pool Value ($1.2M FDV) | Infra as % of Rewards |
|----------|------------------|-------------------------------|----------------------|
| Test (1 week) | ~$50 | $12,000 | 0.4% |
| Public S1 (2 weeks) | ~$400 | $12,000 | 3.3% |
| 200 scouts (2 weeks) | ~$700 | $12,000 | 5.8% |
| 500 scouts (monthly) | ~$6,000 | $12,000 | 50% ⚠️ |

**At 500+ scouts, infra costs eat 50% of reward pool value (at $1.2M FDV).** This is manageable only if:
- FDV grows (at $6M, infra is 10% of pool — healthy)
- Third-party X API alternatives reduce the $5K/mo line item
- Pay-as-you-go X API pricing proves cheaper than fixed Pro tier

### Cost Optimization Roadmap

| Phase | Optimization | Savings |
|-------|-------------|---------|
| Now | Use prompt caching for AI evaluations | 90% on cached tokens |
| S1 | Two-tier evaluation (Haiku triage + Sonnet deep) | ~60% AI cost reduction |
| S2 | Evaluate X API pay-as-you-go vs Basic | Up to 50% if usage < 15K tweets |
| S3 | Test third-party X APIs (TwitterAPI.io, Netrows) for read-only | Up to 96% on read costs |
| S4 | Batch API for non-urgent evaluations | 50% discount on AI |
| Future | Self-hosted LLM for triage (reject/pass) | Eliminate Haiku costs |

---

## 2.9 Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                     SCOUT FRONTEND                          │
│              (Next.js on Vercel, added to Terminal)          │
│   Dashboard · Leaderboard · Profile · Claim Interface       │
└────────────────────────┬────────────────────────────────────┘
                         │
                    Privy Auth
              (X login + wallet connect)
                         │
┌────────────────────────┴────────────────────────────────────┐
│                     BACKEND SERVICES                         │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │  X API Layer  │    │  Evaluation   │    │   Rewards     │  │
│  │  (abstracted) │    │   Engine      │    │   Engine      │  │
│  │               │    │               │    │               │  │
│  │ Official API  │    │ Haiku triage  │    │ Points calc   │  │
│  │ + fallback to │    │ Sonnet deep   │    │ Daily/weekly  │  │
│  │ 3rd party     │    │ eval          │    │ pool split    │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬────────┘  │
│         │                   │                    │           │
│         └───────────────────┴────────────────────┘           │
│                             │                                │
│                     ┌───────┴───────┐                        │
│                     │   Supabase    │                        │
│                     │   (existing)  │                        │
│                     │               │                        │
│                     │ + scout_*     │                        │
│                     │   tables      │                        │
│                     └───────────────┘                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                         │
                    ┌────┴─────┐
                    │  Hedgey  │
                    │ (claims) │
                    │  on Base │
                    └──────────┘
```

---

*Next section: Outcomes, KPIs & What Success Looks Like →*
