#!/bin/bash
#
# fleet-ping.sh — Fleet Dashboard heartbeat for OpenClaw agents
#
# Runs every 5 minutes via cron to report agent status and check for commands.
# Zero AI tokens burned — pure bash system stats.
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Load config from file if it exists
CONFIG_FILE="${FLEET_CONFIG:-$HOME/.fleet/config}"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

# Fallback to environment variables or defaults
FLEET_URL="${FLEET_URL:-https://ezupfosdfurwnvsagsix.supabase.co/functions/v1}"
FLEET_KEY="${FLEET_KEY:-}"
AGENT_ID="${AGENT_ID:-$(whoami)}"
MACHINE="${MACHINE:-$(hostname)}"

# Paths
OPENCLAW_BIN="${OPENCLAW_BIN:-$(which openclaw 2>/dev/null || echo '')}"
COMMAND_FILE="/tmp/fleet-commands-${AGENT_ID}.json"
LOG_FILE="${FLEET_LOG:-/tmp/fleet-ping-${AGENT_ID}.log}"

# ============================================================================
# Helpers
# ============================================================================

log() {
  echo "[$(date -Iseconds)] $*" >> "$LOG_FILE"
}

error() {
  log "ERROR: $*"
  exit 1
}

# ============================================================================
# Collect System Stats
# ============================================================================

collect_stats() {
  local status="online"
  local version="unknown"
  local uptime_hours=0
  local memory_mb=0
  local sessions_active=0
  local last_activity=""
  local os_type=""
  local node_version=""
  
  # Detect OS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    os_type="linux"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    os_type="macos"
  else
    os_type="$OSTYPE"
  fi
  
  # OpenClaw version
  if [ -n "$OPENCLAW_BIN" ] && [ -x "$OPENCLAW_BIN" ]; then
    version=$($OPENCLAW_BIN --version 2>/dev/null | head -1 | awk '{print $NF}' || echo "unknown")
  fi
  
  # Node version
  node_version=$(node --version 2>/dev/null || echo "unknown")
  
  # OpenClaw process stats (memory, uptime)
  local openclaw_pid=$(pgrep -f "openclaw-gateway" | head -1 || echo "")
  
  if [ -n "$openclaw_pid" ]; then
    # Get memory usage (works on both Linux and macOS)
    if [[ "$os_type" == "linux" ]]; then
      memory_mb=$(ps -p "$openclaw_pid" -o rss= | awk '{print int($1/1024)}' || echo 0)
      uptime_seconds=$(ps -p "$openclaw_pid" -o etimes= | tr -d ' ' || echo 0)
    elif [[ "$os_type" == "macos" ]]; then
      memory_mb=$(ps -p "$openclaw_pid" -o rss= | awk '{print int($1/1024)}' || echo 0)
      uptime_seconds=$(ps -p "$openclaw_pid" -o etime= | awk -F: '{if (NF==3) print ($1*3600)+($2*60)+$3; else if (NF==2) print ($1*60)+$2; else print $1}' || echo 0)
    fi
    uptime_hours=$(echo "scale=2; $uptime_seconds / 3600" | bc -l 2>/dev/null || echo 0)
    
    # Count active sessions (rough estimate from openclaw status)
    sessions_active=$($OPENCLAW_BIN status 2>/dev/null | grep -c "session" || echo 0)
    
    # Last activity (use current time for now — could parse logs later)
    last_activity=$(date -Iseconds)
  else
    status="offline"
  fi
  
  # Build JSON payload
  cat <<EOF
{
  "agent_id": "$AGENT_ID",
  "display_name": "${DISPLAY_NAME:-$AGENT_ID}",
  "machine": "$MACHINE",
  "status": "$status",
  "version": "$version",
  "uptime_hours": $uptime_hours,
  "memory_mb": $memory_mb,
  "sessions_active": $sessions_active,
  "last_activity": "$last_activity",
  "os": "$os_type",
  "node_version": "$node_version"
}
EOF
}

# ============================================================================
# Send Heartbeat
# ============================================================================

send_heartbeat() {
  local payload="$1"
  
  log "Sending heartbeat for $AGENT_ID on $MACHINE"
  
  # Send request (include x-api-key header if FLEET_KEY is set)
  if [ -n "$FLEET_KEY" ]; then
    local response=$(curl -s -w "\n%{http_code}" -X POST "$FLEET_URL/heartbeat" \
      -H "Content-Type: application/json" \
      -H "x-api-key: $FLEET_KEY" \
      -d "$payload" \
      --max-time 10 \
      2>&1 || echo "000")
  else
    local response=$(curl -s -w "\n%{http_code}" -X POST "$FLEET_URL/heartbeat" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      --max-time 10 \
      2>&1 || echo "000")
  fi
  
  local http_code=$(echo "$response" | tail -1)
  local body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" != "200" ]; then
    log "Heartbeat failed (HTTP $http_code): $body"
    return 1
  fi
  
  echo "$body"
}

# ============================================================================
# Process Commands
# ============================================================================

process_commands() {
  local response="$1"
  
  # Parse command count
  local command_count=$(echo "$response" | jq -r '.commands // [] | length' 2>/dev/null || echo 0)
  
  if [ "$command_count" -eq 0 ]; then
    log "No commands pending"
    return 0
  fi
  
  log "Received $command_count command(s)"
  
  # Save commands to file
  echo "$response" > "$COMMAND_FILE"
  
  # Wake OpenClaw to process commands
  if [ -n "$OPENCLAW_BIN" ] && [ -x "$OPENCLAW_BIN" ]; then
    log "Waking OpenClaw to process fleet commands"
    $OPENCLAW_BIN wake "Fleet commands received. Check $COMMAND_FILE and process per fleet skill." 2>&1 | head -5 >> "$LOG_FILE"
  else
    log "WARNING: OpenClaw binary not found, cannot wake agent"
  fi
}

# ============================================================================
# Main
# ============================================================================

main() {
  # Validate config
  if [ -z "$FLEET_KEY" ]; then
    error "FLEET_KEY not set. Configure via $CONFIG_FILE or environment variable."
  fi
  
  # Collect stats
  payload=$(collect_stats)
  
  # Send heartbeat
  response=$(send_heartbeat "$payload")
  
  if [ $? -eq 0 ]; then
    # Process any commands
    process_commands "$response"
  fi
  
  log "Heartbeat complete"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
