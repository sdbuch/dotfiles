---
name: gmail
description: >-
  Fetch emails from Gmail via the Gmail API. Supports searching, fetching
  threads/messages, and multiple accounts via --profile. Use when the user
  wants to read, search, or retrieve email content.
allowed-tools: Bash(uv run:*)
---

# Gmail CLI Tool

Fetch emails from Gmail for use in LLM context, job search workflows, etc.

## Setup

### Credentials

OAuth credentials and tokens are stored outside the repo, shared with the
scan (Drive) and calendar skills. Tokens include `gmail.readonly`, `drive`,
`calendar.events`, and `calendar.readonly` scopes:

```
~/.config/google-oauth/
├── credentials.json          # OAuth client secret (from GCP console)
├── token_personal.json       # auto-generated per profile
└── token_work.json           # auto-generated per profile
```

To set up a new machine:
1. Create a GCP project and enable the Gmail API
2. Create an OAuth client ID (Desktop app)
3. Download the client JSON to `~/.config/google-oauth/credentials.json`
4. On the OAuth consent screen, add the `gmail.readonly`, `drive`,
   `calendar.events`, and `calendar.readonly` scopes, and add all Google
   accounts you'll use as test users

### Auth

Each `--profile` stores a separate OAuth token. First run opens a browser:

```bash
cd ~/.claude/skills/gmail && uv run python fetch_gmail.py --profile personal --recent 1
```

Without `--profile`, falls back to Application Default Credentials (gcloud ADC).

## Profiles

- `--profile personal` — personal Gmail
- `--profile work` — work/university email

## Usage

```bash
cd ~/.claude/skills/gmail

# Search (summary view)
uv run python fetch_gmail.py --profile personal --search "from:alice@example.com after:2026/03/01"

# Search (full bodies)
uv run python fetch_gmail.py --profile personal --search "from:alice@example.com" --full

# Recent messages
uv run python fetch_gmail.py --profile work --recent 5

# Full thread by ID (shown in search results)
uv run python fetch_gmail.py --profile personal --thread THREAD_ID

# Single message by ID
uv run python fetch_gmail.py --profile personal --message MSG_ID
```

The `--search` query uses Gmail's native search syntax (same as the Gmail search
bar): `from:`, `to:`, `subject:`, `after:`, `before:`, `is:unread`, `label:`,
`has:attachment`, etc.

### Quote stripping

When fetching threads (`--thread`), quoted reply text is stripped by default to
reduce redundancy. This handles standard bottom-posted replies, inline replies
(preserves the inline responses, strips nested old quotes), and Outlook-style
forward blocks. Use `--keep-quotes` to disable, or `--no-quotes` to enable on
other modes (`--recent`, `--message`, `--search --full`).

### Output format

Search without `--full` prints a summary table with date, sender, subject, and
IDs. With `--full` or other modes, outputs one message per section:

```
===== Message 1 of 3 =====
From: Alice <alice@example.com>
To: Bob <bob@example.com>
Date: 2026-02-15 10:23 PST
Subject: Re: Hello
Message-ID: abc123  Thread-ID: def456

[body text]
```

### Typical workflow

```bash
# Dump emails to a file, then use in Claude Code
uv run python fetch_gmail.py --profile personal --search "from:alice@example.com" --full > /tmp/emails.txt
# Then: "Read /tmp/emails.txt and help me draft a response"
```
