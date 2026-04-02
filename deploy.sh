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

echo "→ Writing cron jobs to jobs.json..."
CRON_DIR="/home/openclawrun/.openclaw/cron"
sudo mkdir -p "$CRON_DIR"

sudo tee "$CRON_DIR/jobs.json" > /dev/null << 'EOF'
{
  "version": 1,
  "jobs": [
    {
      "id": "fdv-snapshot",
      "name": "fdv-snapshot",
      "enabled": true,
      "schedule": {
        "kind": "cron",
        "expr": "0 0 * * *"
      },
      "sessionTarget": "isolated",
      "payload": {
        "kind": "agentTurn",
        "message": "Pull current FDV for all SIGNAL/TRADE tokens from GeckoTerminal and update token_performance table in Supabase. Calculate 1d/7d/14d performance vs signal-time FDV.",
        "timeoutSeconds": 900
      },
      "delivery": {
        "mode": "none"
      }
    },
    {
      "id": "daily-digest",
      "name": "daily-digest",
      "enabled": true,
      "schedule": {
        "kind": "cron",
        "expr": "0 1 * * *"
      },
      "sessionTarget": "isolated",
      "payload": {
        "kind": "agentTurn",
        "message": "Compile daily digest: todays evaluations summary, acceptance rate, notable scores, points settlement. Post to team review channel.",
        "timeoutSeconds": 900
      },
      "delivery": {
        "mode": "none"
      }
    },
    {
      "id": "retroactive-upgrade",
      "name": "retroactive-upgrade",
      "enabled": true,
      "schedule": {
        "kind": "cron",
        "expr": "0 2 * * *"
      },
      "sessionTarget": "isolated",
      "payload": {
        "kind": "agentTurn",
        "message": "Check all DB_SAVE tokens from last 14 days against any SIGNAL/TRADE actions from any pipeline. If match found, retroactively upgrade original scout points and log to digest.",
        "timeoutSeconds": 900
      },
      "delivery": {
        "mode": "none"
      }
    }
  ]
}
EOF

echo "✓ Done. Config changes apply automatically (hybrid hot-reload)."
