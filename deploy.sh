#!/bin/bash
# Judgement Agent — deploy to OpenClaw workspace
# Usage: bash deploy.sh
# Run from repo root after git pull

set -e

WORKSPACE="/home/openclawrun/.openclaw/workspace"
CONFIG="/home/openclawrun/.openclaw/openclaw.json"

echo "→ Copying agent files to workspace..."
sudo cp agent/SOUL.md "$WORKSPACE/"
sudo cp agent/AGENTS.md "$WORKSPACE/"
sudo cp agent/TOOLS.md "$WORKSPACE/"
sudo cp agent/MEMORY.md "$WORKSPACE/"
sudo cp -r agent/skills/ "$WORKSPACE/skills/"
sudo mkdir -p "$WORKSPACE/config"
sudo cp agent/config/factory-registry.json "$WORKSPACE/config/"
sudo cp agent/config/reply-templates.json "$WORKSPACE/config/"

echo "→ Protecting SOUL.md and AGENTS.md..."
sudo chmod 444 "$WORKSPACE/SOUL.md"
sudo chmod 444 "$WORKSPACE/AGENTS.md"

echo "→ Patching openclaw.json (compaction settings)..."
sudo jq '
  .agents.defaults.compaction = {
    "model": "openrouter/auto",
    "mode": "default",
    "reserveTokensFloor": 30000,
    "memoryFlush": {
      "softThresholdTokens": 20000
    }
  }
' "$CONFIG" > /tmp/openclaw_patched.json && sudo mv /tmp/openclaw_patched.json "$CONFIG"

echo "→ Registering cron jobs..."
openclaw cron delete fdv-snapshot 2>/dev/null || true
openclaw cron delete daily-digest 2>/dev/null || true
openclaw cron delete retroactive-upgrade 2>/dev/null || true

openclaw cron add --id fdv-snapshot --schedule "0 0 * * *" --session-target isolated \
  --task "Pull current FDV for all SIGNAL/TRADE tokens from GeckoTerminal and update token_performance table in Supabase. Calculate 1d/7d/14d performance vs signal-time FDV."

openclaw cron add --id daily-digest --schedule "0 1 * * *" --session-target isolated \
  --task "Compile daily digest: todays evaluations summary, acceptance rate, notable scores, points settlement. Post to team review channel."

openclaw cron add --id retroactive-upgrade --schedule "0 2 * * *" --session-target isolated \
  --task "Check all DB_SAVE tokens from last 14 days against any SIGNAL/TRADE actions from any pipeline. If match found, retroactively upgrade original scout points and log to digest."

echo "✓ Done. Config changes apply automatically (hybrid hot-reload)."
