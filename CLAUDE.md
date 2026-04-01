# Scout Game — Project Context

## What This Is

You are building the Scout Game for Fair (formerly FAIRCASTER) — an autonomous VC fund operating as a multi-agent system on Base blockchain. The scout game is a gamified alpha sourcing mechanic where community members ("scouts") tag `@fairvc` on X/Twitter with token signals, and Fair's AI Judgement Agent evaluates, scores, and acts on them.

## Fair Architecture (Reference)

Fair is structured as an orchestrating agent (MD) with sub-agents:
- **Fair MD** — orchestrator, investment decisions, portfolio management (Claude Sonnet 4)
- **Research Agent** — evaluates tokens, produces investment memos (BUY/PASS/WATCH)
- **Comms Agent** — drafts external content
- **Execution Agent** — fills trades
- **Judgement Agent** — NEW, what we're building

Infrastructure:
- **Database:** Supabase (projects: 3,090+, agent_memory: 2,700+, activity: 2.3M+ casts)
- **Agent runtime:** OpenClaw
- **Pipeline:** Farcaster casts → GPT-5 scoring → LangGraph orchestrator → Supabase
- **Trading:** PLAYBOOK frameworks (Metagame Theory, Attention Theory, Probabilistic Thinking, entry checklist)
- **Token:** $FAIR on Base, 100B supply, contract: `0x7d928816cc9c462dd7adef911de41535e444cb07`

## What We're Building

### Judgement Agent

An autonomous OpenClaw sub-agent that:
1. Monitors X for @fairvc mentions
2. Parses tweets, extracts signal + contract address
3. Pulls token metrics snapshot (±60 sec from tag)
4. Checks against Fair's existing database
5. Evaluates quality of the signal
6. Scores the token (0-10)
7. Takes action based on score
8. Replies publicly on X within 5 minutes
9. Learns from outcomes over time

### Full Pipeline

```
Scout tags @fairvc on X (CA required in tweet)
    │
    ▼
[1] INTAKE (< 2 min)
    - Poll X API for @fairvc mentions (every 2-3 min)
    - Parse: extract CA, ticker, scout's thesis/commentary
    - If reply to someone's tweet: parse original tweet, credit to scout
    - Identify scout: wallet → tier → signal weight → reputation
    │
    ▼
[2] RULE-BASED FILTER (instant)
    - No CA in tweet? → reject, reply "include contract address"
    - Text < 20 chars besides CA and tag? → reject
    - Token not trading on DexScreener? → reject
    - Scout hit daily rate limit (5/day)? → reject
    - Duplicate: same CA already submitted in last 24h with no new info? → reject
    │
    ▼
[3] SNAPSHOT (instant)
    - Pull metrics via DexScreener/GeckoTerminal API:
      price, FDV, mcap, liquidity, 24h volume, holders count,
      24h price change, age of token
    - Store snapshot with timestamp (±60 sec from tag)
    - This is the "entry point" for measuring scout performance later
    │
    ▼
[4] DB CHECK
    - Query Supabase: is this CA in `projects` table?
      ├─ No → new project, proceed to evaluation
      └─ Yes → query `agent_memory` for existing intel
           ├─ Scout adds new info not in DB → proceed
           └─ No new info → reject (duplicate)
    │
    ▼
[5] QUICK JUDGE (LLM, ~$0.003, fast)
    - Single Claude call: "Is this a concrete investment thesis or noise?"
    - Evaluates THESIS QUALITY, not the token itself yet
    - Criteria (what makes a good submission):
      • Team/founder mention (named people, verifiable)
      • Utility description (what the token actually does)
      • Connection to known strong projects/protocols
      • On-chain insight (deployer wallet history, interesting txs)
      • Narrative fit (which meta does this ride?)
      • Timing value (is this BEFORE the run, not after?)
      • Specificity (verifiable claims vs "looks bullish bro")
      • Uniqueness (is this info already CT mainstream?)
    - Score 1-10 on thesis quality
    - Score < 4 → reject, no further processing
    │
    ▼
[6] DEEP ANALYSIS (token-analysis-skill, 6 steps)
    - Uses the token-analysis-skill framework:
      1. Founder / Dev — who, social graph, track record, activity
      2. Product — real or vaporware?
      3. Team — broader team, advisors, backers
      4. Market Structure — FDV, liquidity, holders, comps
      5. Narrative — live meta? who's talking?
      6. Decision — verdict, entry target, kill conditions
    - Cross-references with existing DB data (agent_memory)
    - Final token score 0-10
    │
    ▼
[7] FINAL SCORE CALCULATION
    Final Score = Token Score (from deep analysis)
    
    Signal Weight (affects processing priority + display):
      T1 (2M): base
      T2 (10M): enhanced  
      T3 (50M): high
      GP (250M): maximum
    
    Scout Reputation (per-season, affects future signal weight):
      New scout: 1.0x
      Grows/shrinks based on track record
      Resets each season
    │
    ▼
[8] ACTION
    ├─ Score < 4.0 → REJECTED. No save. Reply: "evaluated, doesn't meet threshold"
    ├─ Score 4.0-6.5 → DB SAVE. Save to projects + agent_memory. 1 base point.
    │   Reply: "signal received and saved to our database"
    ├─ Score 6.5-8.0 → SIGNAL. Push to team TG. 5-min override window. Publish signal.
    │   5 base points. Reply: "strong signal — publishing to our feed"
    └─ Score 8.0+ → TRADE CONSIDERATION. Push to team TG. 5-min override. 
        Research Agent gets memo for deep dive. 20 base points.
        Reply: "high conviction signal — our team is reviewing"
    │
    ▼
[9] RECORD
    - Write to scout_submissions: tweet, snapshot, score, reasoning, result, points
    - Update scout_points_daily
    - Update scout reputation data
    │
    ▼
[10] LEARN (ongoing, via MEMORY.md)
    - After trades close: record outcome (profit/loss)
    - Update patterns: "tokens with X characteristic → Y% win rate"
    - Adjust internal heuristics over seasons
    - MEMORY.md grows with each season's learnings
```

### X Reply Templates (Fair tone — lowercase, direct, compressed)

```
RECEIVED (all submissions):
"signal received. evaluating."

REJECTED (no CA):
"need a contract address to evaluate. tag us again with the CA."

REJECTED (low quality):
"evaluated [TICKER]. doesn't meet our threshold. keep scouting."

DB SAVE:
"[TICKER] — saved to our intel database. good find."

SIGNAL:
"[TICKER] — strong signal. publishing to feed. [brief reason]"

TRADE LEVEL:
"[TICKER] — high conviction signal. team reviewing for position."
```

## Reward Economics

### Model: Proportional Points

Pool splits proportionally by weighted points each day. No fixed token amounts.
- Daily pool (50% of season allocation ÷ days): split by weighted points earned that day
- Weekly pool (50% + unused daily): split by leaderboard rank
- Pool CANNOT drain early — proportional model caps daily spend
- More scouts = dilution per point. Fewer = concentration.

### Points Per Action

| Action    | Base | T1 (1.0x) | T2 (1.5x) | T3 (3.0x) | GP (5.0x) |
|-----------|------|-----------|-----------|-----------|-----------|
| Rejected  | 0    | 0         | 0         | 0         | 0         |
| DB save   | 1    | 1         | 1.5       | 3         | 5         |
| Signal    | 5    | 5         | 7.5       | 15        | 25        |
| Trade     | 20   | 20        | 30        | 60        | 100       |

### Tier Structure

| Tier   | Min Hold | Entry ($1.2M FDV) | Signal Weight | Multiplier |
|--------|----------|-------------------|---------------|------------|
| Tier 1 | 2M       | $24               | Base          | 1.0x       |
| Tier 2 | 10M      | $120              | Enhanced      | 1.5x       |
| Tier 3 | 50M      | $600              | High          | 3.0x       |
| GP     | 250M     | $3,000            | Maximum       | 5.0x       |

### Phases

- **S0 (GP test):** 1 week, 10 GPs, 1% supply pool (1B tokens), flat rewards, no multipliers
- **S1 (by application):** ~15 curated scouts, tiered multipliers
- **Future:** public with open tiers

## Key Decisions Already Made

- Proportional reward model (not fixed token amounts)
- CA required in tweet (no guessing)
- Official X API only (no third-party)
- Reply to scout within 5 minutes (public X reply from @fairvc)
- Claims via Hedgey audited contracts, claim UI on our own site
- Auth via Privy (X login + wallet connect)
- Supabase for all data storage (shared with main Fair infra)
- Team (2 people) controls all parameters, no DAO governance
- Continuous seasons, no gaps
- P&L-linked rewards PARKED (legal review needed)
- Earlyness multiplier, discovery bonus, streaks — all post-MVP
- AI agents as scouts — flagged for future, not MVP
- Rug detection — flagged for future (trusted scouts in closed test)
- Scout reputation resets per season
- Evaluation pipeline is the #1 priority technical workstream

## Tools & APIs Available

- **DexScreener API** (free, no key) — price, FDV, liquidity, volume, pairs
- **X API** (Basic $200/mo or Pro $5K/mo) — mentions, tweets, profiles, post replies
- **Grok** (already integrated as `grok-search` skill) — X data fallback
- **Supabase** — read/write to Fair's database (need URL + key from Luke)
- **Claude API** (Sonnet 4.5: $3/$15 per MTok) — evaluation LLM calls
- **Token Analysis Skill** (`token-analysis-skill` repo) — 6-step founder-first research framework
- **Telegram Bot** (existing) — team notifications
- **Hedgey Finance** — audited claim contracts on Base (for reward distribution)

## Project Structure

```
scout-game/
├── CLAUDE.md              ← you are here
├── docs/                  ← all planning documents
│   ├── scout_game_agent_integration.md
│   ├── scout_game_tech_stack_costs.md
│   ├── scout_game_outcomes_kpis.md
│   ├── scout_game_governance_retention.md
│   ├── scout_game_gtm.md
│   ├── scout_game_internal_tracking.md
│   ├── fair_scout_economics_v5.md
│   └── fair_scout_game_architecture.html   ← compiled presentation doc
├── skills/
│   └── token-analysis-skill/               ← cloned from CnxLuc/token-analysis-skill
├── agent/
│   ├── SOUL.md            ← Judgement Agent system prompt (to build)
│   ├── MEMORY.md          ← learnings, starts empty
│   └── config/            ← thresholds, scoring weights, templates
├── src/                   ← agent code (to build)
│   ├── intake/            ← X API polling, tweet parsing
│   ├── evaluation/        ← rule filter, quick judge, deep analysis
│   ├── scoring/           ← final score calculation, signal weight
│   ├── actions/           ← DB writes, signal publish, trade trigger, X reply
│   └── learning/          ← outcome tracking, MEMORY updates
├── tests/                 ← test cases for calibration
│   ├── good_signals.json  ← example tweets that SHOULD score high
│   ├── bad_signals.json   ← example tweets that SHOULD be rejected
│   └── edge_cases.json    ← tricky submissions
└── supabase/
    └── schema.sql         ← scout game tables (to deploy)
```

## What to Build First

Priority order:
1. **SOUL.md** — Judgement Agent system prompt with scoring criteria
2. **X API intake** — polling for @fairvc mentions, parsing tweets
3. **Rule-based filter** — instant reject for no CA, rate limits, etc.
4. **Snapshot module** — DexScreener API integration for token metrics
5. **DB check** — Supabase queries for existing projects/intel
6. **Quick judge** — LLM call for thesis quality assessment
7. **Deep analysis** — token-analysis-skill integration
8. **Score + action** — thresholds, DB writes, Telegram push, X reply
9. **Points engine** — daily/weekly proportional calculation
10. **Test cases** — calibrate with example tweets

## Open Items

- [ ] Get Supabase URL + key from Luke
- [ ] Confirm DexScreener API integration for snapshot module  
- [ ] Design evaluation prompt (SOUL.md) — this is the core work
- [ ] Create test tweet dataset for calibration
- [ ] Set up X API mention polling (confirm tier: Basic $200/mo)
- [ ] Rug detection approach for public phase (flagged for later)
- [ ] Scout reputation scoring formula (post-MVP, second iteration)
- [ ] Hold duration multiplier (flagged for S2+)

## Style & Communication

- Code: clean, documented, modular
- Fair tone (user-facing content): lowercase, spaced lines, declarative. "state change → meaning → impact → punchline"
- Internal docs: normal professional English
- Discussion with team: Russian
- Token prices: four zeros format (0.0000xxxx)
