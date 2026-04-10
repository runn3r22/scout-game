# Future Ideas & Deferred Decisions

## Saved from 2026-03-17 review session

### V2+ Features

1. **Non-token signals: waitlists, early-stage projects**
   Scouts could submit not just live tokens but early signals: waitlist opens, testnet launches, pre-token projects. Would need different evaluation framework (no snapshot data). Could create a separate "early intel" category with different scoring.

2. **Contract analysis for non-factory tokens**
   When `token_factory = "unknown"`, run basic contract analysis: check mint functions, owner privileges, proxy upgradeability, hidden fees. 90% of tokens are from known factories (LP locked), but the 10% custom-deployed tokens need extra scrutiny. Only trigger when factory is NOT identified.

3. **LLM narrative over-weighting mitigation**
   Research shows LLMs structurally over-weight narrative signals vs quantitative on-chain data. For V2: consider multi-agent cross-validation (one agent for narrative, one for on-chain metrics) or structured scoring that forces quantitative checkboxes before narrative assessment.

4. **Small group gaming defenses (S1+)**
   When scaling to 50+ scouts: collusion detection, Sybil resistance, tanking detection. Not needed for GP test with 15-25 hand-picked scouts.

5. **Image support V2: platform-specific URL parsing**
   Instead of OCR/vision, parse data directly from BaseScan/GeckoTerminal/wallet tracker URLs when scouts include links. Most reliable data extraction method.

6. **Progressive autonomy roadmap**
   Start with team approval for all SIGNAL/TRADE. After calibration and proof of work:
   - Phase 1: Team approves everything
   - Phase 2: DB_SAVE auto, SIGNAL auto with team veto window, TRADE team approves
   - Phase 3: SIGNAL auto, TRADE auto with team veto window
   - Phase 4: Full autonomy with kill switch

7. **Internal dashboard: who submitted what**
   For internal use — show all scouts who submitted a given CA, when, with what thesis. Especially useful when multiple scouts converge on same token. Team needs this visibility.

### Performance Scoring (refined from interview)

**Trades only get outcome evaluation.** DB_SAVE and SIGNAL are not scored by price outcome.

**Signal performance tracking for scout reputation:**
- Check at: 1 day, 7 days, 14 days from signal
- Scoring: >100% gain = +1 point, each additional 100% = +1 point
- Penalty: -50% drop = -2 points
- Calculate from: last evaluation checkpoint AND from original signal value
- This feeds into scout reputation, not agent accuracy

**Trade target: 70% winrate.**
- Evaluated when Fair exits position (another agent handles exit)
- Judgement agent does daily PnL check with position-tracking agent

---

## S0 Simplification Log (code-level, surgical)

**Read this before starting S1.** Every entry here is a feature that was deliberately removed or stubbed from runtime files for the GP test. Each entry tells you exactly which file to touch to bring it back. When S1 starts: walk this list top-to-bottom, restore each item, then read the conceptual sections below for context.

**Format:** `Feature` — `what was cut` — `file:context` — `restore action`.

### 2026-04-07 cuts

- **`COORDINATED` modifier (-1.0)** — removed from S0 active modifier list. Was about coordinated push detection (≥3 wallets submit same CA in 15 min). Cut because GP test has 10 known scouts so coordination is impossible.
  - File: `agent/AGENTS.md` — "Modifiers (S0 active)" line. To restore: re-add `COORDINATED (-1.0)` to that list AND flip the phase note in `agent/skills/anti-gaming/SKILL.md` (remove the "DISABLED in S0" sentence).
- **Submission rate limit (5/scout/day)** — fully removed. No rate-limit logic anywhere in pipeline. Was: scout exceeds 5 submissions/day → `RATE_LIMIT` reject.
  - File: `agent/config/reply-templates.json` — `gp_test.structural_rate_limit` template was deleted. To restore: re-add the template, re-add `RATE_LIMIT` reject_code in `agent/AGENTS.md` Step 1, add a count check against `scout_points.submission_count` for current day.
- **Tier system rule** — `SOUL.md` line "Tier ≠ score" was removed (no tiers in S0, all GPs treated equally). To restore: re-add the rule under "Hard Rules" in `agent/SOUL.md` and bring back tier multipliers in `agent/skills/evaluation-output/SKILL.md` per CLAUDE.md "Points Per Action" table.
- **Multi-scout convergence modifier (`MULTI_SCOUT_CONVERGENCE` +0.3 organic / +0.6 max)** — removed from `agent/skills/snapshot-interpretation/SKILL.md`. Was a whole section reading `db.previous_submissions` and applying organic-vs-coordinated bonus/penalty. Cut for same reason as COORDINATED — no statistical signal at 10 scouts.
  - File: `agent/skills/snapshot-interpretation/SKILL.md` — "Multi-Scout Convergence" section was deleted. To restore: paste back the section AND wire `db.previous_submissions` into Step 4 query in `agent/AGENTS.md`.
- **Creator Bid factory** — fully purged from `factory-registry.json`, `TOOLS.md`, and `snapshot-interpretation/SKILL.md`. Confirmed not relevant to Fair (Vasya 2026-04-07: "useless shit"). **Do NOT restore in S1.** Listed here only so we don't accidentally re-add it during S1 sweep.
- **Calibration examples** — `agent/skills/calibration-examples/SKILL.md` exists as placeholder, all 5 example slots are `_To be filled by Vasya._`. **Action item for Vasya:** populate before smoke test. Format: `Submission text / Context / Expected outcome / Why this score / Common failure mode`.
- **SOUL.md duplicate follow-up rules** — two separate lines saying the same thing ("Ignore follow-up replies" and "One evaluation per submission. No re-evaluation on follow-up.") were collapsed into one. Pure dedupe, no behavior change. **Do NOT restore** — this is just cleanup.
- **SOUL.md "Never compose public-facing content" rule** — was: blanket ban on public output. Now reads: ban on freeform copy, but **templated Telegram replies from `config/reply-templates.json` are allowed**. Cut reason: in S0 the Judgement Agent IS the one sending replies to scouts (no Comms Agent in the loop yet). To restore S1 behavior: when Comms Agent comes online and starts handling external posts, tighten this rule back to "produce structured `signal_brief` JSON only, never any user-facing text". File: `agent/SOUL.md` Hard Rules section.

### How to use the simplification log

When you (Claude) cut a feature from current scope to simplify testing, add an entry here with:
1. What was cut (1 line)
2. Why (1 line)
3. Exact file + section/line where it used to live
4. Restore action (precise: "re-add X to file Y in section Z")

When Vasya says "we're starting S1, check the log" — read this section top-to-bottom and restore each entry methodically. Pair with the conceptual sections below for context.

---

## Saved from 2026-04-07 GP test scoping session

The GP test (S0) is intentionally a stripped-down version to validate the core mechanic: submission → evaluation → scoring → DB write → reply. Everything below was deliberately cut from S0 and must come back before S1.

### Reward economics — full version

**Tier multipliers** (T1 1.0x / T2 1.5x / T3 3.0x / GP 5.0x). Cut from S0 — flat points only (REJECT 0 / DB_SAVE 1 / SIGNAL 5 / TRADE 20). Tier holdings affect signal weight and points multiplier in S1+. Full table is in `CLAUDE.md` under "Points Per Action".

**Daily weighted-points cap (50/scout/day).** Cut from S0 — no rate limit at all in GP test. The cap exists to prevent one scout flooding the pool. Re-enable in S1 when there are more scouts and a real pool.

**Daily/weekly proportional pool.** Cut from S0 — no pool, no proportional split, no token distribution. The full design (50% daily / 50% weekly + unused daily, proportional by weighted points) is in `CLAUDE.md` under "Reward Economics". Re-enable in S1.

**Seasonal allocation.** Cut from S0. S0 is 1 week, ~10 GPs, no token rewards from a fixed pool. S1 is the first real season with allocation logic.

**Hedgey claim contracts.** Cut from S0. No claims UI, no token distribution at all in GP test. S1+ uses Hedgey audited contracts on Base.

**Submission rate limits** (5/scout/day in original spec). Cut from S0 — for GP test we want maximum data even from spammy submissions, so we can see what the agent does with edge cases.

### Scoring features — full version

**Scout reputation modifiers** (+0.3 / +0.5). Cut from S0 — all scouts treated as 1.0x in GP test. The reputation system itself is per-season, resets each season, and grows/shrinks based on track record. Add in S1 once we have track records.

**Convergence bonus** (+0.3 per additional scout flagging same CA). Cut from S0. Re-enable when we have enough scouts that convergence is statistically meaningful.

**Earlyness multiplier, discovery bonus, streak bonuses.** All cut from S0 (always were post-MVP). When the same CA gets flagged multiple times, the first scout to flag it should get a multiplier. Streaks: scouts who consistently flag winners get a compounding bonus.

### Evaluation features — full version

**Step 4: DB context check against main Fair Supabase.** Cut from S0 — GP test uses a separate test Supabase with no historical Fair data. In S1, Step 4 queries the shared `projects` and `agent_memory` tables for prior intel and adjusts evaluation accordingly. The current AGENTS.md still describes Step 4 logic correctly — it just runs against the test DB which is empty.

**`agent_memory` table.** Not created in S0 schema. In the main Fair infra, this is a grow-over-time journal of agent observations about tokens (Research Agent memos, Comms Agent narrative notes, prior judgement reasoning). When we integrate with main Fair Supabase, judgement agent should both READ this for context AND WRITE intel summaries after high-scoring evaluations.

**Doppler beneficiary lookup for Bankr/Noice disambiguation.** Decided in 2026-04-07 to defer (option "a"): tokens launched via Bankr or Noice currently match as `doppler` in Step 1, which is fine for scoring. If platform identity matters in Step 5, the LLM can go inspect Lock-event beneficiaries via BaseScan ad-hoc. If on tests we see this is too unreliable, build a dedicated `doppler-beneficiary-lookup` skill that does the BaseScan call → Lock event parse → fee_wallet match. Addresses are in `agent/config/factory-registry.json` under `bankr.addresses.fee_wallet` and `noice.addresses.fee_wallet`.

**Thesis Quality Gate as a separate skill.** Currently lives as one line in `agent/AGENTS.md` Step 2 with a 6-criterion rubric. If on calibration we see scoring drift (same thesis getting different scores across batches), promote it to `agent/skills/thesis-quality/SKILL.md` with explicit examples per score band (1, 4, 7, 10) and possibly a weighted formula across the 6 criteria.

### Cron jobs — cut from S0

**`fdv-snapshot` cron.** Cut from S0. The job pulls current FDV for all SIGNAL/TRADE tokens from GeckoTerminal daily and updates `token_performance` table for 1d/7d/14d performance tracking vs signal-time FDV. Re-enable when we want to measure scout performance for reputation scoring (S1+).

**`retroactive-upgrade` cron.** Cut from S0. The job checks DB_SAVE tokens from last 14 days against any SIGNAL/TRADE actions from other Fair pipelines. If a DB_SAVE token gets later promoted by another pipeline, the original scout retroactively gets upgrade points. Useless in S0 because we have an isolated test Supabase with no other pipelines. Re-enable in S1 when integrated with main Fair infra.

### X integration — full version

**X API intake.** Cut from S0 entirely. GP test is Telegram-only (scout submission group). Original full design polls X API for `@fairvc` mentions every 2-3 minutes, parses tweets, replies publicly within 5 minutes. Requires X API Basic ($200/mo) or Pro ($5K/mo). Re-enable in S1 public launch.

**Public X replies from `@fairvc`.** Cut from S0. In S1, the comms agent (separate from judgement) writes the public reply post; judgement agent only produces structured `signal_brief` JSON. Currently in S0 the judgement agent sends Telegram replies directly to the scout submission group.

**Privy auth (X login + wallet connect).** Cut from S0. No claim UI, no auth, no scout self-onboarding. S1+ uses Privy when there's a public claim flow.

### Anti-gaming — full version

**Rug detection.** Cut from S0. GP test uses a closed group of trusted scouts (10 GPs). No need for rug detection. Re-enable for public phase.

**AI agents as scouts.** Flagged in original spec, not built. Future open question: should AI agents be allowed to participate as scouts? Different signal weights? Separate leaderboard?

**Gaming defenses for 50+ scouts.** Already noted above in "Saved from 2026-03-17" section #4 — collusion detection, Sybil resistance, tanking detection. Belongs in S1+.

### Manual review mechanics — explicitly skipped

**Team manual bonus / "like" mechanic.** Discussed 2026-04-07 — idea was that team could click a button in Telegram team-review channel to give bonus points to a submission they personally liked. Decided to skip as confused/unclear, will not be in S0 or S1. If revived later: needs Telegram inline buttons, separate `team_bonus_points` column, clear semantics about whether it's bonus-on-top or score-override.

---

## How to use this document

When something gets cut from current scope, write it here with: (a) what it is, (b) why it was cut, (c) what conditions would make it relevant again, (d) where in the codebase it would touch. This is the canonical "do not lose this idea" file. When starting a new phase (S1, S2), re-read this end to end and pull items back into scope.
