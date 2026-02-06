# Fleet Dashboard Scripts

System-level monitoring for OpenClaw agents. Reports status every 5 minutes and processes remote commands.

## What It Does

- **Zero AI tokens burned** — pure bash system stats
- Runs via **system cron** (not OpenClaw cron)
- Collects: uptime, memory, version, session count
- POSTs heartbeat to Fleet Dashboard
- Wakes OpenClaw when commands arrive

## Installation

```bash
cd /path/to/your/agent/workspace
./scripts/fleet-install.sh
```

The installer will:
1. Prompt for agent ID and Fleet API key
2. Create `~/.fleet/config`
3. Add cron job (runs every 5 minutes)
4. Run a test heartbeat

## Configuration

Edit `~/.fleet/config`:

```bash
AGENT_ID="gimli"
DISPLAY_NAME="Gimli"
MACHINE="darth-maul"
FLEET_URL="https://ezupfosdfurwnvsagsix.supabase.co/functions/v1"
FLEET_KEY="tmk_fleet_xxxxxxxxxxxxxxxxxxxxx"
OPENCLAW_BIN="/usr/local/bin/openclaw"
FLEET_LOG="/tmp/fleet-ping-gimli.log"
```

## Manual Usage

```bash
# Run heartbeat once
FLEET_CONFIG=~/.fleet/config ./scripts/fleet-ping.sh

# Check logs
tail -f /tmp/fleet-ping-gimli.log

# Test with custom key
FLEET_KEY="tmk_fleet_xxx" ./scripts/fleet-ping.sh
```

## Cron Job

Installed automatically by `fleet-install.sh`:

```cron
*/5 * * * * FLEET_CONFIG=/home/user/.fleet/config /path/to/fleet-ping.sh >> /tmp/fleet-ping-gimli.log 2>&1
```

View/edit:
```bash
crontab -l          # View
crontab -e          # Edit
```

Remove:
```bash
crontab -e
# Delete the fleet-ping line, save & exit
```

## API Endpoints

The script uses these Fleet Dashboard endpoints:

**POST /heartbeat**
```json
{
  "agent_id": "gimli",
  "display_name": "Gimli",
  "machine": "darth-maul",
  "status": "online",
  "version": "2026.2.2",
  "uptime_hours": 48.5,
  "memory_mb": 512,
  "sessions_active": 3,
  "last_activity": "2026-02-06T01:00:00Z",
  "os": "linux",
  "node_version": "v24.13.0"
}
```

**Response:**
```json
{
  "ok": true,
  "commands": [
    {
      "id": "abc-123",
      "action": "sweep",
      "params": { "mode": "quick" }
    }
  ]
}
```

When commands are received, the script wakes OpenClaw:
```bash
openclaw wake "Fleet commands received. Check /tmp/fleet-commands-gimli.json..."
```

**POST /command-ack/{command_id}**
Acknowledge command received (called by OpenClaw)

**POST /command-complete**
```json
{
  "command_id": "abc-123",
  "success": true,
  "result": { ... }
}
```

## Collected Metrics

| Metric | Source | Notes |
|--------|--------|-------|
| `agent_id` | Config or `whoami` | Unique agent identifier |
| `display_name` | Config | Human-readable name |
| `machine` | `hostname` | Server/laptop name |
| `status` | Process check | `online` or `offline` |
| `version` | `openclaw --version` | OpenClaw version |
| `uptime_hours` | `ps` | How long OpenClaw has been running |
| `memory_mb` | `ps` | RSS memory usage |
| `sessions_active` | `openclaw status` | Active session count (rough) |
| `last_activity` | Current time | Timestamp of heartbeat |
| `os` | `$OSTYPE` | `linux` or `macos` |
| `node_version` | `node --version` | Node.js version |

## Troubleshooting

**Cron job not running:**
```bash
# Check cron daemon is running
sudo systemctl status cron    # Linux
sudo launchctl list | grep cron  # macOS

# Check crontab
crontab -l

# Check logs
tail -f /tmp/fleet-ping-gimli.log
```

**"FLEET_KEY not set":**
- Check `~/.fleet/config` exists and has `FLEET_KEY="tmk_fleet_..."`
- Ensure config file is readable: `chmod 600 ~/.fleet/config`

**Heartbeat fails (HTTP error):**
- Verify Fleet URL is correct
- Check API key is valid (not expired/revoked)
- Test manually: `curl -X POST "$FLEET_URL/heartbeat" -H "Authorization: Bearer $FLEET_KEY" -d '{"agent_id":"test"}'`

**OpenClaw not waking:**
- Check `openclaw` binary is in PATH: `which openclaw`
- Set `OPENCLAW_BIN` in config if needed
- Verify OpenClaw gateway is running: `openclaw status`

## Security Notes

- **API key in config:** `~/.fleet/config` is chmod 600 (owner-only read)
- **Logs:** Contain no sensitive data (just system stats)
- **Network:** HTTPS only, authenticated via Bearer token
- **Commands:** Validated and processed by OpenClaw (not executed blindly by bash)

## Uninstall

```bash
# Remove cron job
crontab -e
# Delete the fleet-ping line

# Remove config
rm -rf ~/.fleet

# Remove scripts (optional)
rm scripts/fleet-*.sh
```

---

**Built by:** Gimli (Backend Engineer)  
**For:** Fleet Dashboard — Agent monitoring & control  
**Requested by:** Aragorn (DevOps & Security)  
**Date:** 2026-02-06
