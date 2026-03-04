"""Fetch emails from Gmail via the Gmail API.

Auth modes:
  --profile NAME   Uses OAuth with per-profile tokens stored in ~/.config/google-oauth/
                   First run per profile opens a browser for consent.
  (no --profile)   Uses Application Default Credentials (gcloud ADC).

Credentials file: ~/.config/google-oauth/credentials.json (OAuth client secret)
Token files:      ~/.config/google-oauth/token_<profile>.json (auto-generated)
"""

import argparse
import base64
import re
from email.utils import parsedate_to_datetime
from html.parser import HTMLParser
from pathlib import Path

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


def get_service(profile: str | None = None):
    if profile:
        creds = _get_oauth_credentials(profile)
    else:
        creds, _ = default(scopes=SCOPES)
    return build("gmail", "v1", credentials=creds)


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


class HTMLTextExtractor(HTMLParser):
    """Minimal HTML-to-text converter."""

    def __init__(self):
        super().__init__()
        self._parts: list[str] = []
        self._skip = False

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self._skip = True
        elif tag == "br":
            self._parts.append("\n")
        elif tag in ("p", "div", "tr", "li"):
            self._parts.append("\n")

    def handle_endtag(self, tag):
        if tag in ("script", "style"):
            self._skip = False

    def handle_data(self, data):
        if not self._skip:
            self._parts.append(data)

    def get_text(self) -> str:
        text = "".join(self._parts)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip()


def strip_html(html: str) -> str:
    parser = HTMLTextExtractor()
    parser.feed(html)
    return parser.get_text()


def get_header(headers: list[dict], name: str) -> str:
    for h in headers:
        if h["name"].lower() == name.lower():
            return h["value"]
    return ""


def extract_body(payload: dict) -> str:
    """Extract plain text body from a message payload, falling back to HTML."""
    mime = payload.get("mimeType", "")

    if payload.get("body", {}).get("data"):
        text = base64.urlsafe_b64decode(payload["body"]["data"]).decode(
            "utf-8", errors="replace"
        )
        if "html" in mime:
            return strip_html(text)
        return text

    parts = payload.get("parts", [])
    plain_parts = []
    html_parts = []
    for part in parts:
        part_mime = part.get("mimeType", "")
        if part_mime == "text/plain" and part.get("body", {}).get("data"):
            plain_parts.append(
                base64.urlsafe_b64decode(part["body"]["data"]).decode(
                    "utf-8", errors="replace"
                )
            )
        elif part_mime == "text/html" and part.get("body", {}).get("data"):
            html_parts.append(
                base64.urlsafe_b64decode(part["body"]["data"]).decode(
                    "utf-8", errors="replace"
                )
            )
        elif part.get("parts"):
            nested = extract_body(part)
            if nested:
                plain_parts.append(nested)

    if plain_parts:
        return "\n".join(plain_parts)
    if html_parts:
        return strip_html("\n".join(html_parts))
    return ""


def _find_trailing_quote_start(lines: list[str]) -> int | None:
    """Find the line index where the trailing quote block begins.

    Handles three patterns:
    1. Unquoted "On ... wrote:" followed by '>' lines (standard bottom-post)
    2. Quoted "> On ... wrote:" followed by deeper '>>' lines (nested old quotes
       inside an inline reply)
    3. Outlook-style "From:/Sent:/Subject:" blocks
    4. "---- Original Message ----" dividers
    """
    n = len(lines)

    # Walk backwards past trailing blank lines
    i = n - 1
    while i >= 0 and not lines[i].strip():
        i -= 1
    if i < 0:
        return None

    # Walk backwards past quoted lines (any depth) and blanks
    while i >= 0 and (lines[i].startswith(">") or not lines[i].strip()):
        i -= 1

    if i < 0:
        # Entire message is quoted. Look for a nested quote header inside
        # the quoted block: "> On ... wrote:" followed by ">>" lines.
        return _find_nested_quote_header(lines)

    # lines[i] is the last non-quoted line. Check if it's a quote header.

    # Gmail-style "On ... wrote:" (may span 1-4 lines)
    cut = None
    for start in range(max(0, i - 3), i + 1):
        candidate = " ".join(lines[start : i + 1])
        if re.match(r"^On .+ wrote:$", candidate):
            cut = start
            break

    # Outlook-style "From: ... Sent: ... Subject: ..."
    if cut is None:
        for start in range(max(0, i - 5), i + 1):
            block = "\n".join(lines[start : i + 1])
            if (
                re.search(r"^From: ", block, re.MULTILINE)
                and re.search(r"^Sent: ", block, re.MULTILINE)
                and re.search(r"^Subject: ", block, re.MULTILINE)
            ):
                cut = start
                break

    # "---- Original Message ----" style
    if cut is None and re.match(r"^-{4,}.*Original Message.*-{4,}$", lines[i]):
        cut = i

    # If the cut would remove everything, this is likely an inline reply —
    # fall through to nested quote detection instead.
    if cut is not None:
        if not "\n".join(lines[:cut]).strip():
            return _find_nested_quote_header(lines)
        return cut

    return None


def _find_nested_quote_header(lines: list[str]) -> int | None:
    """Find the outermost quoted 'On ... wrote:' that starts old nested quotes.

    For inline replies, the message is entirely quoted, but there's a point
    where the inline responses end and older nested quotes begin. Scans forward
    to find the first (outermost) such header.
    """
    n = len(lines)
    for i in range(n):
        stripped = lines[i].lstrip(">").strip()
        if not stripped.endswith("wrote:"):
            continue
        depth = len(lines[i]) - len(lines[i].lstrip(">"))
        if depth < 1:
            continue  # skip unquoted top-level "On ... wrote:"
        # Check if this line (possibly with preceding lines) forms "On ... wrote:"
        for start in range(max(0, i - 3), i + 1):
            parts = []
            for k in range(start, i + 1):
                parts.append(lines[k].lstrip(">").strip())
            candidate = " ".join(parts)
            if re.match(r"^On .+ wrote:$", candidate):
                # Verify everything after is at same or deeper quote depth
                all_deeper = True
                for k in range(i + 1, n):
                    if not lines[k].strip():
                        continue
                    line_depth = len(lines[k]) - len(lines[k].lstrip(">"))
                    if line_depth < depth:
                        all_deeper = False
                        break
                if all_deeper:
                    return start
    return None


def strip_quotes(text: str) -> str:
    """Remove the trailing quoted reply block from an email body.

    Strips the bottom-posted quote while preserving inline quoting. Handles
    Gmail-style ("On ... wrote:"), Outlook-style (From/Sent/Subject blocks),
    and nested quotes inside inline replies.
    """
    lines = text.splitlines()
    cut = _find_trailing_quote_start(lines)
    if cut is None:
        return text
    result = "\n".join(lines[:cut])
    result = re.sub(r"\n{3,}", "\n\n", result)
    result = result.strip()
    if not result:
        return text
    return result


def parse_date(headers: list[dict]):
    raw = get_header(headers, "Date")
    if not raw:
        return None
    try:
        return parsedate_to_datetime(raw)
    except Exception:
        return None


def format_date(headers: list[dict]) -> str:
    dt = parse_date(headers)
    if dt is None:
        return get_header(headers, "Date")
    return dt.astimezone().strftime("%Y-%m-%d %H:%M %Z").strip()


def format_message(
    msg: dict,
    index: int | None = None,
    total: int | None = None,
    no_quotes: bool = False,
) -> str:
    headers = msg.get("payload", {}).get("headers", [])
    parts = []
    if index is not None and total is not None:
        parts.append(f"===== Message {index} of {total} =====")
    parts.append(f"From: {get_header(headers, 'From')}")
    parts.append(f"To: {get_header(headers, 'To')}")
    parts.append(f"Date: {format_date(headers)}")
    parts.append(f"Subject: {get_header(headers, 'Subject')}")
    parts.append(f"Message-ID: {msg['id']}  Thread-ID: {msg['threadId']}")
    parts.append("")
    body = extract_body(msg.get("payload", {}))
    if no_quotes:
        body = strip_quotes(body)
    parts.append(body)
    return "\n".join(parts)


def cmd_search(service, args):
    results = (
        service.users()
        .messages()
        .list(userId="me", q=args.search, maxResults=args.max_results)
        .execute()
    )
    messages = results.get("messages", [])
    if not messages:
        print("No messages found.")
        return

    summaries = []
    for m in messages:
        msg = (
            service.users()
            .messages()
            .get(
                userId="me",
                id=m["id"],
                format="metadata",
                metadataHeaders=["From", "Subject", "Date"],
            )
            .execute()
        )
        headers = msg.get("payload", {}).get("headers", [])
        summaries.append(
            {
                "id": msg["id"],
                "threadId": msg["threadId"],
                "from": get_header(headers, "From"),
                "subject": get_header(headers, "Subject"),
                "date": format_date(headers),
            }
        )

    if not args.full:
        for s in summaries:
            print(f"{s['date']:>22}  {s['from'][:40]:<40}  {s['subject'][:60]}")
            print(f"{'':>22}  msg:{s['id']}  thread:{s['threadId']}")
        print(f"\n({len(summaries)} results. Use --full to fetch message bodies.)")
        return

    full_msgs = []
    for m in messages:
        msg = (
            service.users()
            .messages()
            .get(userId="me", id=m["id"], format="full")
            .execute()
        )
        full_msgs.append(msg)
    for i, msg in enumerate(full_msgs, 1):
        print(format_message(msg, i, len(full_msgs), no_quotes=args.no_quotes))
        if i < len(full_msgs):
            print()


def cmd_recent(service, args):
    results = (
        service.users().messages().list(userId="me", maxResults=args.recent).execute()
    )
    messages = results.get("messages", [])
    if not messages:
        print("No messages found.")
        return
    for i, m in enumerate(messages, 1):
        msg = (
            service.users()
            .messages()
            .get(userId="me", id=m["id"], format="full")
            .execute()
        )
        print(format_message(msg, i, len(messages), no_quotes=args.no_quotes))
        if i < len(messages):
            print()


def cmd_thread(service, args):
    thread = (
        service.users()
        .threads()
        .get(userId="me", id=args.thread, format="full")
        .execute()
    )
    messages = thread.get("messages", [])
    for i, msg in enumerate(messages, 1):
        print(format_message(msg, i, len(messages), no_quotes=args.no_quotes))
        if i < len(messages):
            print()


def cmd_message(service, args):
    msg = (
        service.users()
        .messages()
        .get(userId="me", id=args.message, format="full")
        .execute()
    )
    print(format_message(msg, no_quotes=args.no_quotes))


def main():
    parser = argparse.ArgumentParser(
        description="Fetch emails from Gmail via the Gmail API.",
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--search", metavar="QUERY", help="Search using Gmail query syntax"
    )
    group.add_argument(
        "--thread", metavar="THREAD_ID", help="Fetch a full thread by ID"
    )
    group.add_argument(
        "--message", metavar="MSG_ID", help="Fetch a single message by ID"
    )
    group.add_argument(
        "--recent", metavar="N", type=int, help="Fetch N most recent messages"
    )

    parser.add_argument(
        "--profile", metavar="NAME", help="OAuth profile name (e.g. personal, work)"
    )
    parser.add_argument(
        "--full", action="store_true", help="Fetch full bodies (with --search)"
    )
    parser.add_argument(
        "--max-results", type=int, default=20, help="Max search results (default: 20)"
    )
    parser.add_argument(
        "--no-quotes",
        action="store_true",
        default=None,
        help="Strip quoted replies (default: on for --thread)",
    )
    parser.add_argument(
        "--keep-quotes",
        action="store_true",
        help="Keep quoted replies (overrides default)",
    )

    args = parser.parse_args()
    # Default --no-quotes on for --thread
    if args.keep_quotes:
        args.no_quotes = False
    elif args.no_quotes is None:
        args.no_quotes = bool(args.thread)
    service = get_service(args.profile)

    if args.search:
        cmd_search(service, args)
    elif args.recent:
        cmd_recent(service, args)
    elif args.thread:
        cmd_thread(service, args)
    elif args.message:
        cmd_message(service, args)


if __name__ == "__main__":
    main()
