# FAIR SCOUT GAME — Section 5: GTM Plan

---

## 5.1 Test Launch (GP Only)

### Timeline

| Day | Action |
|-----|--------|
| D-3 | Send brief doc to GPs via DM (1-pager: what it is, how to participate, what we're testing) |
| D-2 | Group chat message: "test starts in 2 days, read the doc, questions?" |
| D-1 | Optional 15-min call for anyone who wants walkthrough. Not mandatory — doc should be self-sufficient |
| D0 | Test goes live. First submission from team member to demonstrate flow |
| D0 | Pin message in GP chat: "game is live. tag @fairvc on X with alpha. here's how scoring works" |
| D1-D6 | Daily: post leaderboard update in GP chat. Flag interesting submissions. Quick feedback check |
| D7 | Season ends. Run analysis playbook (Section 3.7). Share results in GP chat |
| D8-D10 | Tune parameters based on feedback. Prep public launch |

### GP Brief Document (1-Pager)

Contents:
- What: you find alpha on X, tag @fairvc, agent evaluates, you earn $FAIR
- How: tag @fairvc in a tweet with a project/token you think is interesting. Add your own take (not just a link)
- Scoring: DB save = 1pt, Signal = 5pt, Trade = 20pt. No multipliers for test — flat rewards
- Pool: 1B tokens (1% supply) for 1 week
- Rules: max 5 submissions/day. No copy-paste templates. Your own analysis in your own words
- What NOT to do: don't spam, don't submit obvious scams, don't coordinate submissions with others
- Feedback: tell us what's broken, confusing, or stupid. That's the whole point of the test

**Tone:** Fair voice. Lowercase, direct, compressed. Not a corporate memo.

### GP Onboarding Flow

```
GP has 250M+ $FAIR (already) 
  → receives DM with brief doc
  → connects wallet on fair.xyz (Privy — X login + wallet)
  → sees scout dashboard: tier = GP, points = 0, pool status
  → goes to X, finds alpha, tags @fairvc
  → within 1 hour: notification with result (rejected/saved/signal/trade)
  → points appear on dashboard
  → end of day: daily pool share calculated
  → end of week: leaderboard payout + claim available
```

---

## 5.2 Public Launch

### Pre-Launch (D-7 to D-1)

**Content sequence:**

| Day | Channel | Content | Purpose |
|-----|---------|---------|---------|
| D-7 | Farcaster + X | Teaser: "we've been testing something with our GPs. results were interesting." | Curiosity |
| D-5 | Farcaster + X | GP test results post: X submissions, Y signals, Z trades. "scouts found alpha our pipeline missed." | Proof it works |
| D-3 | Farcaster + X | Announcement: "the scout game is going public. hold $FAIR, tag @fairvc, earn rewards." with explainer thread | Core launch message |
| D-3 | Farcaster + X | How-to thread: tier structure, point system, how to participate, link to dashboard | Education |
| D-2 | Farcaster + X | "Leaderboard preview — top scouts earn [amount]. season starts in 48h" | Incentive + urgency |
| D-1 | Farcaster + X | Final reminder + countdown. "Tomorrow. Hold $FAIR. Find alpha. Get paid." | Hype |

**Key message (compressed, Fair tone):**

```
scout game is live

hold $FAIR → find alpha on X → tag @fairvc → agent evaluates → earn rewards

4 tiers: 2M / 10M / 50M / 250M
higher hold = bigger multiplier = more rewards

season 1: 2 weeks. 1B token pool.

the agent is watching. show us what you've got.
```

### Launch Day (D0)

| Time | Action |
|------|--------|
| Morning | "Season 1 is live" post on Farcaster + X |
| Morning | Pin tweet with rules + dashboard link |
| +1h | First submission from a GP or team member (seed the mechanic, show others how it's done) |
| +3h | First leaderboard snapshot: "3 hours in, X scouts, Y submissions. [top scout handle] is leading" |
| End of day | Daily recap: submissions, signals published, leaderboard standings |

### First Week Cadence

| Content | Frequency | Channel |
|---------|-----------|---------|
| Leaderboard update | Daily | Farcaster + X |
| "Signal of the day" (best scout submission → published signal) | Daily (if material) | Farcaster + X |
| Scout spotlight (profile a top scout — with permission) | 2-3x per week | Farcaster + X |
| Trade alert (if agent trades from scout signal) | Real-time | Farcaster + X |
| Mid-season stats | Once (day 7) | Farcaster + X |

The trade alert is the killer content. "Scout @handle submitted $TOKEN at $X FDV → agent evaluated → confidence 85% → trade executed → currently +40%." This is the moment that makes people want to join.

---

## 5.3 Growth Levers

### Organic Growth Drivers

**1. Winning trades = best marketing**

When a scout-sourced trade hits, post it publicly. The before/after is the content:
- "Scout @handle tagged us on $TOKEN 3 days ago"
- "Agent evaluated: 82% confidence"
- "Entry: $X FDV. Current: $Y FDV. +Z%"
- "This is what the scout game does."

No amount of announcement threads beats a real winning trade with a clear scout attribution.

**2. Leaderboard as content**

Weekly leaderboard posts create:
- Competition (scouts share their ranking)
- Social proof (handles visible = real people earning)
- FOMO ("that guy earned $X this week from tagging @fairvc?")

**3. The "tag @fairvc" meme**

The goal: whenever someone finds alpha on CT, someone in the replies says "tag @fairvc." This happens organically IF:
- People see that tagging works (signals get published, trades happen)
- There's a financial incentive (rewards)
- It becomes cultural (first few scouts doing it consistently seeds the behavior)

This can't be forced. It grows from visible, repeated proof that the mechanic works.

**4. Scout-as-identity**

"I'm a Fair scout" becomes a bio line. Badges, tier status, track record — all contribute to making scouting part of someone's on-chain identity. This is longer-term but the foundation is in the reputation system.

---

## 5.4 Scout Acquisition Funnel

```
AWARENESS
│ CT user sees @fairvc signal or winning trade post
│ or: sees friend tagged @fairvc and earned rewards
│ or: sees leaderboard post with earnings
│
▼
INTEREST
│ Checks dashboard / reads how-to thread
│ Sees: tier structure, reward math, current leaderboard
│ Calculates: "if I buy 2M FAIR ($24) and submit 3 good signals..."
│
▼
DECISION
│ Cost: $24 (Tier 1) to $3,000 (GP) in $FAIR
│ Friction: buy $FAIR on Base → connect wallet → start submitting
│ Incentive: potential $60+ per published signal, leaderboard prizes
│
▼
ACTION
│ Buys $FAIR → connects on dashboard → first submission
│
▼
RETENTION
│ Gets first result (accepted or rejected)
│ If accepted: sees points, leaderboard position → motivated to continue
│ If rejected: needs to understand why → feedback quality matters
│ Tier progression incentive: hold rewards → tier up → earn more next season
│
▼
ADVOCACY
│ Top scouts share their results ("earned X this week scouting for @fairvc")
│ Becomes organic marketing → new scouts enter at top of funnel
```

### Friction Points to Watch

| Friction | Impact | Mitigation |
|---------|--------|-----------|
| Buying $FAIR on Base | High — many CT users aren't on Base yet | Clear guide: "how to buy $FAIR in 3 steps." Link to bridge + DEX |
| Connecting wallet + X account | Medium — Privy makes this smooth but it's still a step | One-click flow, test thoroughly before launch |
| First submission rejected | High — scout's first experience is negative | Fast, clear feedback: "rejected because [reason]. Try: [suggestion]" |
| No feedback for hours | Medium — scout submits and hears nothing | Instant "received" confirmation. Result within 1 hour |
| Leaderboard dominated by whales | Medium — T1 scout sees GP earning 5x and feels outmatched | Highlight Tier 1 success stories. Show that quality beats size |

---

## 5.5 Launch Checklist

### Must Have (Before Test)

- [ ] Scout dashboard live on Terminal (profile, leaderboard, pool status)
- [ ] Privy auth working (X login + wallet connect)
- [ ] X API mention monitoring active
- [ ] Evaluation pipeline working (submission → score → result)
- [ ] Points calculation running (daily pool split)
- [ ] Hedgey claim campaign ready to deploy
- [ ] GP brief document written (Fair tone)
- [ ] `scout_daily_metrics` cron job running
- [ ] `source_type` field added to signal/trade tables
- [ ] Baseline snapshot taken
- [ ] Team member test submission (end-to-end flow verified)

### Must Have (Before Public)

- [ ] Everything from test checklist ✅
- [ ] Tier system active (4 tiers with multipliers)
- [ ] Weekly leaderboard calculation working
- [ ] Claim UI embedded on site (Hedgey contracts + custom frontend)
- [ ] How-to thread drafted and reviewed
- [ ] Announcement content ready (teaser, results, launch, how-to)
- [ ] Leaderboard public view (non-scouts can see)
- [ ] Feedback mechanism (how scouts report issues)
- [ ] Rate limit enforcement (max submissions/day)
- [ ] Duplicate detection (same project, multiple scouts)
- [ ] Anti-spam rules documented and communicated

### Nice to Have (S1, not blocking)

- [ ] "Signal of the day" auto-post
- [ ] Scout profile pages (public, shareable)
- [ ] Tier progression tracker ("you need X more FAIR for next tier")
- [ ] Push notifications (Telegram bot for result alerts)
- [ ] Season countdown on dashboard

---

*Next section: Internal Tracking System Design →*
