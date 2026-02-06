#!/usr/bin/env python3
"""
Email client — IMAP/SMTP operations for temaki.ai agents.
Credentials read from workspace .credentials/email.json (CWD-relative).
"""

import argparse
import email
import email.utils
import imaplib
import json
import os
import smtplib
import sys
from email.header import decode_header
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path


def load_creds():
    # Look for credentials relative to CWD (workspace root), then fallback to script-relative
    candidates = [
        Path.cwd() / ".credentials" / "email.json",
        Path(__file__).resolve().parents[3] / ".credentials" / "email.json",
    ]
    for cred_path in candidates:
        if cred_path.exists():
            with open(cred_path) as f:
                return json.load(f)
    print(f"ERROR: Credentials not found. Searched: {[str(p) for p in candidates]}", file=sys.stderr)
    sys.exit(1)


def decode_str(value):
    if value is None:
        return ""
    parts = decode_header(value)
    result = []
    for part, charset in parts:
        if isinstance(part, bytes):
            result.append(part.decode(charset or "utf-8", errors="replace"))
        else:
            result.append(part)
    return " ".join(result)


def get_body(msg):
    """Extract plain text body from email message."""
    if msg.is_multipart():
        for part in msg.walk():
            ct = part.get_content_type()
            if ct == "text/plain":
                payload = part.get_payload(decode=True)
                charset = part.get_content_charset() or "utf-8"
                return payload.decode(charset, errors="replace")
            elif ct == "text/html":
                payload = part.get_payload(decode=True)
                charset = part.get_content_charset() or "utf-8"
                return f"[HTML]\n{payload.decode(charset, errors='replace')}"
    else:
        payload = msg.get_payload(decode=True)
        if payload:
            charset = msg.get_content_charset() or "utf-8"
            return payload.decode(charset, errors="replace")
    return "[No readable body]"


def connect_imap(creds):
    imap = imaplib.IMAP4_SSL(creds["imap"]["server"], creds["imap"]["port"])
    imap.login(creds["email"], creds["password"])
    return imap


def cmd_inbox(args):
    creds = load_creds()
    imap = connect_imap(creds)
    imap.select("INBOX")

    status_filter = "UNSEEN" if args.unread else "ALL"
    _, msg_nums = imap.search(None, status_filter)
    ids = msg_nums[0].split()

    if not ids:
        print("Inbox is empty." if not args.unread else "No unread messages.")
        imap.logout()
        return

    # Get latest N
    ids = ids[-(args.limit):]
    ids.reverse()

    print(f"{'ID':>6} | {'Date':20} | {'From':30} | Subject")
    print("-" * 100)

    for mid in ids:
        _, data = imap.fetch(mid, "(BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE)] FLAGS)")
        raw = data[0][1]
        msg = email.message_from_bytes(raw)
        flags_raw = data[0][0].decode() if data[0][0] else ""
        unread = "\\Seen" not in flags_raw

        from_addr = decode_str(msg.get("From", ""))[:30]
        subject = decode_str(msg.get("Subject", "(no subject)"))
        date_str = msg.get("Date", "")
        try:
            date_parsed = email.utils.parsedate_to_datetime(date_str)
            date_fmt = date_parsed.strftime("%Y-%m-%d %H:%M")
        except Exception:
            date_fmt = date_str[:20]

        marker = "●" if unread else " "
        print(f"{mid.decode():>6} {marker}| {date_fmt:20} | {from_addr:30} | {subject}")

    imap.logout()


def cmd_read(args):
    creds = load_creds()
    imap = connect_imap(creds)
    imap.select("INBOX")

    _, data = imap.fetch(str(args.id).encode(), "(RFC822)")
    if not data or data[0] is None:
        print(f"Message {args.id} not found.")
        imap.logout()
        return

    msg = email.message_from_bytes(data[0][1])

    print(f"From:    {decode_str(msg.get('From', ''))}")
    print(f"To:      {decode_str(msg.get('To', ''))}")
    print(f"Date:    {msg.get('Date', '')}")
    print(f"Subject: {decode_str(msg.get('Subject', ''))}")

    # List attachments
    attachments = []
    if msg.is_multipart():
        for part in msg.walk():
            fn = part.get_filename()
            if fn:
                attachments.append(decode_str(fn))
    if attachments:
        print(f"Attachments: {', '.join(attachments)}")

    print("-" * 60)
    print(get_body(msg))

    imap.logout()


def cmd_send(args):
    creds = load_creds()

    msg = MIMEMultipart()
    msg["From"] = creds["email"]
    msg["To"] = args.to
    if args.cc:
        msg["Cc"] = args.cc
    msg["Subject"] = args.subject
    msg.attach(MIMEText(args.body, "plain"))

    with smtplib.SMTP_SSL(creds["smtp"]["server"], creds["smtp"]["port"]) as server:
        server.login(creds["email"], creds["password"])
        recipients = [args.to]
        if args.cc:
            recipients += [a.strip() for a in args.cc.split(",")]
        server.sendmail(creds["email"], recipients, msg.as_string())

    print(f"Sent to {args.to}" + (f" (cc: {args.cc})" if args.cc else ""))


def cmd_search(args):
    creds = load_creds()
    imap = connect_imap(creds)
    imap.select("INBOX")

    # Build IMAP search criteria
    criteria = []
    if args.from_addr:
        criteria.append(f'FROM "{args.from_addr}"')
    if args.subject:
        criteria.append(f'SUBJECT "{args.subject}"')
    if args.since:
        criteria.append(f'SINCE {args.since}')
    if args.text:
        criteria.append(f'TEXT "{args.text}"')

    search_str = " ".join(criteria) if criteria else "ALL"
    _, msg_nums = imap.search(None, search_str)
    ids = msg_nums[0].split()

    if not ids:
        print("No matching messages.")
        imap.logout()
        return

    ids = ids[-(args.limit):]
    ids.reverse()

    print(f"Found {len(ids)} message(s):")
    print(f"{'ID':>6} | {'Date':20} | {'From':30} | Subject")
    print("-" * 100)

    for mid in ids:
        _, data = imap.fetch(mid, "(BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE)])")
        raw = data[0][1]
        msg = email.message_from_bytes(raw)

        from_addr = decode_str(msg.get("From", ""))[:30]
        subject = decode_str(msg.get("Subject", "(no subject)"))
        date_str = msg.get("Date", "")
        try:
            date_parsed = email.utils.parsedate_to_datetime(date_str)
            date_fmt = date_parsed.strftime("%Y-%m-%d %H:%M")
        except Exception:
            date_fmt = date_str[:20]

        print(f"{mid.decode():>6} | {date_fmt:20} | {from_addr:30} | {subject}")

    imap.logout()


def cmd_folders(args):
    creds = load_creds()
    imap = connect_imap(creds)
    _, folders = imap.list()
    for f in folders:
        print(f.decode())
    imap.logout()


def cmd_count(args):
    creds = load_creds()
    imap = connect_imap(creds)
    imap.select("INBOX")
    _, all_msgs = imap.search(None, "ALL")
    _, unseen = imap.search(None, "UNSEEN")
    total = len(all_msgs[0].split()) if all_msgs[0] else 0
    unread = len(unseen[0].split()) if unseen[0] else 0
    print(f"Total: {total}, Unread: {unread}")
    imap.logout()


def main():
    parser = argparse.ArgumentParser(description="temaki.ai email client")
    sub = parser.add_subparsers(dest="command", required=True)

    # inbox
    p_inbox = sub.add_parser("inbox", help="List inbox messages")
    p_inbox.add_argument("-n", "--limit", type=int, default=20, help="Number of messages")
    p_inbox.add_argument("-u", "--unread", action="store_true", help="Unread only")

    # read
    p_read = sub.add_parser("read", help="Read a specific message")
    p_read.add_argument("id", type=int, help="Message ID")

    # send
    p_send = sub.add_parser("send", help="Send an email")
    p_send.add_argument("--to", required=True, help="Recipient")
    p_send.add_argument("--cc", help="CC recipients (comma-separated)")
    p_send.add_argument("--subject", required=True, help="Subject line")
    p_send.add_argument("--body", required=True, help="Message body")

    # search
    p_search = sub.add_parser("search", help="Search messages")
    p_search.add_argument("--from", dest="from_addr", help="From address")
    p_search.add_argument("--subject", help="Subject contains")
    p_search.add_argument("--text", help="Body contains")
    p_search.add_argument("--since", help="Since date (DD-Mon-YYYY)")
    p_search.add_argument("-n", "--limit", type=int, default=20, help="Max results")

    # folders
    sub.add_parser("folders", help="List mailbox folders")

    # count
    sub.add_parser("count", help="Count total and unread messages")

    args = parser.parse_args()
    cmd_map = {
        "inbox": cmd_inbox,
        "read": cmd_read,
        "send": cmd_send,
        "search": cmd_search,
        "folders": cmd_folders,
        "count": cmd_count,
    }
    cmd_map[args.command](args)


if __name__ == "__main__":
    main()
