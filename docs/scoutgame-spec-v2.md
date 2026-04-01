# Scout Game — Judgement Agent Spec v2

> Compiled from founder interview, 2026-03-17. Updated 2026-03-27.
> This is the canonical spec. Workspace files (SOUL.md, AGENTS.md, skills) are the implementation.

---

## 1. System Overview

The Judgement Agent evaluates scout submissions containing a contract address (CA) and thesis about Base tokens. It scores the submission, takes action, and replies.

**GP test (S0):** Telegram-only. Scouts post in a dedicated TG group. X/Twitter integration deferred to S1.

**Target universe:** Base tokens only. FDV >$50K and <$20M. Launched <30 days. Has active LP on GeckoTerminal. All token types welcome — quality of thesis, team, and on-chain activity determines the score.

**The agent does NOT publish signals directly.** It produces structured evaluations. A separate comms agent composes and publishes signal posts after team approval.

---

## 2. Evaluation Pipeline

### Step 1: Structural Filter
On OpenClaw, every message hits the LLM — no true pre-LLM short-circuit. For GP test, accept the cost (~$0.003/message). For S1+, build external intake service.

Checks: no CA (`NO_CA`), too short (`TOO_SHORT`), not trading (`NOT_TRADING`), FDV outside range (`OUT_OF_RANGE`), age >30d (`TOO_OLD`), no LP (`NO_LP`), rate limit (`RATE_LIMIT`), duplicate (`DUPLICATE`), banned (`BANNED`).

**Factory detection runs here.** Read `config/factory-registry.json` (explicit tool call — not auto-injected). If `token_factory = "unknown"`, flag `UNVERIFIED_LAUNCH`.

**Write submission receipt to Supabase immediately** — compaction protection.

### Step 2: Thesis Quality Gate (Sonnet)
Scores thesis quality 1-10. Gate at < 4. Rejects 70-80% of submissions.

- **Reply handling:** If scout's tweet is a reply, concatenate parent tweet + scout's reply as combined thesis. Scout gets credit for surfacing good threads.
- **Media:** If `has_media = true`, pass images to vision API (Sonnet) alongside text. Evaluate both text and visual content (screenshots of BaseScan, wallet data, charts).
- **Rubric:** Specificity, information edge, timing (FDV vs comps), on-chain insight (must be specific with wallet addresses / tx IDs), builder mention, narrative fit.

### Step 3: Snapshot Interpretation (Sonnet, on-demand skill)
Reads GeckoTerminal + BaseScan data. Builds market context:
- Liquidity ratio (`pool_liquidity_usd / fdv_usd`) — key metric for realizable value
- Age, holder concentration, volume patterns, timing assessment
- Multi-scout convergence analysis (organic vs coordinated)
- For `UNVERIFIED_LAUNCH` tokens: basic contract analysis (mint functions, owner privileges, proxy upgradeability, hidden fees)

### Step 4: DB Context Check
- Existing project with new info → **fresh evaluation from scratch**, old score provided as context only (no anchoring)
- Existing project, no new info → duplicate handling
- New project → mark `is_new_discovery`

### Step 5: Deep Token Analysis (Sonnet, on-demand skill)
5 dimensions, **Builder/Team weighted 2x**:

| Dimension | Range | Weight | Description |
|-----------|-------|--------|-------------|
| Builder / Team | 0-4 | 2x | Identity, track record, social graph, shipping activity |
| Product Reality | 0-2 | 1x | Live product, on-chain usage, traction |
| On-chain Activity | 0-2 | 1x | Smart money accumulation, deployer history, holder quality |
| Market Structure | 0-1 | 1x | Liquidity ratio, concentration, buy/sell flow |
| Narrative Fit | 0-2 | 1x | Current meta fit, lifecycle position, attention state |
| **Max raw** | **11** | | |

Normalized: `token_score = (raw_score / 11) * 10`

Investment frameworks applied: Metagame Theory, Attention Theory, Probabilistic Thinking, Incentive Mapping, Social Graph as Distribution.

Builder/Team research: live web/X search. No pre-built database. If unverifiable, score conservatively and say so explicitly.

### Step 6: Final Score
Token score + modifiers. Floor 0, ceiling 10.

| Modifier | Delta |
|----------|-------|
| Scout signal_score > 5 (proven track record) | +0.5 |
| Scout signal_score 3-5 (good track record) | +0.3 |
| Thesis score 8+ | +0.3 |
| New discovery + token_score >= 5.5 | +0.2 |
| Multi-scout organic convergence | +0.3/scout (max +0.6) |
| LOW_LIQUIDITY (<$10K) | -0.5 |
| HIGH_CONCENTRATION (top10 >70%) | -0.5 |
| DEPLOYER_HOLDING_LARGE + selling | -1.0 |
| COORDINATED_PUSH | -1.0 |
| FDV near comparable ceiling | -0.5 |
| UNVERIFIED_LAUNCH + contract red flags | -0.5 |

---

## 3. Decision Table

| Final Score | Action | Base Points | Review |
|-------------|--------|-------------|--------|
| < 4.0 | REJECT | 0 | Automatic |
| 4.0 - 6.4 | DB_SAVE | 1 | Automatic (logged in daily digest) |
| 6.5 - 7.9 | SIGNAL | 5 | **Team approval required** |
| 8.0 - 10.0 | TRADE | 20 | **Team approval required** |

**No auto-publish.** All SIGNAL and TRADE actions go to Telegram review queue. Team explicitly approves, edits, or kills.

---

## 4. Reply Flow

### GP test (TG):
| Outcome | Reply |
|---------|-------|
| No CA | *(ignore silently)* |
| Structural fail | Specific reason (`rate limit`, `outside range`, etc.) |
| REJECT | `evaluated [TICKER]. doesn't meet our threshold.` |
| Duplicate | `we already have [TICKER]. submit new intel to update our view.` |
| DB_SAVE / SIGNAL / TRADE | `[TICKER] — logged. watching.` *(identical — scout doesn't know tier)* |

### S1 (X/Twitter — deferred):
- Scout tags `@fairvc` → immediate receipt → evaluation reply
- DB_SAVE/SIGNAL/TRADE: `[TICKER] — saved to our intel database. follow @fairvc to see which signals make the cut.`
- CTA to follow Fair's X (growth mechanic)

### Key decisions:
- Blunt, no coaching, no score sharing
- **One-shot only.** Never respond to follow-ups.

---

## 5. Signal Publishing Flow

1. Judgement Agent produces evaluation JSON + `signal_brief` (ticker, thesis, key insight, scout handles, FDV)
2. Evaluation goes to Supabase (structured data) + Telegram (team review)
3. Team reviews in Telegram: sees full evaluation, scores, reasoning, flags
4. Team can **APPROVE**, **EDIT** (modify brief or downgrade SIGNAL → DB_SAVE), or **KILL**
5. On APPROVE: comms agent receives `signal_brief` + composes signal post in Fair's voice
6. Signal post mentions all scouts who submitted the CA. First submitter highlighted.
7. If token price moved significantly since evaluation, include `evaluated at $[FDV] FDV` note

**The Judgement Agent does NOT compose the signal post.** That's the comms agent's job.

---

## 6. Points & Economics

### Base points:
- REJECT: 0
- DB_SAVE: 1
- SIGNAL: 5
- TRADE: 20

### Tier multipliers:
- T1: 1.0x
- T2: 1.5x
- T3: 3.0x
- GP: 5.0x

### Daily cap: **50 weighted points per scout per day**
Prevents GP volume farming. A GP doing 5 DB_SAVEs = 5 × 1 × 5.0 = 25 points. A GP landing one SIGNAL = 5 × 5.0 = 25 points. Cap reached at 50 regardless.

### Multi-scout credit:
- All scouts who submitted the same CA with organic convergence get mentioned in signal post
- **First submitter gets 1.5x points** for early discovery
- Subsequent organic scouts get standard points
- Each scout's tier multiplier applies individually

### Retroactive points:
- If a DB_SAVE'd token is escalated to SIGNAL/TRADE by ANY pipeline within **14 days**, original scout(s) get **full upgraded points**
- Example: scout DB_SAVE'd (1 pt) → Farcaster pipeline scores TRADE 10 days later → scout retroactively gets 20 base points × tier multiplier
- First submitter bonus (1.5x) still applies
- Logged in daily digest

---

## 7. Token Factory Detection

### Architecture:
Pluggable config file: `agent/config/factory-registry.json`

Adding a new launchpad = adding one entry to the JSON config. No code changes.

### Supported factories (GP test):
- **Clanker** — fee claim detection (claimed = active creator, unclaimed >7d = possible bot)
- **Bankr** — context only, no fee mechanism
- **Flaunch** — Flaunch launchpad
- **Virtuals** — AI agent token factory, bonding curve
- **Noice** — Noice launchpad
- **Creator Bid (Aerodrome)** — Aerodrome-based token creation

### Fee detection:
Only Clanker currently has a fee claim mechanism. For Clanker tokens:
- Fees claimed → green signal (founder is active, not a bot)
- Fees unclaimed + token ≥ 7 days → flag `CLANKER_FEES_UNCLAIMED`, -0.5 to founder score
- Fees unclaimed + token < 1 day → too early, ignore

---

## 8. Watch Flags

When writing `agent_memory` for DB_SAVE+, the agent decides **per case** whether to flag as `worth_watching`.

No fixed score threshold. Agent uses synthesis judgment and writes specific revisit conditions:
- "revisit if TVL crosses $5M"
- "revisit if founder ships V2"
- "revisit if narrative picks up"

Other agents in Fair infrastructure can notify the Judgement Agent about traction updates on watched tokens. The Judgement Agent evaluates those notifications as new context (not a re-scan — it's reactive to incoming signals).

---

## 9. Anti-Gaming

**Phase scoping:**
- **GP test (S0):** Anti-gaming rules DISABLED (known individuals). Prompt injection protection always active.
- **Public season (S1+):** Full anti-gaming active — coordinated push detection, template farming, thesis padding, wash volume.

Details in `anti-gaming` skill (loaded on-demand).

---

## 10. Signal Performance Tracking

Performance tracked for **scout reputation scoring**. Checked at **1 day, 7 days, 14 days** from signal.

### Scoring formula:
- Token up >100% from signal FDV: **+1 point**
- Each additional 100% gain: **+1 point** (200% = +2, 300% = +3, etc.)
- Token down >50%: **-2 points**
- Calculate from: (a) last checkpoint AND (b) original signal FDV

### Example:
Signal at $200K FDV.
- Day 1: FDV $500K (+150%) → +1 point. Checkpoint: $500K.
- Day 7: FDV $300K (-40% from checkpoint, +50% from original) → 0 points.
- Day 14: FDV $100K (-67% from checkpoint, -50% from original) → -2 from checkpoint, -2 from original.

Cumulative `signal_score` feeds into scout reputation → used as modifier in Step 6 (+0.3 or +0.5).

### Trade performance:
Only evaluated when Fair exits position. **70% win rate target.** Judgement Agent requests daily PnL from position-tracking agent after first trade.

### GP test phase:
- **Duration:** 2 weeks
- **Scale:** 5-10 GPs, ~25-50 daily submissions
- **Kill criteria:** If < 20% of submissions pass the Thesis Quality Gate, thesis quality bar or scout engagement is broken. Redesign needed.
- **GP awareness:** Partial — GPs know scores exist and see their acceptance rate, but the specific rubric stays private.

---

## 11. Public Leaderboard

After GP test, on fair.fun or similar:
- **Points + best finds** — total weighted points this season + trophy case of top 3 highest-scoring discoveries (tickers and brief descriptions)
- No full stat exposure (avoids optimizing for volume metrics)
- Scouts see their own detailed stats in a private dashboard

---

## 12. OpenClaw Architecture

### Model strategy (GP test):
Single model (Sonnet) for everything. OpenClaw pins models per session — can't switch mid-evaluation. Model tiering deferred to S1 via Lobster pipeline if needed.

### Session strategy:
Hourly batches. Fresh session per batch. ~2-4 submissions per batch at GP volume.
- Prompt cache reuse within batch
- Bounded context growth (max ~25 evaluations per batch)
- Clean state between batches

### Compaction mitigation:
Write submission receipt to Supabase at Step 1 (before heavy LLM work). If compaction fires mid-eval, submission exists in DB and gets re-processed next batch.

### Memory:
MEMORY.md doesn't load in group chats. All evaluation state → Supabase. OpenClaw daily notes only for agent self-calibration.

### Bootstrap files (injected every turn):
| File | Size | Purpose |
|------|------|---------|
| `SOUL.md` | ~4 KB | Identity, character, decision thresholds, hard rules |
| `AGENTS.md` | ~8 KB | Pipeline, output JSON, TG reply flow, points, memory, tools |
| `TOOLS.md` | ~2 KB | API guidance |
| **Total** | **~14 KB** | Well under 20K per-file limit |

### Skills (on-demand — loaded by explicit directive in AGENTS.md):
| Skill | Size | When loaded |
|-------|------|-------------|
| `snapshot-interpretation` | ~6 KB | Step 3 |
| `deep-analysis` | ~6 KB | Steps 5-6 |
| `anti-gaming` | ~3 KB | S1+ only |

### Config:
- `openclaw.json` — agent settings, channels, cron jobs, compaction thresholds
- `factory-registry.json` — pluggable factory detection (read via explicit tool call, not auto-injected)

### Cron jobs (separate from Judgement Agent):
| Job | Schedule | Model | Purpose |
|-----|----------|-------|---------|
| `fdv-snapshot` | Daily 00:00 UTC | Sonnet | FDV tracking for SIGNAL/TRADE tokens |
| `daily-digest` | Daily 01:00 UTC | Sonnet | Summary, acceptance rates, notable scores |
| `retroactive-upgrade` | Daily 02:00 UTC | Sonnet | 14-day lookback for DB_SAVE escalations |

### Reference:
- `v1-full-spec.md` — original monolithic 34K spec (not deployed)

---

## 13. File Structure

```
scout-game/
├── CLAUDE.md                          # Project context for Claude
├── agent/
│   ├── SOUL.md                        # Agent identity (bootstrap)
│   ├── AGENTS.md                      # Operating manual (bootstrap)
│   ├── TOOLS.md                       # Tool guidance (bootstrap)
│   ├── v1-full-spec.md                # Original monolithic spec (reference)
│   ├── config/
│   │   ├── openclaw.json              # OpenClaw agent config (model, channels, cron)
│   │   └── factory-registry.json      # Pluggable factory detection
│   └── skills/
│       ├── snapshot-interpretation/
│       │   └── SKILL.md               # Step 3 market data interpretation
│       ├── deep-analysis/
│       │   └── SKILL.md               # Steps 5-6 token analysis + frameworks
│       └── anti-gaming/
│           └── SKILL.md               # Manipulation detection (S1+)
├── docs/
│   ├── openclaw/                      # OpenClaw reference docs
│   │   ├── workspace-guide.md
│   │   ├── system-prompt-architecture.md
│   │   ├── skills-system.md
│   │   ├── lobster-pipelines.md
│   │   ├── multi-agent-config.md
│   │   └── implementation-notes-tyreal.md  # Engineering review notes
│   ├── scoutgame-spec-v2.md           # THIS FILE — canonical spec
│   ├── supabase-schema.md              # DB field spec for Luc
│   ├── critical-notes-2026-03-17.md
│   └── future-ideas.md
└── skills/
    └── token-analysis-skill/          # Original Fair token analysis skill
```

---

*Scout Game Judgement Agent Spec v2 — compiled 2026-03-17, updated 2026-03-27*
