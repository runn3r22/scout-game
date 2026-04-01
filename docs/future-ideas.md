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
