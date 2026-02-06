#!/bin/bash
# Fellowship Bootstrap Script
# Usage: ./bootstrap.sh <agent-name>
# Or:    curl -sL https://raw.githubusercontent.com/Temaki-AI/fellowship-config/main/scripts/bootstrap.sh | bash -s <agent-name>

set -e

AGENT_NAME="${1:-}"
REPO_URL="https://github.com/Temaki-AI/fellowship-config.git"
CONFIG_DIR="$HOME/fellowship-config"
WORKSPACE="$HOME/clawd"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[fellowship]${NC} $1"; }
warn() { echo -e "${YELLOW}[fellowship]${NC} $1"; }
error() { echo -e "${RED}[fellowship]${NC} $1"; exit 1; }

# Validate agent name
if [ -z "$AGENT_NAME" ]; then
    error "Usage: $0 <agent-name>\nValid agents: gandalf, sam, frodo, aragorn, pippin, gimli"
fi

VALID_AGENTS="gandalf sam frodo aragorn pippin gimli"
if ! echo "$VALID_AGENTS" | grep -qw "$AGENT_NAME"; then
    error "Unknown agent: $AGENT_NAME\nValid agents: $VALID_AGENTS"
fi

log "Bootstrapping agent: $AGENT_NAME"

# Clone or update config repo
if [ -d "$CONFIG_DIR" ]; then
    log "Updating fellowship-config..."
    cd "$CONFIG_DIR" && git pull
else
    log "Cloning fellowship-config..."
    git clone "$REPO_URL" "$CONFIG_DIR"
fi

# Create workspace if needed
if [ ! -d "$WORKSPACE" ]; then
    log "Creating workspace at $WORKSPACE..."
    mkdir -p "$WORKSPACE"
fi

# Copy base files (always overwrite)
log "Copying base files..."
cp "$CONFIG_DIR/base/AGENTS.md" "$WORKSPACE/AGENTS.md"
cp "$CONFIG_DIR/base/HEARTBEAT.md" "$WORKSPACE/HEARTBEAT.md"

# Copy SOUL.md only if it doesn't exist
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
    log "Copying SOUL.md for $AGENT_NAME..."
    cp "$CONFIG_DIR/agents/$AGENT_NAME/SOUL.md" "$WORKSPACE/SOUL.md"
else
    warn "SOUL.md already exists, skipping (preserving identity)"
fi

# Copy TOOLS.md template only if it doesn't exist
if [ ! -f "$WORKSPACE/TOOLS.md" ]; then
    log "Copying TOOLS.md template..."
    cp "$CONFIG_DIR/base/TOOLS.md.template" "$WORKSPACE/TOOLS.md"
    warn "Edit TOOLS.md with machine-specific details!"
else
    warn "TOOLS.md already exists, skipping"
fi

# Create memory directory if needed
if [ ! -d "$WORKSPACE/memory" ]; then
    log "Creating memory directory..."
    mkdir -p "$WORKSPACE/memory"
fi

# Create USER.md if it doesn't exist
if [ ! -f "$WORKSPACE/USER.md" ]; then
    log "Creating USER.md placeholder..."
    cat > "$WORKSPACE/USER.md" << 'EOF'
# USER.md - About Your Human

- **Name:** Miguel Amaral (fmfamaral)
- **Email:** fmfamaral@gmail.com
- **Timezone:** Europe/Lisbon

*Add more details as you learn about your human.*
EOF
fi

# Install required skills
log "Installing required skills..."
if command -v clawhub &> /dev/null; then
    while read -r skill; do
        # Skip comments and empty lines
        [[ "$skill" =~ ^#.*$ ]] && continue
        [[ -z "$skill" ]] && continue
        log "Installing skill: $skill"
        clawhub install "$skill" || warn "Failed to install $skill (may already exist)"
    done < "$CONFIG_DIR/skills/required.txt"
else
    warn "clawhub not found, skipping skill installation"
    warn "Install skills manually: clawhub install <skill-name>"
fi

log "Bootstrap complete! 🎉"
log ""
log "Next steps:"
log "  1. Edit $WORKSPACE/TOOLS.md with machine-specific details"
log "  2. Set up credentials in .credentials/ directories"
log "  3. Configure OpenClaw for this agent"
log ""
log "To sync future updates: ~/fellowship-config/scripts/sync.sh"
