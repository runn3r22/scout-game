# FAIR SCOUT GAME — Section 1: Agent Integration

---

## 1.1 How Scout Submissions Enter the Existing Pipeline

### Current State (without Scout Game)

Fair's intelligence pipeline today:

```
Farcaster casts (5K users) → GPT-5 relevance scoring → LangGraph orchestrator → Supabase
                                                         ├─ Project Discovery Agent (new projects → `projects` table)
                                                         ├─ Intelligence Extraction Agent (updates → `agent_memory` table)
                                                         ├─ Investment Analyst Agent v3 (research assessments)
                                                         └─ Communication Agent (Telegram alerts)
```

Separate from the pipeline: Research Agent (Claude) evaluates tokens through PLAYBOOK frameworks → produces structured investment memos (BUY / PASS / WATCH) → Fair MD approves → Execution Agent fills.

### With Scout Game

Scout submissions create a **new input channel** into the same system. The pipeline becomes:

```
INPUT LAYER
├─ Farcaster pipeline (existing, automated, 2x daily)
├─ X/Twitter scout submissions (new, event-driven, real-time)
└─ [Future: other platforms]
          │
          ▼
SHARED DATABASE (Supabase)
├─ projects (3,090+ canonical entries)
├─ agent_memory (2,700+ intelligence entries)
├─ research_assessments
└─ [NEW] scout_submissions (scout-specific tracking)
          │
          ▼
EVALUATION → AGENT ACTIONS
```

### Data Flow: Submission → Evaluation → Action

```
Scout tags @fairvc on X
        │
        ▼
[1] INTAKE
    - Parse tweet: extract token/project mention, scout's commentary, linked content
    - Identify scout: wallet → tier → signal weight
    - Check: is this project already in `projects` table?
        ├─ YES → is this new information not in `agent_memory`?
        │         ├─ YES → proceed to evaluation
        │         └─ NO → reject (duplicate info, no reward)
        └─ NO → new project discovery → proceed to evaluation
        │
        ▼
[2] EVALUATION
    - Agent assesses using existing frameworks (PLAYBOOK, entry checklist, rug detection)
    - Cross-references: on-chain data, holder distribution, volume patterns, team verification
    - Scout's signal weight (from holdings) affects attention priority, NOT evaluation outcome
    - Confidence score assigned
        │
        ▼
[3] ACTION (based on confidence)
    ├─ LOW → Rejected. No DB entry. No reward.
    ├─ <60% → Saved to DB. New project → `projects`. New intel → `agent_memory`. Small reward.
    ├─ 60-80% → Signal Published. Comms Agent drafts signal post. Push notification to team before publish. Medium reward.
    └─ 80%+ → Trade Considered. Research Agent produces full investment memo. Push to team. Agent executes if autonomous mode. Large reward.
        │
        ▼
[4] RECORDING
    - Scout submission logged to `scout_submissions` table (scout wallet, project, timestamp, action taken, points earned)
    - Points calculated: base points × tier multiplier → daily pool + weekly leaderboard
    - If multiple scouts submitted same project: all rewarded for signal/trade actions
```

### Key Design Decisions

**Scout submissions hit the same database as the autonomous pipeline.** This is critical. When a scout submits a project that's already tracked, the agent compares against existing `agent_memory` entries. If the scout adds genuinely new information (new team member found, new partnership, liquidity event), it's a valid DB save. If it's information the pipeline already captured from Farcaster — rejected as duplicate.

**Evaluation uses the same frameworks.** The Research Agent's PLAYBOOK (Metagame Theory, Attention Theory, Probabilistic Thinking, etc.) and entry checklist (5 must-haves + 3-of-7 signals) apply equally to scout-sourced and pipeline-sourced signals. No separate evaluation logic. This keeps quality consistent and prevents gaming.

**Signal weight ≠ evaluation bias.** A GP's submission gets processed with higher priority (looked at sooner), but the confidence score is determined by the project's fundamentals, not the scout's tier. A Tier 1 scout submitting a genuine 80%+ confidence project gets the same trade outcome as a GP submitting it.

---

## 1.2 How Scouts Improve the Agent

### The Learning Loop

Every scout interaction improves the agent's capabilities in three ways:

**1. Coverage expansion**
The Farcaster pipeline monitors 5,000 users and ingests ~100K casts per run. This is deep but narrow — it only sees what Farcaster's social graph surfaces. Scouts on X extend coverage to alpha that lives outside the Farcaster bubble: CT (Crypto Twitter) alpha, Telegram group leaks that surface on X, cross-chain signals from non-Base communities, KOL callouts that don't get cross-posted to Farcaster.

**2. Human pattern recognition**
The pipeline uses GPT-5 relevance scoring (0.0–1.0). Good, but algorithmic. Scouts bring human intuition: "this dev's wallet just did something weird," "this team is the same guys who built X," "this narrative is about to rotate." These are signals that are hard to encode in a scoring prompt but obvious to experienced traders.

**3. Database enrichment**
Even rejected submissions teach the agent. Over time, patterns emerge: what types of projects scouts consistently submit that get rejected (noise profile), what types consistently lead to trades (signal profile). This data can be used to tune the pipeline's own scoring model.

### Feedback Mechanisms

**Track record per scout (post-MVP):**
Each scout builds a history in `scout_submissions`. Over seasons, the agent can see:
- Scout A: 40 submissions, 12 accepted, 3 led to profitable trades → high-signal scout
- Scout B: 60 submissions, 5 accepted, 0 trades → noise

This enables future features like scout reputation scoring and dynamic signal weighting based on track record, not just holdings.

**Agent performance tracking on scout-sourced signals:**
When the agent takes a trade based on a scout signal, the P&L of that position is tracked. We can't tie P&L to individual scout rewards (parked — legal), but we CAN:
- Display aggregate stats: "Scout-sourced trades: X% win rate, Y% avg return"
- Recognize top scouts with non-financial rewards ("Scout of the Week" — recognition, not commission)
- Use the data internally to evaluate whether the scout channel is producing alpha vs. the autonomous pipeline

---

## 1.3 Push Notification Before Signal Publish

For the Scout Game, the agent operates with **high autonomy + team visibility:**

- **DB saves:** Fully autonomous. No notification needed.
- **Signal publish:** Agent drafts signal → push notification to team (Telegram) → 5-min window for override → auto-publish if no veto.
- **Trade execution:** Agent produces memo + trade plan → push to team → 5-min window → auto-execute if no veto.

The goal is not to slow the agent down. The push is a safety net, not an approval gate. Team sees what's about to happen and can intervene only if something is clearly wrong (obvious scam, agent hallucination, position too large).

---

## 1.4 The "Paid Evaluation" Feature

### Designed Behavior, Not a Bug

A holder of token X can buy $FAIR → become a scout → submit token X to @fairvc. This is intentional and valuable:

**Why it's good:**
- Creates direct buy pressure on $FAIR from external communities
- Brings new users into the FAIR ecosystem who might stay as active scouts
- The agent evaluates objectively — buying $FAIR doesn't buy a positive signal, it buys ACCESS to the evaluation pipeline
- If the project is actually good, FAIR benefits from discovering it
- If the project is bad, it gets rejected and the scout wasted their entry cost

**Why it's safe:**
- Agent evaluation is the same for all submissions — no preferential treatment
- PLAYBOOK frameworks, entry checklist, and rug detection apply regardless of who submitted
- If agent detects coordinated push (multiple scouts, same token, short window), confidence DECREASES per the anti-manipulation rules in the risks document
- The scout paid real money ($24-$3,000+ depending on tier) for the chance to submit, not for a guaranteed signal

**Positioning:**
This should be communicated as a feature: "Want Fair's AI to evaluate your project? Hold $FAIR and submit it." It's essentially selling research-as-a-service through token holding — similar to the existing ACP service ($1 USDC per analysis on Virtuals) but through the scout mechanic.

---

## 1.5 AI Agents as Scouts

### The Idea

Allow other AI agents (not just humans) to participate as scouts. An AI agent running on another protocol could hold $FAIR, monitor its own data sources, and submit signals to @fairvc.

### Pros

- **Signal volume and diversity:** AI agents can monitor data sources 24/7 that human scouts can't — on-chain anomaly detection, cross-chain bridge flows, smart money wallet tracking, liquidation cascades
- **No fatigue:** Human scouts churn. Agent scouts don't get tired, don't lose motivation, don't take weekends off
- **Ecosystem narrative:** "AI agents hiring AI agents" — strong narrative for the Fair brand. Positions FAIR as infrastructure that other agents plug into
- **Natural fit with ACP:** Already selling research through Agent Commerce Protocol. Agent scouts are the buy side of the same marketplace
- **Token demand:** Agent protocols would need to acquire and hold $FAIR to participate, creating sustained buy pressure from protocol treasuries, not just retail

### Cons

- **Sybil risk amplified:** Creating 100 agent wallets is trivially cheap compared to creating 100 human identities. The token holding requirement helps but at Tier 1 ($24 entry) an agent could spin up many accounts
- **Spam potential:** AI agents can submit much higher volume than humans. Even with rate limits (3-5/day per wallet), 50 agent wallets = 150-250 submissions/day, overwhelming the evaluation pipeline
- **Quality uncertainty:** Agent-generated submissions might hit all the right keywords without genuine alpha — essentially automated keyword stuffing at scale
- **Gaming the scoring:** An agent can be specifically fine-tuned to craft submissions that maximize confidence scores, unlike humans who submit organically
- **Anti-spam detection on X:** 50 bot accounts all tagging @fairvc looks much worse to X's systems than 50 humans doing the same

### Recommendation

**Include as a flagged future feature.** Don't block it, don't build for it in MVP. Note it in the architecture as a planned expansion with specific requirements to enable:
- Separate "Agent Scout" tier with higher minimum holding (50M+?)
- Agent identity verification (must declare as agent, linked to a known protocol)
- Separate rate limits and evaluation queue
- Potentially separate reward pool to prevent cannibalization of human scout rewards

---

## 1.6 Open Questions (Need Resolution)

| # | Question | Impact | Suggested Resolution |
|---|----------|--------|---------------------|
| 1 | Does scout evaluation run through the existing Research Agent (Claude), or does it need a dedicated evaluation module? | Architecture. Research Agent already has PLAYBOOK + memo framework, but adding scout volume may overload it. | Start with Research Agent. If volume exceeds capacity, spin out a dedicated Scout Evaluation Agent with the same PLAYBOOK. |
| 2 | What confidence thresholds map to each action? Currently the flow doc says <60% = DB, 60-80% = signal, 80%+ = trade. Are these the right numbers? | Economics. Lower thresholds = more rewards paid = faster pool drain. Higher = fewer rewards = scout frustration. | Test phase will calibrate. Start with these thresholds, adjust based on acceptance rate data. Target: 20-30% acceptance rate. |
| 3 | How fast does evaluation need to happen? Real-time (minutes) or batched (hours)? | UX + cost. Real-time = better scout experience but higher API costs. Batched = cheaper but scouts don't get instant feedback. | Hybrid: intake + dedup check = real-time. Full evaluation = batched every 30-60 min. Scout gets "received" confirmation instantly, result within 1 hour. |
| 4 | Scout submissions that lead to trades — does the Execution Agent handle these the same as Research Agent recommendations? | Trading system. Need to confirm the scout → evaluation → trade path uses the same position sizing, stops, and TP rules. | Yes, same TRADING-SYSTEM.md rules apply. Scout-sourced trades follow the same conviction/momentum/asymmetric classification. |
| 5 | How do we handle a scout submitting a project the pipeline already discovered independently? | Rewards. Scout thinks they found alpha, but Fair pipeline already has it in DB. | If project exists in DB AND no new info: rejected. If project exists but scout adds new intel: DB save reward. Clear UX communication needed. |
| 6 | Rate limit for the override window on signal publish — what happens if team is asleep? | Operations. 5-min window with no response = auto-publish. But at 3am? | Accept the risk. The whole point is autonomy. PLAYBOOK frameworks + rug detection are the safety net, not human availability. |

---

*Next section: Tech Stack & Costs →*
