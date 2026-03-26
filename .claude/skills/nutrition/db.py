"""SQLite-backed storage for nutrition data, plus BMR/TDEE calculations."""

import json
import sqlite3
from pathlib import Path

_BASE_DIR = Path.home() / ".config" / "nutrition-tracker"
_profile = "default"
_initialized = set()


def set_profile(name: str):
    global _profile
    _profile = name


def config_dir() -> Path:
    return _BASE_DIR / _profile


# FDA Daily Values (based on 2,000 cal diet)
# Users can override via config "daily_values" key
FDA_DAILY_VALUES = {
    "calories": 2000,
    "protein_g": 50,
    "fat_g": 78,
    "saturated_fat_g": 20,
    "carbs_g": 275,
    "fiber_g": 28,
    "sugar_g": 50,  # added sugar; we track total
    "cholesterol_mg": 300,
    "sodium_mg": 2300,
    "potassium_mg": 4700,
    "vitamin_a": 900,  # mcg RAE (FatSecret reports IU; ~3000 IU = 900 mcg)
    "vitamin_c": 90,  # mg
    "calcium": 1300,  # mg
    "iron": 18,  # mg
}


def get_daily_values(config: dict | None = None, exercise_hours: float = 0) -> dict:
    """Get daily value targets, adjusted for exercise.

    Scaling:
    - Calories: TDEE (already includes base activity multiplier)
    - Protein: g/kg bodyweight (default 1.6g/kg)
    - Sodium: +600 mg/hr exercise (ACSM sweat loss midpoint, 500-700 range)
    - Potassium: +175 mg/hr exercise (Baker et al. 2019, 150-200 range)
    - Other micros: fixed FDA DVs (don't scale with activity)
    """
    dvs = dict(FDA_DAILY_VALUES)
    if config:
        # Use TDEE as calorie target if configured
        tdee = compute_tdee(config) if config.get("weight_kg") else None
        if tdee:
            dvs["calories"] = round(tdee)
        # Protein: g/kg bodyweight (default 1.6g/kg)
        weight_kg = config.get("weight_kg")
        if weight_kg:
            protein_per_kg = config.get("protein_g_per_kg", 1.6)
            dvs["protein_g"] = round(weight_kg * protein_per_kg)
        # Exercise-adjusted electrolytes
        sodium_per_hr = config.get("sodium_mg_per_exercise_hr", 600)
        potassium_per_hr = config.get("potassium_mg_per_exercise_hr", 175)
        dvs["sodium_mg"] += round(sodium_per_hr * exercise_hours)
        dvs["potassium_mg"] += round(potassium_per_hr * exercise_hours)
        # Allow per-nutrient overrides
        overrides = config.get("daily_values", {})
        dvs.update(overrides)
    return dvs


MICRO_COLS = [
    "saturated_fat_g",
    "polyunsaturated_fat_g",
    "monounsaturated_fat_g",
    "cholesterol_mg",
    "sodium_mg",
    "potassium_mg",
    "fiber_g",
    "sugar_g",
    "vitamin_a",
    "vitamin_c",
    "calcium",
    "iron",
]


def _ensure_schema(conn):
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS meals (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            meal_type TEXT NOT NULL,
            name TEXT NOT NULL,
            serving TEXT,
            calories REAL NOT NULL DEFAULT 0,
            protein_g REAL NOT NULL DEFAULT 0,
            fat_g REAL NOT NULL DEFAULT 0,
            carbs_g REAL NOT NULL DEFAULT 0,
            saturated_fat_g REAL NOT NULL DEFAULT 0,
            polyunsaturated_fat_g REAL NOT NULL DEFAULT 0,
            monounsaturated_fat_g REAL NOT NULL DEFAULT 0,
            cholesterol_mg REAL NOT NULL DEFAULT 0,
            sodium_mg REAL NOT NULL DEFAULT 0,
            potassium_mg REAL NOT NULL DEFAULT 0,
            fiber_g REAL NOT NULL DEFAULT 0,
            sugar_g REAL NOT NULL DEFAULT 0,
            vitamin_a REAL NOT NULL DEFAULT 0,
            vitamin_c REAL NOT NULL DEFAULT 0,
            calcium REAL NOT NULL DEFAULT 0,
            iron REAL NOT NULL DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS weight (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            weight_lbs REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS activities (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            activity_type TEXT NOT NULL,
            name TEXT,
            duration_minutes REAL NOT NULL,
            calories_burned REAL NOT NULL DEFAULT 0,
            distance_km REAL,
            source TEXT DEFAULT 'manual'
        );

        CREATE INDEX IF NOT EXISTS idx_meals_timestamp ON meals(timestamp);
        CREATE INDEX IF NOT EXISTS idx_weight_timestamp ON weight(timestamp);
        CREATE INDEX IF NOT EXISTS idx_activities_timestamp ON activities(timestamp);
    """)
    # Migrate existing DBs: add micronutrient columns if missing
    for col in MICRO_COLS:
        try:
            conn.execute(f"ALTER TABLE meals ADD COLUMN {col} REAL NOT NULL DEFAULT 0")
        except sqlite3.OperationalError:
            pass  # column already exists


def get_db() -> sqlite3.Connection:
    d = config_dir()
    d.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(d / "nutrition.db")
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    if _profile not in _initialized:
        _ensure_schema(conn)
        _initialized.add(_profile)
    return conn


# --- Writes ---


def insert_meal(
    id,
    timestamp,
    meal_type,
    name,
    serving,
    calories,
    protein_g,
    fat_g,
    carbs_g,
    **micros,
):
    all_cols = [
        "id",
        "timestamp",
        "meal_type",
        "name",
        "serving",
        "calories",
        "protein_g",
        "fat_g",
        "carbs_g",
    ] + MICRO_COLS
    vals = [
        id,
        timestamp,
        meal_type,
        name,
        serving,
        calories,
        protein_g,
        fat_g,
        carbs_g,
    ] + [micros.get(c, 0) for c in MICRO_COLS]
    placeholders = ", ".join("?" * len(all_cols))
    col_names = ", ".join(all_cols)
    conn = get_db()
    conn.execute(f"INSERT INTO meals ({col_names}) VALUES ({placeholders})", vals)
    conn.commit()
    conn.close()


def insert_weight(timestamp, weight_lbs):
    conn = get_db()
    conn.execute(
        "INSERT INTO weight (timestamp, weight_lbs) VALUES (?, ?)",
        (timestamp, weight_lbs),
    )
    conn.commit()
    conn.close()


def insert_activity(
    id,
    timestamp,
    activity_type,
    name,
    duration_minutes,
    calories_burned,
    distance_km=None,
    source="manual",
):
    conn = get_db()
    conn.execute(
        "INSERT OR REPLACE INTO activities "
        "(id, timestamp, activity_type, name, duration_minutes, calories_burned, distance_km, source) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (
            id,
            timestamp,
            activity_type,
            name,
            duration_minutes,
            calories_burned,
            distance_km,
            source,
        ),
    )
    conn.commit()
    conn.close()


# --- Reads ---


def _today_local() -> str:
    from datetime import datetime

    return datetime.now().strftime("%Y-%m-%d")


def meals_today() -> list[dict]:
    return meals_for_date(_today_local())


def meals_for_date(date_str: str) -> list[dict]:
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM meals WHERE date(timestamp, 'localtime') = ? ORDER BY timestamp",
        (date_str,),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def totals_today() -> dict:
    return totals_for_date(_today_local())


def totals_for_date(date_str: str) -> dict:
    sum_cols = ["calories", "protein_g", "fat_g", "carbs_g"] + MICRO_COLS
    select = ", ".join(f"COALESCE(SUM({c}), 0) as {c}" for c in sum_cols)
    conn = get_db()
    row = conn.execute(
        f"SELECT {select} FROM meals WHERE date(timestamp, 'localtime') = ?",
        (date_str,),
    ).fetchone()
    conn.close()
    return dict(row)


def totals_for_range(start: str, end: str) -> list[dict]:
    sum_cols = ["calories", "protein_g", "fat_g", "carbs_g"] + MICRO_COLS
    select = ", ".join(f"SUM({c}) as {c}" for c in sum_cols)
    conn = get_db()
    rows = conn.execute(
        f"SELECT date(timestamp, 'localtime') as date, {select} "
        "FROM meals WHERE date(timestamp, 'localtime') BETWEEN ? AND ? "
        "GROUP BY date(timestamp, 'localtime') ORDER BY date",
        (start, end),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def burned_today() -> float:
    return burned_for_date(_today_local())


def burned_for_date(date_str: str) -> float:
    conn = get_db()
    row = conn.execute(
        "SELECT COALESCE(SUM(calories_burned), 0) as burned "
        "FROM activities WHERE date(timestamp, 'localtime') = ?",
        (date_str,),
    ).fetchone()
    conn.close()
    return row["burned"]


def activities_today() -> list[dict]:
    return activities_for_date(_today_local())


def activities_for_date(date_str: str) -> list[dict]:
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM activities WHERE date(timestamp, 'localtime') = ? ORDER BY timestamp",
        (date_str,),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def burned_for_range(start: str, end: str) -> list[dict]:
    conn = get_db()
    rows = conn.execute(
        "SELECT date(timestamp, 'localtime') as date, "
        "SUM(calories_burned) as burned "
        "FROM activities WHERE date(timestamp, 'localtime') BETWEEN ? AND ? "
        "GROUP BY date(timestamp, 'localtime') ORDER BY date",
        (start, end),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def latest_weight() -> float | None:
    conn = get_db()
    row = conn.execute(
        "SELECT weight_lbs FROM weight ORDER BY timestamp DESC LIMIT 1"
    ).fetchone()
    conn.close()
    return row["weight_lbs"] if row else None


def weight_history(days: int = 30) -> list[dict]:
    conn = get_db()
    rows = conn.execute(
        "SELECT date(timestamp, 'localtime') as date, weight_lbs "
        "FROM weight ORDER BY timestamp DESC LIMIT ?",
        (days,),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def db_stats() -> dict:
    conn = get_db()
    meals_count = conn.execute("SELECT COUNT(*) as n FROM meals").fetchone()["n"]
    activities_count = conn.execute("SELECT COUNT(*) as n FROM activities").fetchone()[
        "n"
    ]
    weight_count = conn.execute("SELECT COUNT(*) as n FROM weight").fetchone()["n"]
    first_meal = conn.execute(
        "SELECT MIN(date(timestamp, 'localtime')) as d FROM meals"
    ).fetchone()["d"]
    last_meal = conn.execute(
        "SELECT MAX(date(timestamp, 'localtime')) as d FROM meals"
    ).fetchone()["d"]
    conn.close()
    return {
        "meals": meals_count,
        "activities": activities_count,
        "weight_entries": weight_count,
        "first_date": first_meal,
        "last_date": last_meal,
    }


# --- Config ---


def load_config() -> dict:
    p = config_dir() / "config.json"
    if p.exists():
        return json.loads(p.read_text())
    return {}


def save_config(config: dict):
    d = config_dir()
    d.mkdir(parents=True, exist_ok=True)
    (d / "config.json").write_text(json.dumps(config, indent=2))


def load_combos() -> dict:
    p = config_dir() / "combos.json"
    if p.exists():
        return json.loads(p.read_text())
    return {}


def save_combos(combos: dict):
    d = config_dir()
    d.mkdir(parents=True, exist_ok=True)
    (d / "combos.json").write_text(json.dumps(combos, indent=2))


def delete_meals_by_ids(ids: list[str]):
    conn = get_db()
    placeholders = ",".join("?" * len(ids))
    conn.execute(f"DELETE FROM meals WHERE id IN ({placeholders})", ids)
    conn.commit()
    conn.close()


def recent_meals(n: int) -> list[dict]:
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM meals ORDER BY rowid DESC LIMIT ?", (n,)
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# --- Calculations ---


def compute_bmr(config: dict) -> float:
    """Mifflin-St Jeor: Men 10w+6.25h-5a+5, Women 10w+6.25h-5a-161."""
    w = config.get("weight_kg", 80)
    h = config.get("height_cm", 178)
    a = config.get("age", 30)
    s = config.get("sex", "male")
    bmr = 10 * w + 6.25 * h - 5 * a
    return bmr + 5 if s == "male" else bmr - 161


def compute_tdee(config: dict) -> float:
    return compute_bmr(config) * config.get("activity_multiplier", 1.2)


def compute_deficit(totals: dict, config: dict) -> dict:
    tdee = compute_tdee(config)
    consumed = totals.get("calories", 0)
    burned = totals.get("burned", 0)
    net = consumed - burned
    return {
        "tdee": round(tdee),
        "consumed": round(consumed),
        "burned": round(burned),
        "net": round(net),
        "deficit": round(tdee - net),
    }
