---
name: email
description: Manage your temaki.ai email. Check inbox, read messages, send emails, search, list folders. Use for any email-related task.
---

# Email

Each agent has their own email: `<agentname>@temaki.ai`
Credentials: `.credentials/email.json` in your workspace (gitignored, never log or expose)

## Usage

All operations via the email client script:

```bash
python3 skills/email/scripts/email_client.py <command> [options]
```

### Commands

**Check inbox:**
```bash
python3 skills/email/scripts/email_client.py inbox           # last 20 messages
python3 skills/email/scripts/email_client.py inbox -n 5      # last 5
python3 skills/email/scripts/email_client.py inbox -u        # unread only
```

**Quick count (lightweight — use for heartbeat checks):**
```bash
python3 skills/email/scripts/email_client.py count
```

**Read a message:**
```bash
python3 skills/email/scripts/email_client.py read <ID>
```

**Send:**
```bash
python3 skills/email/scripts/email_client.py send --to "addr" --subject "subj" --body "text"
python3 skills/email/scripts/email_client.py send --to "addr" --cc "cc1,cc2" --subject "subj" --body "text"
```

**Search:**
```bash
python3 skills/email/scripts/email_client.py search --from "addr"
python3 skills/email/scripts/email_client.py search --subject "keyword"
python3 skills/email/scripts/email_client.py search --text "anything"
python3 skills/email/scripts/email_client.py search --since "29-Jan-2026"
```

**List folders:**
```bash
python3 skills/email/scripts/email_client.py folders
```

## Security Rules

- Never log, print, or store the password outside `.credentials/`
- Never send credentials in chat messages or memory files
- When sending emails externally, be professional — you represent your agent identity and Miguel.
- Ask before sending to external addresses (outside temaki.ai) unless explicitly told to send.

## Mailbox Info

- Provider: Roundcube webmail at webmail.temaki.ai
- IMAP: webmail.temaki.ai:993 (SSL/TLS)
- SMTP: webmail.temaki.ai:465 (SSL/TLS)
- Folders: INBOX, Sent, Trash, Spam, Drafts

## Setup

Credentials file `.credentials/email.json` is auto-created by `create-bot.sh`. Format:

```json
{
  "email": "<agent>@temaki.ai",
  "password": "...",
  "imap": { "server": "webmail.temaki.ai", "port": 993, "security": "SSL/TLS", "username": "<agent>@temaki.ai" },
  "smtp": { "server": "webmail.temaki.ai", "port": 465, "security": "SSL/TLS", "username": "<agent>@temaki.ai" }
}
```
