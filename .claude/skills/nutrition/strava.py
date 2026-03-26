"""Strava API integration — OAuth 2.0 + activity sync."""

import json
import os
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlencode, urlparse

import db
import requests

REDIRECT_URI = "http://localhost:8742/callback"
AUTH_URL = "https://www.strava.com/oauth/authorize"
TOKEN_URL = "https://www.strava.com/oauth/token"
API_BASE = "https://www.strava.com/api/v3"


def _token_path():
    return db.config_dir() / "strava_token.json"


def _get_credentials():
    config = db.load_config()
    client_id = config.get("strava_client_id") or os.environ.get("STRAVA_CLIENT_ID", "")
    client_secret = config.get("strava_client_secret") or os.environ.get("STRAVA_CLIENT_SECRET", "")
    return client_id, client_secret


def _load_token() -> dict | None:
    tp = _token_path()
    if tp.exists():
        return json.loads(tp.read_text())
    return None


def _save_token(data: dict):
    tp = _token_path()
    tp.parent.mkdir(parents=True, exist_ok=True)
    tp.write_text(json.dumps(data, indent=2))


def _refresh_token(token_data: dict) -> dict:
    client_id, client_secret = _get_credentials()
    resp = requests.post(
        TOKEN_URL,
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "grant_type": "refresh_token",
            "refresh_token": token_data["refresh_token"],
        },
    )
    resp.raise_for_status()
    new_data = resp.json()
    _save_token(new_data)
    return new_data


def _get_token() -> str:
    import time

    data = _load_token()
    if not data:
        raise RuntimeError("No Strava token. Run 'strava-auth' first.")
    if data.get("expires_at", 0) < time.time():
        data = _refresh_token(data)
    return data["access_token"]


def authorize():
    """Run OAuth authorization flow — opens browser, starts local callback server."""
    client_id, client_secret = _get_credentials()
    if not client_id or not client_secret:
        print("Set STRAVA_CLIENT_ID/STRAVA_CLIENT_SECRET in ~/.zshrc or profile config.json")
        return

    params = urlencode(
        {
            "client_id": client_id,
            "redirect_uri": REDIRECT_URI,
            "response_type": "code",
            "scope": "activity:read_all",
        }
    )
    url = f"{AUTH_URL}?{params}"

    auth_code = None

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            nonlocal auth_code
            qs = parse_qs(urlparse(self.path).query)
            auth_code = qs.get("code", [None])[0]
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Authorization complete. You can close this tab.")

        def log_message(self, format, *args):
            pass

    print("Opening browser for Strava authorization...")
    webbrowser.open(url)

    server = HTTPServer(("localhost", 8742), Handler)
    server.handle_request()

    if not auth_code:
        print("Authorization failed — no code received.")
        return

    resp = requests.post(
        TOKEN_URL,
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "code": auth_code,
            "grant_type": "authorization_code",
        },
    )
    resp.raise_for_status()
    token_data = resp.json()
    _save_token(token_data)
    athlete = token_data.get("athlete", {}).get("firstname", "?")
    print(f"Strava authorized for athlete {athlete}.")


def get_activities(after=None) -> list[dict]:
    token = _get_token()
    params = {"per_page": 50}
    if after:
        params["after"] = int(after)
    resp = requests.get(
        f"{API_BASE}/athlete/activities",
        headers={
            "Authorization": f"Bearer {token}",
        },
        params=params,
    )
    resp.raise_for_status()
    return resp.json()


def sync_activities():
    activities = get_activities()
    count = 0
    for a in activities:
        calories = a.get("calories", 0) or a.get("kilojoules", 0) * 0.239006
        db.insert_activity(
            id=f"strava-{a['id']}",
            timestamp=a["start_date"],
            activity_type=a.get("type", "Unknown"),
            name=a.get("name", ""),
            duration_minutes=a.get("moving_time", 0) / 60,
            calories_burned=calories,
            distance_km=(a.get("distance", 0) / 1000) if a.get("distance") else None,
            source="strava",
        )
        count += 1
    print(f"Synced {count} activities from Strava.")
