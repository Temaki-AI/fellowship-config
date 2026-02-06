#!/bin/bash
#
# fleet-install.sh — Install fleet-ping.sh cron job for OpenClaw agent monitoring
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLEET_PING="$SCRIPT_DIR/fleet-ping.sh"
CONFIG_DIR="$HOME/.fleet"
CONFIG_FILE="$CONFIG_DIR/config"

echo "🚀 Fleet Dashboard Agent Installer"
echo ""

# ============================================================================
# Check prerequisites
# ============================================================================

echo "Checking prerequisites..."

if ! command -v jq &> /dev/null; then
  echo "❌ jq is required but not installed."
  echo "   Install: sudo apt install jq (Linux) or brew install jq (macOS)"
  exit 1
fi

if ! command -v bc &> /dev/null; then
  echo "❌ bc is required but not installed."
  echo "   Install: sudo apt install bc (Linux) or brew install bc (macOS)"
  exit 1
fi

if [ ! -f "$FLEET_PING" ]; then
  echo "❌ fleet-ping.sh not found at $FLEET_PING"
  exit 1
fi

echo "✅ Prerequisites OK"
echo ""

# ============================================================================
# Configure
# ============================================================================

echo "Configuration:"
echo ""

# Agent ID
read -p "Agent ID (e.g. gandalf, gimli): " -i "$(whoami)" -e AGENT_ID
AGENT_ID=${AGENT_ID:-$(whoami)}

# Display name
read -p "Display name (e.g. Gandalf, Gimli): " -i "$(echo $AGENT_ID | sed 's/.*/\u&/')" -e DISPLAY_NAME
DISPLAY_NAME=${DISPLAY_NAME:-$AGENT_ID}

# Fleet API key
echo ""
echo "Fleet API key:"
echo "  Get this from the Fleet Dashboard (Settings → API Keys)"
read -p "API Key (tmk_fleet_...): " FLEET_KEY

if [ -z "$FLEET_KEY" ]; then
  echo "❌ Fleet API key is required"
  exit 1
fi

# Fleet URL (optional override)
FLEET_URL="https://ezupfosdfurwnvsagsix.supabase.co/functions/v1"
read -p "Fleet URL [$FLEET_URL]: " CUSTOM_URL
FLEET_URL=${CUSTOM_URL:-$FLEET_URL}

echo ""
echo "Summary:"
echo "  Agent ID: $AGENT_ID"
echo "  Display:  $DISPLAY_NAME"
echo "  Machine:  $(hostname)"
echo "  Fleet:    $FLEET_URL"
echo ""

read -p "Install? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Installation cancelled."
  exit 0
fi

# ============================================================================
# Create config
# ============================================================================

echo "Creating config at $CONFIG_FILE..."

mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<EOF
# Fleet Dashboard configuration
# Generated: $(date -Iseconds)

AGENT_ID="$AGENT_ID"
DISPLAY_NAME="$DISPLAY_NAME"
MACHINE="$(hostname)"
FLEET_URL="$FLEET_URL"
FLEET_KEY="$FLEET_KEY"
OPENCLAW_BIN="$(which openclaw)"
FLEET_LOG="/tmp/fleet-ping-${AGENT_ID}.log"
EOF

chmod 600 "$CONFIG_FILE"
echo "✅ Config saved"

# ============================================================================
# Make script executable
# ============================================================================

chmod +x "$FLEET_PING"
echo "✅ Script executable"

# ============================================================================
# Install cron job
# ============================================================================

echo ""
echo "Installing cron job (runs every 5 minutes)..."

CRON_CMD="*/5 * * * * FLEET_CONFIG=$CONFIG_FILE $FLEET_PING >> /tmp/fleet-ping-${AGENT_ID}.log 2>&1"

# Check if already installed
if crontab -l 2>/dev/null | grep -F "$FLEET_PING" > /dev/null; then
  echo "⚠️  Cron job already exists. Updating..."
  (crontab -l 2>/dev/null | grep -v "$FLEET_PING"; echo "$CRON_CMD") | crontab -
else
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
fi

echo "✅ Cron job installed"

# ============================================================================
# Test run
# ============================================================================

echo ""
echo "Running test heartbeat..."

export FLEET_CONFIG="$CONFIG_FILE"
if "$FLEET_PING"; then
  echo "✅ Test successful!"
else
  echo "⚠️  Test failed. Check log: /tmp/fleet-ping-${AGENT_ID}.log"
fi

# ============================================================================
# Done
# ============================================================================

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  • Check log: tail -f /tmp/fleet-ping-${AGENT_ID}.log"
echo "  • View cron: crontab -l | grep fleet"
echo "  • Uninstall: crontab -e (remove the fleet-ping line)"
echo ""
echo "The agent will report status every 5 minutes."
echo "Check the Fleet Dashboard to see your agent online!"
