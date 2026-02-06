# Email Skill Installation

This is a custom Python-based email client for temaki.ai agents.

## Install

```bash
# Copy skill to OpenClaw skills directory
mkdir -p ~/.openclaw/skills/email/scripts
cp SKILL.md ~/.openclaw/skills/email/
cp scripts/email_client.py ~/.openclaw/skills/email/scripts/

# Create workspace credentials directory
mkdir -p ~/clawd/.credentials

# Copy and edit credentials template
cp credentials.template.json ~/clawd/.credentials/email.json
# Edit email.json with your agent's email and password
```

## Credentials Format

```json
{
  "email": "sam@temaki.ai",
  "password": "YOUR_PASSWORD",
  "webmail": "https://webmail.temaki.ai/",
  "imap": {
    "server": "webmail.temaki.ai",
    "port": 993,
    "security": "SSL/TLS",
    "username": "sam@temaki.ai"
  },
  "smtp": {
    "server": "webmail.temaki.ai",
    "port": 465,
    "security": "SSL/TLS",
    "username": "sam@temaki.ai"
  }
}
```

**IMPORTANT:** Server is `webmail.temaki.ai` (NOT `mail.temaki.ai`)

## Test

```bash
cd ~/clawd
python3 ~/.openclaw/skills/email/scripts/email_client.py count
```

Should output: `Total: X, Unread: Y`
