"""Upload files to Google Drive."""

import argparse
import sys
from pathlib import Path

from google.auth import default
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

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


def upload_file(
    service,
    filepath: Path,
    folder_id: str | None = None,
    name: str | None = None,
    description: str | None = None,
) -> dict:
    metadata = {"name": name or filepath.name}
    if folder_id:
        metadata["parents"] = [folder_id]
    if description:
        metadata["description"] = description

    mime = (
        "application/pdf" if filepath.suffix == ".pdf" else "application/octet-stream"
    )
    media = MediaFileUpload(str(filepath), mimetype=mime, resumable=True)
    result = (
        service.files()
        .create(body=metadata, media_body=media, fields="id,name,webViewLink")
        .execute()
    )
    return result


def main():
    parser = argparse.ArgumentParser(description="Upload files to Google Drive")
    parser.add_argument("files", nargs="+", help="Files to upload")
    parser.add_argument(
        "--profile", metavar="NAME", help="OAuth profile name (e.g. personal, work)"
    )
    parser.add_argument("--folder-id", help="Drive folder ID to upload into")
    parser.add_argument("--name", help="Override filename in Drive")
    parser.add_argument("--description", help="File description (searchable metadata)")
    args = parser.parse_args()

    service = get_service(args.profile)
    for f in args.files:
        path = Path(f)
        if not path.exists():
            print(f"Error: {f} not found", file=sys.stderr)
            continue
        result = upload_file(service, path, args.folder_id, args.name, args.description)
        print(
            f"Uploaded: {result['name']} -> {result.get('webViewLink', result['id'])}"
        )


if __name__ == "__main__":
    main()
