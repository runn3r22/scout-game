# Vasya — Action Items Before Smoke Test

Things that block the GP test smoke test and require Vasya's hands. Claude can't do these.

## P0 — hard blockers

### 1. Apply Supabase schema
**Status:** in progress (2026-04-07)
**File:** `supabase/schema.sql`
**Steps:**
1. Open https://supabase.com → log in → click `scout-game-test` project
2. Open SQL Editor (`</>` icon in left sidebar)
3. Open `C:\builder\fair\scout-game\supabase\schema.sql` in a text editor (VS Code, not browser/markdown viewer)
4. Ctrl+A → Ctrl+C → paste into SQL Editor → Run
5. Verify in Table Editor that 3 tables exist: `scout_submissions`, `projects`, `scout_points`
6. Tell Claude "schema applied, 3 tables visible"

### 2. Inspect server for HTTP tool path
**Status:** pending
**Why:** Agent is told to write to Supabase / call GeckoTerminal / send Telegram replies, but `agent/TOOLS.md` doesn't document which tool function to use because we don't know its name. Without this, the agent will fail at Step 1 trying to write the receipt.
**Steps (run on the OpenClaw server):**
```bash
cat ~/.openclaw/openclaw.json | head -100
ls ~/.openclaw/mcp/ 2>/dev/null
ls ~/.openclaw/plugins/ 2>/dev/null
openclaw tools list 2>/dev/null
```
**What to send back to Claude:**
- Names and signatures of any HTTP / fetch / supabase / telegram tools
- Specifically: how does Research Agent currently write to the main `projects` table? Same mechanism applies here.
- Telegram bot tool name + signature (`send_message(chat_id, reply_to_message_id, text)`?)

### 3. Put env vars on the server
**Status:** pending
**Vars to add (same place as existing `botToken`):**
```
SUPABASE_URL=<on server in ~/.openclaw/secrets.env>
SUPABASE_SERVICE_KEY=<on server in ~/.openclaw/secrets.env — NEVER commit>
```
**Note:** the service key is in chat history → after smoke test rotate it in Supabase Settings → API → "Reset service_role key".

## P1 — content gaps

### 4. Fill calibration-examples skill
**Status:** placeholder, all 5 slots are `_To be filled by Vasya._`
**File:** `agent/skills/calibration-examples/SKILL.md`
**Why:** the skill exists to anchor agent scoring across batches. Without real examples, the agent has no ground truth for what a "5" vs "8" thesis looks like — score drift is guaranteed.
**Format per example:**
- **Submission text** — exact tweet/telegram message (use real or realistic)
- **Context** — token state at the time (FDV, factory, age, what was happening on CT)
- **Expected outcome** — REJECT / DB_SAVE / SIGNAL / TRADE + score
- **Why this score** — 2-3 sentences explaining which dimensions drove it
- **Common failure mode** — what a naive scorer would get wrong about this one

**Aim for coverage:**
- 1 clear REJECT (low quality, no specifics)
- 1 borderline DB_SAVE (4.0-5.0 range)
- 1 solid DB_SAVE (5.5-6.4)
- 1 SIGNAL (6.5-7.9, with named builder + on-chain insight)
- 1 TRADE (8.0+, the type of submission you'd actually want to trade on)

The 5 examples become the agent's calibration anchors for the entire GP test.

## P2 — nice to have before smoke test

### 5. Decide on Vasya/team Telegram chat IDs
The agent needs to know:
- Scout submission group `chat_id` (where scouts submit) — for replies
- Team review channel `chat_id` (where SIGNAL/TRADE alerts go) — for approvals

If these are already in env vars, document the var names. If not, find the IDs (forward a message to @userinfobot in Telegram) and add them.

---

## Once all P0 done, the smoke test plan

1. Vasya posts a fake submission in the scout group with a real Base CA + 30-word thesis
2. Watch agent logs: receipt → snapshot → DB write → reply
3. Verify in Supabase: `scout_submissions` row created, `projects` row upserted, `scout_points` incremented
4. Verify in Telegram: agent replied with the right template

If all four happen → S0 is functionally live and we can onboard the 10 GPs.
