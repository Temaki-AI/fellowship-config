#!/usr/bin/env python3
"""
clean-model-cooldowns.py — Remove model cooldown settings from OpenClaw config

Works on macOS and Linux. Removes:
- cooldownSeconds
- cooldown
- rateLimitCooldown

From all models in the config file.
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime

# Configuration
CONFIG_PATH = os.environ.get('OPENCLAW_CONFIG', Path.home() / '.openclaw' / 'openclaw.json')
BACKUP_SUFFIX = '.pre-cooldown-clean'

def remove_cooldowns(obj):
    """Recursively remove cooldown keys from nested dicts."""
    if isinstance(obj, dict):
        # Remove cooldown keys
        obj = {k: v for k, v in obj.items() 
               if k not in ('cooldownSeconds', 'cooldown', 'rateLimitCooldown')}
        # Recurse into remaining values
        return {k: remove_cooldowns(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [remove_cooldowns(item) for item in obj]
    else:
        return obj

def count_cooldowns(obj):
    """Count cooldown settings in nested structure."""
    count = 0
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in ('cooldownSeconds', 'cooldown', 'rateLimitCooldown'):
                count += 1
            count += count_cooldowns(v)
    elif isinstance(obj, list):
        for item in obj:
            count += count_cooldowns(item)
    return count

def main():
    print("🧹 OpenClaw Model Cooldown Cleaner")
    print()
    
    # Check config exists
    if not Path(CONFIG_PATH).exists():
        print(f"❌ Config file not found: {CONFIG_PATH}")
        sys.exit(1)
    
    print(f"Config file: {CONFIG_PATH}")
    print()
    
    # Load config
    with open(CONFIG_PATH, 'r') as f:
        config = json.load(f)
    
    # Count cooldowns
    cooldown_count = count_cooldowns(config)
    
    if cooldown_count == 0:
        print("⚠️  No cooldown settings found in config")
        print()
        print("Nothing to clean. Exiting.")
        sys.exit(0)
    
    print(f"Found {cooldown_count} cooldown setting(s)")
    print()
    
    # Create backup
    backup_path = f"{CONFIG_PATH}{BACKUP_SUFFIX}"
    with open(backup_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"✅ Backup created: {backup_path}")
    print()
    
    # Confirm
    response = input("Remove cooldown settings? [y/N] ").strip().lower()
    if response not in ('y', 'yes'):
        print("⚠️  Cancelled by user")
        os.remove(backup_path)
        sys.exit(0)
    
    # Remove cooldowns
    cleaned_config = remove_cooldowns(config)
    
    # Write cleaned config
    with open(CONFIG_PATH, 'w') as f:
        json.dump(cleaned_config, f, indent=2)
    
    print("✅ Cooldown settings removed from config")
    print()
    print("📝 Summary:")
    print(f"   - Backup: {backup_path}")
    print(f"   - Cleaned: {CONFIG_PATH}")
    print(f"   - Settings removed: {cooldown_count}")
    print()
    print("💡 Tip: Restart OpenClaw gateway for changes to take effect:")
    print("   openclaw gateway restart")
    print()
    print("🔄 To restore the backup if needed:")
    print(f"   cp {backup_path} {CONFIG_PATH}")

if __name__ == '__main__':
    main()
