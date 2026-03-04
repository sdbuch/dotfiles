---
name: calendar
description: >-
  Manage Google Calendar events. Supports listing, searching, creating,
  modifying, and deleting events across multiple accounts via --profile.
  Use when the user wants to view, create, or manage calendar events.
allowed-tools: Bash(uv run:*)
---

# Google Calendar CLI Tool

Manage Google Calendar events for use in scheduling, meeting coordination, etc.

## Setup

### Credentials

OAuth credentials and tokens are stored outside the repo, shared with the
gmail and scan (Drive) skills:

```
~/.config/google-oauth/
├── credentials.json          # OAuth client secret (from GCP console)
├── token_personal.json       # auto-generated per profile
└── token_work.json           # auto-generated per profile
```

Tokens include the `calendar.events`, `calendar.readonly`, `gmail.readonly`,
and `drive` scopes. If you add this skill to a machine that already has
gmail/Drive tokens, delete the existing `token_*.json` files and re-auth to
pick up the new scopes.

### Auth

Each `--profile` stores a separate OAuth token. First run opens a browser:

```bash
cd ~/.claude/skills/calendar && uv run python calendar_cli.py --profile personal --list
```

Without `--profile`, falls back to Application Default Credentials (gcloud ADC).

## Profiles

- `--profile personal` — personal Gmail / Google account
- `--profile work` — work/university Google account

### Default calendars

When `--calendar-id` is not specified, the profile's default calendars are
queried. For `--list` and `--search`, events from all default calendars are
merged and sorted by start time.

- `personal`: primary personal calendar + work/university calendar (see `PROFILE_DEFAULT_CALENDARS` in `calendar_cli.py`)
- All other profiles: `primary`

Use `--calendars` to discover available calendar IDs.

## Usage

```bash
cd ~/.claude/skills/calendar

# List available calendars
uv run python calendar_cli.py --profile personal --calendars

# List upcoming events (default: next 7 days, merges personal + work calendars)
uv run python calendar_cli.py --profile personal --list

# List next 14 days
uv run python calendar_cli.py --profile work --list --days 14

# List from a specific calendar only
uv run python calendar_cli.py --profile personal --list --calendar-id "your-email@gmail.com"

# Search events
uv run python calendar_cli.py --profile personal --search "standup"

# Get full event details
uv run python calendar_cli.py --profile personal --get EVENT_ID

# Create an event
uv run python calendar_cli.py --profile personal --create "Team standup" --start "2026-03-05 2:00pm" --end "2026-03-05 3:00pm"

# Create an all-day event
uv run python calendar_cli.py --profile personal --create "Company retreat" --start "2026-03-06" --all-day

# Create with attendees
uv run python calendar_cli.py --profile work --create "1:1 with Alice" --start "2026-03-05 10:00am" --attendees "alice@example.com,bob@example.com"

# Modify an event
uv run python calendar_cli.py --profile personal --modify EVENT_ID --title "Updated title"
uv run python calendar_cli.py --profile personal --modify EVENT_ID --start "2026-03-05 3:00pm"

# Delete an event
uv run python calendar_cli.py --profile personal --delete EVENT_ID

# Delete and notify attendees
uv run python calendar_cli.py --profile personal --delete EVENT_ID --notify
```

### Time formats

`--start` and `--end` accept:
- ISO 8601: `2026-03-05T14:00:00-08:00`
- `YYYY-MM-DD HH:MM`: `2026-03-05 14:00`
- `YYYY-MM-DD H:MMam/pm`: `2026-03-05 2:00pm` or `2026-03-05 2pm`

Local timezone is assumed when none is specified.

### Output format

List/search prints one line per event:
```
2026-03-05 14:00-15:00   Team standup                   id:abc123
2026-03-06 (all day)     Company retreat                id:def456
```

`--get`, `--create`, and `--modify` print full details:
```
===== Event =====
Title: Team standup
Start: 2026-03-05 14:00 PST
End:   2026-03-05 15:00 PST
Description: Weekly sync
Attendees: alice@example.com, bob@example.com
Event-ID: abc123
Link: https://...
```

### Options reference

| Flag | Description |
|------|-------------|
| `--list` | List upcoming events (default next 7 days) |
| `--search QUERY` | Search events by text |
| `--create TITLE` | Create event (requires `--start`) |
| `--modify EVENT_ID` | Modify event fields |
| `--delete EVENT_ID` | Delete an event |
| `--get EVENT_ID` | Full details of one event |
| `--calendars` | List available calendars |
| `--profile NAME` | OAuth profile (personal, work) |
| `--calendar-id ID` | Calendar ID (repeatable; default: profile-specific) |
| `--days N` | Time window for --list/--search (default: 7) |
| `--max-results N` | Max results for --list/--search |
| `--start TIME` | Start time for --create/--modify |
| `--end TIME` | End time for --create/--modify |
| `--description TEXT` | Description for --create/--modify |
| `--attendees EMAILS` | Comma-separated emails for --create/--modify |
| `--all-day` | All-day event (with --create) |
| `--title TEXT` | New title (with --modify) |
| `--notify` | Notify attendees on --delete |
