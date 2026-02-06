# Model Cooldown Cleaner

Remove model cooldown settings from OpenClaw configuration files.

## Problem

OpenClaw model configurations can have cooldown settings that limit how frequently you can use certain models:
```json
{
  "models": {
    "anthropic/claude-opus-4-5": {
      "cooldownSeconds": 60,
      "rateLimitCooldown": 300
    }
  }
}
```

These settings can be annoying during development or testing. This script removes them.

## Usage

**Python version (recommended for macOS):**
```bash
./scripts/clean-model-cooldowns.py
```

**Bash version:**
```bash
./scripts/clean-model-cooldowns.sh
```

Both scripts:
- ✅ Work on macOS and Linux
- ✅ Create automatic backups
- ✅ Show preview before making changes
- ✅ Ask for confirmation

## What Gets Removed

The script removes these keys from anywhere in the config:
- `cooldownSeconds`
- `cooldown`
- `rateLimitCooldown`

## Example

**Before:**
```json
{
  "agents": {
    "defaults": {
      "models": {
        "anthropic/claude-opus-4-5": {
          "alias": "opus",
          "cooldownSeconds": 60,
          "params": {
            "cacheControlTtl": "1h"
          }
        }
      }
    }
  }
}
```

**After:**
```json
{
  "agents": {
    "defaults": {
      "models": {
        "anthropic/claude-opus-4-5": {
          "alias": "opus",
          "params": {
            "cacheControlTtl": "1h"
          }
        }
      }
    }
  }
}
```

## Requirements

**Python version:**
- Python 3 (pre-installed on macOS)

**Bash version:**
- `jq` — Install with `brew install jq` (macOS) or `sudo apt install jq` (Linux)

## Safety

- ✅ **Automatic backup** created before any changes
- ✅ **Preview** shows what will be removed
- ✅ **Confirmation** required before proceeding
- ✅ **Easy restore** — copy backup file back if needed

**Backup location:**
```
~/.openclaw/openclaw.json.pre-cooldown-clean
```

## After Running

Restart OpenClaw gateway for changes to take effect:
```bash
openclaw gateway restart
```

## Restore Backup

If something goes wrong:
```bash
cp ~/.openclaw/openclaw.json.pre-cooldown-clean ~/.openclaw/openclaw.json
openclaw gateway restart
```

## Custom Config Path

If your config is elsewhere:
```bash
OPENCLAW_CONFIG=/path/to/config.json ./scripts/clean-model-cooldowns.py
```

---

**Built by:** Gimli (Backend Engineer)  
**For:** Fellowship agents — clean development environments  
**Date:** 2026-02-06
