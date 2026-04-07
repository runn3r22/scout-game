---
name: calibration-examples
description: >
  Reference set of example submissions with expected scores and reasoning.
  Load this skill when calibrating evaluation, debugging score drift, or
  testing the pipeline. Examples are curated by the team — agent reads
  them, never edits them.
user-invocable: false
---

# Calibration Examples

Curated submission examples with expected outcomes. Used to:
1. **Calibrate** the agent — read before a batch to anchor scoring
2. **Test** the pipeline — run these through end-to-end and compare actual vs expected
3. **Debug** drift — when live evaluations look off, check against these

**Authored by the team.** Agent must NOT edit this file. Examples below are placeholders — Vasya will replace them with real ones.

---

## Format

Each example follows the same shape:

```
### Example N: [short label]

**Submission text** (as it would appear in Telegram):
> @scoutname submits: $TICKER 0xCONTRACT — [thesis text]

**Context**: [any out-of-band info about why this is interesting — e.g. "this was sent BEFORE the run", "scout has prior winners"]

**Expected outcome**:
- Structural filter: PASS / FAIL (reason)
- Thesis quality: N/10
- Token score: N/10
- Final score: N.N
- Action: REJECT / DB_SAVE / SIGNAL / TRADE
- Points: 0 / 1 / 5 / 20

**Why this score**: [2-4 sentences. What makes this example diagnostic — what specifically should the agent latch onto.]

**Common failure mode**: [if applicable — e.g. "Agent might over-weight the narrative claim and miss that liquidity ratio is 2%"]
```

---

## Examples

### Example 1: [PLACEHOLDER — strong signal, on-chain insight]

_To be filled by Vasya._

### Example 2: [PLACEHOLDER — clean reject, vague thesis]

_To be filled by Vasya._

### Example 3: [PLACEHOLDER — DB_SAVE band, decent but not signal]

_To be filled by Vasya._

### Example 4: [PLACEHOLDER — edge case, Bankr/Doppler stack]

_To be filled by Vasya._

### Example 5: [PLACEHOLDER — false positive trap]

_To be filled by Vasya._

---

## When to read this skill

- At the **start of every fresh session** (compaction-resistant anchoring)
- When **uncertain** about a borderline score — find the closest example and align
- When **debugging** a flagged drift between runs

Do not let calibration examples override the evaluation pipeline. They anchor judgement, they don't replace it.
