# Fellowship Config

Shared configuration for Miguel's AI Fellowship — consistent tooling, skills, and operating guidelines across all agents.

## Agents

| Agent | Role | Machine |
|-------|------|---------|
| Gandalf | Chief of Staff & Architect | darth-maul |
| Aragorn | Senior DevOps & Security | darth-maul |
| Pippin | Senior Frontend Engineer | darth-maul |
| Gimli | Senior Backend Engineer | darth-maul |
| Sam | Content & Growth Strategist | Fernandos-MBP-3 |
| Frodo | Executive Assistant | Fernandos-MBP-3 |

## Structure

```
fellowship-config/
├── base/                    # Shared across ALL agents
│   ├── AGENTS.md           # Operating guidelines
│   ├── HEARTBEAT.md        # Standard periodic checks
│   └── TOOLS.md.template   # Template for machine-specific config
├── agents/                  # Per-agent identity (SOUL.md)
│   ├── gandalf/
│   ├── sam/
│   └── ...
├── skills/
│   ├── required.txt        # Skills to install via clawhub
│   └── custom/             # Fellowship-specific skills
└── scripts/
    ├── bootstrap.sh        # Fresh machine setup
    └── sync.sh             # Pull latest updates
```

## Usage

### Fresh Machine Setup
```bash
curl -sL https://raw.githubusercontent.com/Temaki-AI/fellowship-config/main/scripts/bootstrap.sh | bash -s <agent-name>
```

### Sync Updates (run by agent)
```bash
~/fellowship-config/scripts/sync.sh
```

## What Gets Synced

| File | Sync Behavior |
|------|---------------|
| `AGENTS.md` | Overwrite (shared guidelines) |
| `HEARTBEAT.md` | Overwrite (shared checks) |
| `skills/*` | Install missing |
| `SOUL.md` | Copy only if missing (never overwrite) |
| `MEMORY.md` | Never touch |
| `TOOLS.md` | Never touch (machine-specific) |
| `memory/*` | Never touch |

## Credentials

Credentials are **never** stored in this repo. Each machine manages its own:
- `~/.openclaw/openclaw.json` (API keys, tokens)
- `.credentials/` directories in skills
