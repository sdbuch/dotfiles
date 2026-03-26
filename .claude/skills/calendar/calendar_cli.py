"""Google Calendar CLI — list, search, create, modify, delete events.

Auth modes:
  --profile NAME   Uses OAuth with per-profile tokens stored in ~/.config/google-oauth/
                   First run per profile opens a browser for consent.
  (no --profile)   Uses Application Default Credentials (gcloud ADC).

Credentials file: ~/.config/google-oauth/credentials.json (OAuth client secret)
Token files:      ~/.config/google-oauth/token_<profile>.json (auto-generated)
"""

import argparse
import json
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from google.auth import default
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/calendar.events",
    "https://www.googleapis.com/auth/calendar.readonly",
]
CONFIG_DIR = Path.home() / ".config" / "google-oauth"
CREDENTIALS_PATH = CONFIG_DIR / "credentials.json"

LOCAL_TZ = datetime.now(timezone.utc).astimezone().tzinfo


def _load_calendar_config() -> dict:
    """Load per-profile default calendar IDs from config file."""
    path = CONFIG_DIR / "calendar_config.json"
    if path.exists():
        return json.loads(path.read_text()).get("profile_default_calendars", {})
    return {}


PROFILE_DEFAULT_CALENDARS = _load_calendar_config()


def _get_oauth_credentials(profile: str) -> Credentials:
    token_path = CONFIG_DIR / f"token_{profile}.json"
    creds = None
    if token_path.exists():
        creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not CREDENTIALS_PATH.exists():
                raise FileNotFoundError(
                    f"OAuth credentials not found at {CREDENTIALS_PATH}\n"
                    "Download your OAuth client JSON from GCP console and save it there."
                )
            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_PATH), SCOPES
            )
            creds = flow.run_local_server(port=0)
        token_path.write_text(creds.to_json())
    return creds


def get_service(profile: str | None = None):
    if profile:
        creds = _get_oauth_credentials(profile)
    else:
        creds, _ = default(scopes=SCOPES)
    return build("calendar", "v3", credentials=creds)


def parse_datetime(s: str) -> datetime:
    """Parse a datetime string using stdlib only.

    Accepts:
      - ISO 8601 (2026-03-05T14:00:00-08:00)
      - YYYY-MM-DD HH:MM
      - YYYY-MM-DD H:MMam/pm
    Assumes local timezone if none given.
    """
    s = s.strip()

    # ISO 8601 with timezone
    for fmt in ("%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%dT%H:%M%z"):
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            pass

    # ISO 8601 without timezone
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M"):
        try:
            dt = datetime.strptime(s, fmt)
            return dt.replace(tzinfo=LOCAL_TZ)
        except ValueError:
            pass

    # YYYY-MM-DD HH:MM
    try:
        dt = datetime.strptime(s, "%Y-%m-%d %H:%M")
        return dt.replace(tzinfo=LOCAL_TZ)
    except ValueError:
        pass

    # YYYY-MM-DD H:MMam/pm (e.g. "2026-03-05 2:00pm" or "2026-03-05 2pm")
    m = re.match(
        r"(\d{4}-\d{2}-\d{2})\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)",
        s,
        re.IGNORECASE,
    )
    if m:
        date_str, hour_str, min_str, ampm = m.groups()
        hour = int(hour_str)
        minute = int(min_str) if min_str else 0
        if ampm.lower() == "pm" and hour != 12:
            hour += 12
        elif ampm.lower() == "am" and hour == 12:
            hour = 0
        dt = datetime.strptime(date_str, "%Y-%m-%d").replace(
            hour=hour, minute=minute, tzinfo=LOCAL_TZ
        )
        return dt

    raise ValueError(
        f"Cannot parse datetime: {s!r}\n"
        "Expected: ISO 8601, 'YYYY-MM-DD HH:MM', or 'YYYY-MM-DD H:MMam/pm'"
    )


def format_event_time(event: dict) -> str:
    """Format start-end for compact one-line display."""
    start = event.get("start", {})
    end = event.get("end", {})

    if "date" in start:
        return f"{start['date']} (all day)"

    start_dt = datetime.fromisoformat(start["dateTime"]).astimezone(LOCAL_TZ)
    end_dt = datetime.fromisoformat(end["dateTime"]).astimezone(LOCAL_TZ)

    if start_dt.date() == end_dt.date():
        return f"{start_dt.strftime('%Y-%m-%d %H:%M')}-{end_dt.strftime('%H:%M')}"
    return f"{start_dt.strftime('%Y-%m-%d %H:%M')}-{end_dt.strftime('%Y-%m-%d %H:%M')}"


def format_dt_full(dt_dict: dict) -> str:
    """Format a start/end dict for full event view."""
    if "date" in dt_dict:
        return f"{dt_dict['date']} (all day)"
    dt = datetime.fromisoformat(dt_dict["dateTime"]).astimezone(LOCAL_TZ)
    return dt.strftime("%Y-%m-%d %H:%M %Z")


def format_event_compact(event: dict) -> str:
    """One-line summary for list/search output."""
    time_str = format_event_time(event)
    summary = event.get("summary", "(no title)")
    event_id = event["id"]
    return f"{time_str:<24} {summary:<30} id:{event_id}"


def format_event_full(event: dict) -> str:
    """Full event detail view."""
    lines = ["===== Event ====="]
    lines.append(f"Title: {event.get('summary', '(no title)')}")
    lines.append(f"Start: {format_dt_full(event.get('start', {}))}")
    lines.append(f"End:   {format_dt_full(event.get('end', {}))}")
    if event.get("description"):
        lines.append(f"Description: {event['description']}")
    attendees = event.get("attendees", [])
    if attendees:
        emails = [a["email"] for a in attendees]
        lines.append(f"Attendees: {', '.join(emails)}")
    lines.append(f"Event-ID: {event['id']}")
    if event.get("htmlLink"):
        lines.append(f"Link: {event['htmlLink']}")
    return "\n".join(lines)


def _resolve_calendar_ids(args) -> list[str]:
    """Return the list of calendar IDs to query.

    If --calendar-id was explicitly given, use those. Otherwise fall back to
    profile defaults, or ["primary"].
    """
    if args.calendar_id:
        return args.calendar_id
    if args.profile and args.profile in PROFILE_DEFAULT_CALENDARS:
        return PROFILE_DEFAULT_CALENDARS[args.profile]
    return ["primary"]


def _event_sort_key(event: dict) -> str:
    start = event.get("start", {})
    return start.get("dateTime", start.get("date", ""))


def cmd_list(service, args):
    now = datetime.now(timezone.utc)
    time_min = now.isoformat()
    time_max = (now + timedelta(days=args.days)).isoformat()

    all_events = []
    for cal_id in _resolve_calendar_ids(args):
        events = (
            service.events()
            .list(
                calendarId=cal_id,
                timeMin=time_min,
                timeMax=time_max,
                maxResults=args.max_results,
                singleEvents=True,
                orderBy="startTime",
            )
            .execute()
            .get("items", [])
        )
        all_events.extend(events)

    all_events.sort(key=_event_sort_key)
    if not all_events:
        print("No upcoming events.")
        return
    for e in all_events:
        print(format_event_compact(e))


def cmd_search(service, args):
    now = datetime.now(timezone.utc)
    time_min = now.isoformat()
    time_max = (now + timedelta(days=args.days)).isoformat()

    all_events = []
    for cal_id in _resolve_calendar_ids(args):
        events = (
            service.events()
            .list(
                calendarId=cal_id,
                timeMin=time_min,
                timeMax=time_max,
                maxResults=args.max_results,
                singleEvents=True,
                orderBy="startTime",
                q=args.search,
            )
            .execute()
            .get("items", [])
        )
        all_events.extend(events)

    all_events.sort(key=_event_sort_key)
    if not all_events:
        print("No matching events.")
        return
    for e in all_events:
        print(format_event_compact(e))


def _single_calendar_id(args) -> str:
    """Return a single calendar ID for single-event commands."""
    return _resolve_calendar_ids(args)[0]


def cmd_create(service, args):
    cal_id = _single_calendar_id(args)
    body: dict = {"summary": args.create}

    if args.description:
        body["description"] = args.description

    if args.all_day:
        start_date = args.start.strip()[:10]
        body["start"] = {"date": start_date}
        if args.end:
            body["end"] = {"date": args.end.strip()[:10]}
        else:
            end = datetime.strptime(start_date, "%Y-%m-%d") + timedelta(days=1)
            body["end"] = {"date": end.strftime("%Y-%m-%d")}
    else:
        if not args.start:
            print("Error: --start is required for --create", file=sys.stderr)
            sys.exit(1)
        start_dt = parse_datetime(args.start)
        body["start"] = {"dateTime": start_dt.isoformat()}
        if args.end:
            end_dt = parse_datetime(args.end)
            body["end"] = {"dateTime": end_dt.isoformat()}
        else:
            end_dt = start_dt + timedelta(hours=1)
            body["end"] = {"dateTime": end_dt.isoformat()}

    if args.attendees:
        body["attendees"] = [
            {"email": email.strip()} for email in args.attendees.split(",")
        ]

    event = service.events().insert(calendarId=cal_id, body=body).execute()
    print(format_event_full(event))


def cmd_modify(service, args):
    cal_id = _single_calendar_id(args)
    event = service.events().get(calendarId=cal_id, eventId=args.modify).execute()

    if args.title:
        event["summary"] = args.title
    if args.description:
        event["description"] = args.description
    if args.start:
        if "date" in event.get("start", {}):
            event["start"] = {"date": args.start.strip()[:10]}
        else:
            start_dt = parse_datetime(args.start)
            event["start"] = {"dateTime": start_dt.isoformat()}
    if args.end:
        if "date" in event.get("end", {}):
            event["end"] = {"date": args.end.strip()[:10]}
        else:
            end_dt = parse_datetime(args.end)
            event["end"] = {"dateTime": end_dt.isoformat()}
    if args.attendees:
        event["attendees"] = [
            {"email": email.strip()} for email in args.attendees.split(",")
        ]

    updated = (
        service.events()
        .update(calendarId=cal_id, eventId=args.modify, body=event)
        .execute()
    )
    print(format_event_full(updated))


def cmd_delete(service, args):
    cal_id = _single_calendar_id(args)
    send_updates = "all" if args.notify else "none"
    service.events().delete(
        calendarId=cal_id,
        eventId=args.delete,
        sendUpdates=send_updates,
    ).execute()
    print(f"Deleted event {args.delete}")


def cmd_get(service, args):
    cal_id = _single_calendar_id(args)
    event = service.events().get(calendarId=cal_id, eventId=args.get).execute()
    print(format_event_full(event))


def cmd_calendars(service, args):
    cals = service.calendarList().list().execute().get("items", [])
    if not cals:
        print("No calendars found.")
        return
    for c in cals:
        role = c.get("accessRole", "")
        summary = c.get("summary", "(no name)")
        cal_id = c["id"]
        print(f"{cal_id:<55} {summary:<30} {role}")


def main():
    parser = argparse.ArgumentParser(
        description="Google Calendar CLI — list, search, create, modify, delete events."
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--list", action="store_true", help="List upcoming events")
    group.add_argument("--search", metavar="QUERY", help="Search events by text")
    group.add_argument("--create", metavar="TITLE", help="Create a new event")
    group.add_argument("--modify", metavar="EVENT_ID", help="Modify an event")
    group.add_argument("--delete", metavar="EVENT_ID", help="Delete an event")
    group.add_argument("--get", metavar="EVENT_ID", help="Get full event details")
    group.add_argument(
        "--calendars", action="store_true", help="List available calendars"
    )

    parser.add_argument(
        "--profile", metavar="NAME", help="OAuth profile name (e.g. personal, work)"
    )
    parser.add_argument(
        "--calendar-id",
        action="append",
        default=None,
        help="Calendar ID (repeatable; default: profile-specific or 'primary')",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=7,
        help="Time window for --list/--search (default: 7)",
    )
    parser.add_argument(
        "--max-results", type=int, default=50, help="Max results for --list/--search"
    )

    # --create options
    parser.add_argument(
        "--start", help="Start time (ISO, 'YYYY-MM-DD HH:MM', 'YYYY-MM-DD H:MMam/pm')"
    )
    parser.add_argument("--end", help="End time (same formats as --start)")
    parser.add_argument("--description", help="Event description")
    parser.add_argument("--attendees", help="Comma-separated email addresses")
    parser.add_argument(
        "--all-day", action="store_true", help="Create an all-day event"
    )

    # --modify options
    parser.add_argument("--title", help="New title (with --modify)")

    # --delete options
    parser.add_argument(
        "--notify", action="store_true", help="Notify attendees on delete"
    )

    args = parser.parse_args()
    service = get_service(args.profile)

    if args.list:
        cmd_list(service, args)
    elif args.search:
        cmd_search(service, args)
    elif args.create:
        cmd_create(service, args)
    elif args.modify:
        cmd_modify(service, args)
    elif args.delete:
        cmd_delete(service, args)
    elif args.get:
        cmd_get(service, args)
    elif args.calendars:
        cmd_calendars(service, args)


if __name__ == "__main__":
    main()
