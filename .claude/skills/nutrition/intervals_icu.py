"""Intervals.icu API integration — cycling/workout activity sync."""

import os
from base64 import b64encode
from datetime import datetime, timedelta

import db
import requests

API_BASE = "https://intervals.icu/api/v1"


def _get_credentials():
    config = db.load_config()
    api_key = config.get("intervals_api_key") or os.environ.get("INTERVALS_API_KEY", "")
    athlete_id = config.get("intervals_athlete_id") or os.environ.get("INTERVALS_ATHLETE_ID", "")
    return api_key, athlete_id


def _auth_header() -> dict:
    api_key, athlete_id = _get_credentials()
    if not api_key or not athlete_id:
        raise RuntimeError("Set INTERVALS_API_KEY/INTERVALS_ATHLETE_ID in ~/.zshrc or profile config.json")
    creds = b64encode(f"API_KEY:{api_key}".encode()).decode()
    return {"Authorization": f"Basic {creds}"}


def get_activities(oldest=None, newest=None) -> list[dict]:
    _, athlete_id = _get_credentials()
    params = {}
    if oldest:
        params["oldest"] = oldest
    if newest:
        params["newest"] = newest
    resp = requests.get(
        f"{API_BASE}/athlete/{athlete_id}/activities",
        headers=_auth_header(),
        params=params,
    )
    resp.raise_for_status()
    return resp.json()


def sync_activities():
    oldest = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")
    activities = get_activities(oldest=oldest)
    count = 0
    for a in activities:
        calories = a.get("calories", 0) or 0
        # Use elapsed_time for duration (better for sweat/nutrition calculations)
        elapsed = a.get("elapsed_time", 0) or a.get("moving_time", 0) or 0
        distance = a.get("distance", 0) or 0
        db.insert_activity(
            id=f"intervals-{a['id']}",
            timestamp=a.get("start_date_local", a.get("start_date", "")),
            activity_type=a.get("type", "Unknown"),
            name=a.get("name", ""),
            duration_minutes=elapsed / 60,
            calories_burned=calories,
            distance_km=(distance / 1000) if distance else None,
            source="intervals.icu",
        )
        count += 1
    print(f"Synced {count} activities from Intervals.icu.")
