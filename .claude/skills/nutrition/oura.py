"""Oura Ring API integration — daily activity calorie sync.

Stores NEAT (non-exercise activity) by subtracting workout calories from
other sources (Strava, Intervals.icu) on the same day to avoid double-counting.
"""

import os
from datetime import datetime, timedelta

import db
import requests

API_BASE = "https://api.ouraring.com/v2/usercollection"

# Sources whose calories overlap with Oura's active_calories
WORKOUT_SOURCES = {"strava", "intervals.icu", "manual"}


def _get_token():
    config = db.load_config()
    return config.get("oura_token") or os.environ.get("OURA_TOKEN", "")


def get_daily_activities(start_date: str, end_date: str) -> list[dict]:
    token = _get_token()
    if not token:
        raise RuntimeError("Set OURA_TOKEN in ~/.zshrc or profile config.json")
    resp = requests.get(
        f"{API_BASE}/daily_activity",
        headers={"Authorization": f"Bearer {token}"},
        params={"start_date": start_date, "end_date": end_date},
    )
    resp.raise_for_status()
    return resp.json().get("data", [])


def _workout_calories_for_date(date_str: str) -> float:
    """Sum calories from non-Oura activity sources on a given date."""
    activities = db.activities_for_date(date_str)
    return sum(
        a["calories_burned"]
        for a in activities
        if a.get("source") in WORKOUT_SOURCES
    )


def sync_activity(days: int = 7):
    end = datetime.now().strftime("%Y-%m-%d")
    start = (datetime.now() - timedelta(days=days - 1)).strftime("%Y-%m-%d")
    activities = get_daily_activities(start, end)
    if not activities:
        print(f"No Oura activity data for {start} to {end}.")
        return
    for activity in activities:
        date = activity.get("day")
        total_active = activity.get("active_calories", 0)
        steps = activity.get("steps", 0)
        distance = activity.get("equivalent_walking_distance", 0)

        # Subtract workout calories already tracked from other sources
        workout_cal = _workout_calories_for_date(date)
        neat = max(0, total_active - workout_cal)

        db.insert_activity(
            id=f"oura-{date}",
            timestamp=f"{date}T12:00:00+00:00",
            activity_type="daily_activity",
            name=f"Oura NEAT ({steps} steps)",
            duration_minutes=1440,
            calories_burned=neat,
            distance_km=(distance / 1000) if distance else None,
            source="oura",
        )
    print(f"Synced {len(activities)} days of Oura activity ({start} to {end}).")
