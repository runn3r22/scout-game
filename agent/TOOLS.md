# Judgement Agent — Tools & API

You have four tool families. This file is the contract for how to call each one.

1. **`exec`** — run `bash -c '<command>'` for HTTP via `curl`. This is the canonical path for Supabase, GeckoTerminal, and BaseScan. `curl 8.5.0` and `jq 1.7` are available on the host.
2. **`message`** — cross-channel sends (team review channel alerts for SIGNAL/TRADE). DO NOT use this to reply in the scout group — the channel adapter handles scout-group replies automatically when you print text.
3. **`read` / `write`** — workspace files under `config/` (factory registry, reply templates) and daily notes under `memory/`.
4. **`web_fetch` / `web_search` / `x_search`** — builder and narrative research in Step 5 only.

Environment variables available inside `exec`: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`. Never echo them into replies or logs. No API key is needed for GeckoTerminal public tier.

---

## Supabase (via `exec` + `curl`)

PostgREST endpoint is `$SUPABASE_URL/rest/v1`. The service key bypasses RLS. Every request MUST send both `apikey` and `Authorization: Bearer` headers. Use `jq` to parse responses.

### S1 — INSERT receipt (Step 1, compaction protection)

Write this FIRST, before any LLM-heavy work, so the `id` is persisted if context drops.

```bash
exec bash -c '
curl -sS -X POST "$SUPABASE_URL/rest/v1/scout_submissions" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d @- <<'"'"'JSON'"'"' | jq -r ".[0].id"
{
  "scout_id": "<telegram_user_id>",
  "scout_handle": "<telegram_username>",
  "source_platform": "telegram",
  "source_chat_id": "<chat_id>",
  "source_message_id": "<message_id>",
  "source_message": "<original_text>",
  "ca": "<0x...>",
  "status": "pending"
}
JSON
'
```

Capture the returned `id` into working memory as `$SUB_ID` — Step 6 needs it for the final PATCH.

### S2 — SELECT projects by ca (Step 4, dedup + context)

```bash
exec bash -c '
curl -sS -G "$SUPABASE_URL/rest/v1/projects" \
  --data-urlencode "ca=eq.<0x...>" \
  --data-urlencode "select=ca,ticker,factory,latest_score,latest_action,submission_count,notes,notes_updated_at" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
| jq ".[0] // null"
'
```

`null` → new discovery. Non-null → existing project; do NOT read `latest_score` or `notes` until Step 5 is done (per AGENTS.md — avoids score anchoring).

### S3 — PATCH submission with snapshot (Step 3)

```bash
exec bash -c '
curl -sS -X PATCH "$SUPABASE_URL/rest/v1/scout_submissions?id=eq.$SUB_ID" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d @- <<'"'"'JSON'"'"'
{"snapshot_json": { ... }, "ticker": "<TICKER>", "factory": "<FACTORY>"}
JSON
'
```

### S4 — PATCH submission final (Step 6)

```bash
exec bash -c '
curl -sS -X PATCH "$SUPABASE_URL/rest/v1/scout_submissions?id=eq.$SUB_ID" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d @- <<'"'"'JSON'"'"'
{
  "thesis_score": 7,
  "token_score": 6.4,
  "final_score": 6.7,
  "modifiers_json": {"thesis_bonus": 0.3},
  "action": "SIGNAL",
  "reject_code": null,
  "reasoning": "<short>",
  "points_awarded": 5,
  "evaluated_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
  "status": "done"
}
JSON
'
```

For rejects: set `status="done"`, `reject_code="NO_CA"|...`, leave scores null, `action=null`, `points_awarded=0`.

### S5 — UPSERT project (Step 6, after final score)

```bash
exec bash -c '
curl -sS -X POST "$SUPABASE_URL/rest/v1/projects" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=minimal" \
  -d @- <<'"'"'JSON'"'"'
{
  "ca": "<0x...>",
  "ticker": "<TICKER>",
  "factory": "<FACTORY>",
  "last_seen_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
  "latest_action": "SIGNAL",
  "latest_score": 6.7,
  "latest_evaluated_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
  "notes": "<append timestamped note>",
  "notes_updated_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
}
JSON
'
```

`resolution=merge-duplicates` performs ON CONFLICT (ca) DO UPDATE. `submission_count` is NOT touched here — increment it in a follow-up PATCH when needed, or leave at default. For the first-seen row, also pass `first_seen_at`, `first_scout_id`, `first_submission_id`.

### S6 — UPSERT scout_points (Step 6, after action decided)

`scout_points` is a flat counter. PostgREST upsert is easier than computing deltas — use `resolution=merge-duplicates` with a full row:

```bash
exec bash -c '
# First read current totals so we can add points_awarded
CURRENT=$(curl -sS -G "$SUPABASE_URL/rest/v1/scout_points" \
  --data-urlencode "scout_id=eq.<scout_id>" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
| jq ".[0] // {}")

# Then upsert with computed sums (action and counts come from evaluation)
curl -sS -X POST "$SUPABASE_URL/rest/v1/scout_points" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=minimal" \
  -d @- <<JSON
{
  "scout_id": "<scout_id>",
  "scout_handle": "<handle>",
  "total_points": $(echo "$CURRENT" | jq ".total_points // 0 | . + 5"),
  "submission_count": $(echo "$CURRENT" | jq ".submission_count // 0 | . + 1"),
  "accepted_count": $(echo "$CURRENT" | jq ".accepted_count // 0 | . + 1"),
  "signal_count": $(echo "$CURRENT" | jq ".signal_count // 0 | . + 1"),
  "trade_count": $(echo "$CURRENT" | jq ".trade_count // 0"),
  "last_submission_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
'
```

For REJECT: only bump `submission_count`, leave `accepted_count` / `signal_count` / `trade_count` unchanged, `total_points` += 0.

---

## GeckoTerminal (public tier, no key)

Base URL: `https://api.geckoterminal.com/api/v2`. Free public tier, ~30 req/min. No auth. Expected load ~0.1 req/min, 300× headroom.

### G1 — Token snapshot (Step 3 primary)

```bash
exec bash -c '
curl -sS "https://api.geckoterminal.com/api/v2/networks/base/tokens/<CA>" \
| jq "{
    ticker:        .data.attributes.symbol,
    name:          .data.attributes.name,
    price_usd:     .data.attributes.price_usd,
    fdv_usd:       .data.attributes.fdv_usd,
    mcap_usd:      .data.attributes.market_cap_usd,
    volume_h24:    .data.attributes.volume_usd.h24,
    total_reserve: .data.attributes.total_reserve_in_usd,
    top_pool:      .data.relationships.top_pools.data[0].id
  }"
'
```

`top_pool` is formatted `base_<0xpool>` — strip the `base_` prefix for G2.

### G2 — Pool detail (Step 3, age + momentum + wallet counts)

```bash
exec bash -c '
curl -sS "https://api.geckoterminal.com/api/v2/networks/base/pools/<POOL_ADDR>" \
| jq "{
    pool_created_at: .data.attributes.pool_created_at,
    reserve_usd:     .data.attributes.reserve_in_usd,
    price_change:    .data.attributes.price_change_percentage,
    volume:          .data.attributes.volume_usd,
    tx_h24:          .data.attributes.transactions.h24,
    tx_h1:           .data.attributes.transactions.h1
  }"
'
```

Use `pool_created_at` for `TOO_OLD` / age check in Step 1. Use `reserve_in_usd` as real LP for `LOW_LIQUIDITY` modifier. `price_change_percentage.{m5,m15,h1,h6,h24}` feeds convergence / momentum in Step 3.

### G3 — Token info (Step 3 / Step 5, the jackpot)

```bash
exec bash -c '
curl -sS "https://api.geckoterminal.com/api/v2/networks/base/tokens/<CA>/info" \
| jq "{
    gt_score:        .data.attributes.gt_score,
    gt_score_detail: .data.attributes.gt_score_details,
    is_honeypot:     .data.attributes.is_honeypot,
    gt_verified:     .data.attributes.gt_verified,
    holders_count:   .data.attributes.holders.count,
    holders_dist:    .data.attributes.holders.distribution_percentage,
    categories:      .data.attributes.categories,
    websites:        .data.attributes.websites,
    twitter:         .data.attributes.twitter_handle,
    telegram:        .data.attributes.telegram_handle,
    farcaster:       .data.attributes.farcaster_url,
    description:     .data.attributes.description
  }"
'
```

`holders.distribution_percentage` has keys `top_10 / 11_30 / 31_50 / rest` — use top_10 for `HIGH_CONCENTRATION` modifier (excluding LP via BaseScan still required for precision; GT's top_10 INCLUDES the LP wallet).

`is_honeypot=true` → automatic REJECT regardless of score. `gt_score < 30` → include in reasoning as concern but do not auto-reject.

---

## BaseScan (via `exec` + `curl`)

Base block explorer for deployer wallet history and LP-adjusted holder concentration. API base: `https://api.basescan.org/api`. Key in `BASESCAN_API_KEY` env var (add to `~/.openclaw/secrets.env` on server when needed — not yet wired).

Use for:
- Deployer address lookup: `?module=contract&action=getcontractcreation&contractaddresses=<CA>`
- Top holders with LP exclusion: scrape `https://basescan.org/token/tokenholderchart/<CA>` (HTML, use `web_fetch` not curl)
- Deployer tx history (DEPLOYER_SELLING modifier): `?module=account&action=tokentx&address=<DEPLOYER>`

For S0 this is optional — use GeckoTerminal `holders.distribution_percentage` as the primary concentration signal and only fall back to BaseScan when `UNVERIFIED_LAUNCH` needs contract source inspection.

---

## factory-registry.json

Workspace config at `config/factory-registry.json`. NOT auto-injected.

```text
read config/factory-registry.json
```

Follow `_detection_priority` in the file. Bankr and Noice have no own factory and MUST match as `doppler` — that is correct, not `UNVERIFIED_LAUNCH`.

---

## Telegram replies

### Scout group reply (automatic)

The channel adapter auto-forwards your text output to the source chat. When you print a reply, it goes to the scout group as a reply to the original submission message. **No tool call required.** Use the templates in `config/reply-templates.json`.

### Cross-channel team alert (`message` tool)

Required for SIGNAL and TRADE — the team review channel is a different group from the scout submission group. Exact call signature (from `src/agents/tools/message-tool.ts:695`, verified live):

```text
message
  action:  "send"
  channel: "telegram"
  target:  "<team_review_group_id>"     // numeric, negative, e.g. -1001234567890
  message: "<formatted alert body>"
```

Target group ID lives in `~/.openclaw/openclaw.json` under `channels.telegram.groups` — ask for the `team_review` key at session start if needed. Format the alert body per `skills/evaluation-output/SKILL.md`.

Optional params you may use: `replyTo` (message id to quote), `threadId` (forum topic id), `interactive` (inline buttons for APPROVE / EDIT / KILL — see telegram docs on the server at `/home/ubuntu/openclaw/docs/channels/telegram.md` if you need button schemas).

DRY RUN: pass `dryRun: true` during calibration to validate the call without actually sending.

---

## Web / X search (Step 5 only)

Builder and narrative research. Call sparingly — one research pass per submission max.

- `web_search "<query>"` → surface-level web results
- `web_fetch "<url>"` → full page content (use for builder GitHub/LinkedIn/personal sites)
- `x_search "<query>"` → X/Twitter search (use for "is this narrative live?" and "is this builder real?")

If unverifiable, state that explicitly in reasoning and score conservatively.

---

## Rules

- **Never** echo `SUPABASE_SERVICE_KEY` or `BASESCAN_API_KEY` into replies, reasoning, notes, or logs.
- **Never** run `openclaw` CLI, `systemctl`, `sudo`, or any command unrelated to HTTP / jq / file reads. The `exec` tool is whitelisted for `curl`, `bash -c`, `sh -c` only.
- **Batch** — one `exec` call per pipeline step where possible. Don't make 5 separate curls when one heredoc can pipe through jq.
- **On curl failure** (`curl exit != 0`, or HTTP 4xx/5xx in response): do NOT retry silently. Write `status="error"` on the submission via S4 with `reasoning` containing the error, then stop. The daily-digest cron will surface errors.
- **Timestamps** — always UTC, ISO 8601, generated via `$(date -u +%Y-%m-%dT%H:%M:%SZ)`.

---

*GP test (S0), Telegram-only. X API integration deferred to S1.*
