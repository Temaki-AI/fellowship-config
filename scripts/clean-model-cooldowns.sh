#!/bin/bash
#
# clean-model-cooldowns.sh — Remove model cooldown settings from OpenClaw config
#
# Works on both macOS and Linux
#

set -euo pipefail

# Configuration
CONFIG_PATH="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
BACKUP_SUFFIX=".pre-cooldown-clean"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}✅${NC} $*"
}

warn() {
  echo -e "${YELLOW}⚠️${NC}  $*"
}

error() {
  echo -e "${RED}❌${NC} $*"
  exit 1
}

# Check prerequisites
if ! command -v jq &> /dev/null; then
  error "jq is required but not installed.\n   Install: brew install jq (macOS) or sudo apt install jq (Linux)"
fi

if [ ! -f "$CONFIG_PATH" ]; then
  error "Config file not found: $CONFIG_PATH"
fi

echo "🧹 OpenClaw Model Cooldown Cleaner"
echo ""
echo "Config file: $CONFIG_PATH"
echo ""

# Backup config
BACKUP_PATH="${CONFIG_PATH}${BACKUP_SUFFIX}"
cp "$CONFIG_PATH" "$BACKUP_PATH"
log "Backup created: $BACKUP_PATH"

# Check if there are any cooldown settings
COOLDOWN_COUNT=$(jq '
  [
    (.. | objects | 
      select(has("cooldownSeconds") or has("cooldown") or has("rateLimitCooldown"))
    )
  ] | length
' "$CONFIG_PATH")

if [ "$COOLDOWN_COUNT" -eq 0 ]; then
  warn "No cooldown settings found in config"
  rm "$BACKUP_PATH"
  echo ""
  echo "Nothing to clean. Exiting."
  exit 0
fi

echo "Found $COOLDOWN_COUNT cooldown setting(s)"
echo ""

# Show what will be removed
echo "Preview of changes:"
jq -r '
  .. | objects | 
  select(has("cooldownSeconds") or has("cooldown") or has("rateLimitCooldown")) |
  to_entries[] |
  select(.key | test("cooldown|Cooldown")) |
  "  - \(.key): \(.value)"
' "$CONFIG_PATH" || true

echo ""
read -p "Remove these cooldown settings? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  warn "Cancelled by user"
  rm "$BACKUP_PATH"
  exit 0
fi

# Remove cooldown settings
jq '
  # Function to recursively remove cooldown keys
  walk(
    if type == "object" then
      del(.cooldownSeconds, .cooldown, .rateLimitCooldown)
    else
      .
    end
  )
' "$CONFIG_PATH" > "${CONFIG_PATH}.tmp"

# Replace config with cleaned version
mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"

log "Cooldown settings removed from config"
echo ""
echo "📝 Summary:"
echo "   - Backup: $BACKUP_PATH"
echo "   - Cleaned: $CONFIG_PATH"
echo "   - Settings removed: $COOLDOWN_COUNT"
echo ""
echo "💡 Tip: Restart OpenClaw gateway for changes to take effect:"
echo "   openclaw gateway restart"
echo ""
echo "🔄 To restore the backup if needed:"
echo "   cp $BACKUP_PATH $CONFIG_PATH"
