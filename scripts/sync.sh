#!/bin/bash
# Fellowship Sync Script
# Pulls latest config updates and applies to workspace
# Run periodically or when updates are announced

set -e

CONFIG_DIR="$HOME/fellowship-config"
WORKSPACE="$HOME/clawd"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[fellowship]${NC} $1"; }
warn() { echo -e "${YELLOW}[fellowship]${NC} $1"; }
error() { echo -e "${RED}[fellowship]${NC} $1"; exit 1; }

# Check config dir exists
if [ ! -d "$CONFIG_DIR" ]; then
    error "fellowship-config not found. Run bootstrap.sh first."
fi

# Check workspace exists
if [ ! -d "$WORKSPACE" ]; then
    error "Workspace not found at $WORKSPACE"
fi

# Pull latest
log "Pulling latest fellowship-config..."
cd "$CONFIG_DIR"
git pull

# Compare and update base files
log "Syncing base files..."

# AGENTS.md - always sync
if ! cmp -s "$CONFIG_DIR/base/AGENTS.md" "$WORKSPACE/AGENTS.md"; then
    cp "$CONFIG_DIR/base/AGENTS.md" "$WORKSPACE/AGENTS.md"
    log "Updated AGENTS.md"
else
    log "AGENTS.md is current"
fi

# HEARTBEAT.md - always sync
if ! cmp -s "$CONFIG_DIR/base/HEARTBEAT.md" "$WORKSPACE/HEARTBEAT.md"; then
    cp "$CONFIG_DIR/base/HEARTBEAT.md" "$WORKSPACE/HEARTBEAT.md"
    log "Updated HEARTBEAT.md"
else
    log "HEARTBEAT.md is current"
fi

# Install any new required skills
log "Checking skills..."
if command -v clawhub &> /dev/null; then
    while read -r skill; do
        [[ "$skill" =~ ^#.*$ ]] && continue
        [[ -z "$skill" ]] && continue
        # Check if skill is installed (basic check)
        if [ ! -d "$HOME/.openclaw/skills/$skill" ]; then
            log "Installing missing skill: $skill"
            clawhub install "$skill" || warn "Failed to install $skill"
        fi
    done < "$CONFIG_DIR/skills/required.txt"
else
    warn "clawhub not found, skipping skill check"
fi

log "Sync complete! ✅"
log ""
log "Files that are NEVER synced (preserved locally):"
log "  - SOUL.md (your identity)"
log "  - MEMORY.md (your memories)"
log "  - TOOLS.md (machine-specific)"
log "  - memory/* (your logs)"
