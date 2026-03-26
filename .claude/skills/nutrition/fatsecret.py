"""FatSecret API client — OAuth 2.0 token management, food search, detail fetch."""

import base64
import json
import os
import re
import time
from pathlib import Path

import requests

TOKEN_URL = "https://oauth.fatsecret.com/connect/token"
API_BASE = "https://platform.fatsecret.com/rest"
TOKEN_TTL = 23 * 3600  # refresh ~1h before expiry


def _token_path() -> Path:
    import db
    return db.config_dir() / "fatsecret_token.json"


def _get_token() -> str:
    """Get a valid OAuth 2.0 access token, using cache when possible."""
    tp = _token_path()
    if tp.exists():
        data = json.loads(tp.read_text())
        if data.get("expires_at", 0) > time.time():
            return data["access_token"]

    client_id = os.environ["FATSECRET_CLIENT_ID"]
    client_secret = os.environ["FATSECRET_CLIENT_SECRET"]
    creds = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()

    resp = requests.post(
        TOKEN_URL,
        headers={
            "Authorization": f"Basic {creds}",
            "Content-Type": "application/x-www-form-urlencoded",
        },
        data="grant_type=client_credentials&scope=premier",
        timeout=10,
    )
    resp.raise_for_status()
    token_data = resp.json()

    tp.parent.mkdir(parents=True, exist_ok=True)
    tp.write_text(
        json.dumps(
            {
                "access_token": token_data["access_token"],
                "expires_at": time.time() + TOKEN_TTL,
            }
        )
    )
    return token_data["access_token"]


def search_foods(query: str, max_results: int = 10) -> list[dict]:
    """Search for foods by name. Returns list of food dicts."""
    token = _get_token()
    resp = requests.get(
        f"{API_BASE}/foods/search/v1",
        headers={"Authorization": f"Bearer {token}"},
        params={
            "search_expression": query,
            "format": "json",
            "max_results": max_results,
        },
        timeout=10,
    )
    resp.raise_for_status()
    data = resp.json()
    return data.get("foods", {}).get("food", [])


def get_food_details(food_id: str) -> dict:
    """Get detailed food info including all serving sizes."""
    token = _get_token()
    resp = requests.get(
        f"{API_BASE}/food/v4",
        headers={"Authorization": f"Bearer {token}"},
        params={"food_id": food_id, "format": "json"},
        timeout=10,
    )
    resp.raise_for_status()
    return resp.json().get("food", {})


def parse_description(desc: str) -> dict:
    """Parse FatSecret description string like 'Per 100g - Calories: 32kcal | Fat: 0.30g | Carbs: 7.68g | Protein: 0.67g'.

    Returns dict with keys: serving, calories, fat_g, carbs_g, protein_g.
    """
    result = {}
    m = re.match(r"Per\s+(.+?)\s*-\s*", desc)
    if m:
        result["serving"] = m.group(1)

    for key, pattern in [
        ("calories", r"Calories:\s*([\d.]+)"),
        ("fat_g", r"Fat:\s*([\d.]+)"),
        ("carbs_g", r"Carbs:\s*([\d.]+)"),
        ("protein_g", r"Protein:\s*([\d.]+)"),
    ]:
        m = re.search(pattern, desc)
        result[key] = float(m.group(1)) if m else 0.0

    return result


def get_servings(food_id: str) -> list[dict]:
    """Get serving size options for a food. Returns list of serving dicts."""
    details = get_food_details(food_id)
    servings_data = details.get("servings", {}).get("serving", [])
    if isinstance(servings_data, dict):
        servings_data = [servings_data]
    return servings_data


def format_search_result(food: dict, index: int) -> str:
    """Format a single search result for display."""
    name = food.get("food_name", "?")
    brand = food.get("brand_name", "")
    desc = food.get("food_description", "")
    label = f"  {index}. {name}"
    if brand:
        label += f" ({brand})"
    label += f"\n     {desc}"
    return label


def format_serving(serving: dict, index: int) -> str:
    """Format a serving option for display."""
    desc = serving.get("serving_description", "?")
    cal = serving.get("calories", "?")
    protein = serving.get("protein", "?")
    fat = serving.get("fat", "?")
    carbs = serving.get("carbohydrate", "?")
    return f"  {index}. {desc} — {cal} cal | P:{protein}g F:{fat}g C:{carbs}g"
