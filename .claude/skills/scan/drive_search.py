"""Search and download files from Google Drive."""

import argparse
import sys
from pathlib import Path

from google.auth import default
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/calendar.events",
    "https://www.googleapis.com/auth/calendar.readonly",
]
CONFIG_DIR = Path.home() / ".config" / "google-oauth"
CREDENTIALS_PATH = CONFIG_DIR / "credentials.json"


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
    return build("drive", "v3", credentials=creds)


def search_files(
    service,
    query: str | None = None,
    folder_id: str | None = None,
    max_results: int = 20,
) -> list[dict]:
    conditions = ["trashed = false"]
    if folder_id:
        conditions.append(f"'{folder_id}' in parents")
    if query:
        conditions.append(f"(name contains '{query}' or fullText contains '{query}')")

    q = " and ".join(conditions)
    kwargs = dict(
        q=q,
        pageSize=max_results,
        fields="files(id,name,description,mimeType,createdTime,size,webViewLink)",
    )
    if not query:
        kwargs["orderBy"] = "createdTime desc"
    results = service.files().list(**kwargs).execute()
    return results.get("files", [])


def download_file(service, file_id: str, output_path: Path) -> Path:
    request = service.files().get_media(fileId=file_id)
    with open(output_path, "wb") as f:
        downloader = MediaIoBaseDownload(f, request)
        done = False
        while not done:
            _, done = downloader.next_chunk()
    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Search and download from Google Drive"
    )
    parser.add_argument(
        "--profile", metavar="NAME", help="OAuth profile name (e.g. personal, work)"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    ls = sub.add_parser("search", help="Search for files")
    ls.add_argument(
        "query", nargs="?", help="Search term (matches name and description)"
    )
    ls.add_argument("--folder-id", help="Limit search to a folder")
    ls.add_argument("-n", type=int, default=20, help="Max results")

    dl = sub.add_parser("download", help="Download a file by ID")
    dl.add_argument("file_id", help="Drive file ID")
    dl.add_argument("-o", "--output", help="Output path (default: original filename)")

    mv = sub.add_parser("move", help="Move a file to a different folder")
    mv.add_argument("file_id", help="Drive file ID")
    mv.add_argument("folder_id", help="Destination folder ID")

    rm = sub.add_parser("delete", help="Trash a file by ID")
    rm.add_argument("file_id", help="Drive file ID")

    args = parser.parse_args()
    service = get_service(args.profile)

    if args.command == "search":
        files = search_files(service, args.query, args.folder_id, args.n)
        if not files:
            print("No files found.")
            return
        for f in files:
            desc = f.get("description", "")
            desc_str = f"  | {desc}" if desc else ""
            size = int(f.get("size", 0))
            size_str = f"{size / 1_000_000:.1f}MB" if size else "?"
            print(
                f"{f['id']}  {f['createdTime'][:10]}  {size_str:>8}  {f['name']}{desc_str}"
            )

    elif args.command == "download":
        if args.output:
            out = Path(args.output)
        else:
            meta = service.files().get(fileId=args.file_id, fields="name").execute()
            out = Path(meta["name"])
        download_file(service, args.file_id, out)
        print(f"Downloaded: {out}")

    elif args.command == "move":
        f = service.files().get(fileId=args.file_id, fields="parents,name").execute()
        old_parents = ",".join(f.get("parents", []))
        service.files().update(
            fileId=args.file_id,
            addParents=args.folder_id,
            removeParents=old_parents,
            fields="id,parents",
        ).execute()
        print(f"Moved {f['name']} to folder {args.folder_id}")

    elif args.command == "delete":
        f = service.files().get(fileId=args.file_id, fields="name").execute()
        service.files().update(fileId=args.file_id, body={"trashed": True}).execute()
        print(f"Trashed: {f['name']}")


if __name__ == "__main__":
    main()
