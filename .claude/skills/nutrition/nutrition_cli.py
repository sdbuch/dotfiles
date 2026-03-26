"""Nutrition tracker CLI — search foods, log meals/workouts/weight, query daily stats."""

import argparse
import sys
import uuid
from datetime import datetime, timedelta, timezone

import db
import fatsecret

ATTRIBUTION = "Powered by FatSecret (https://www.fatsecret.com)"


# --- Search ---


def cmd_search(args):
    foods = fatsecret.search_foods(args.query, max_results=args.max)
    if not foods:
        print("No results found.")
        return
    print(f'\nResults for "{args.query}":\n')
    for i, food in enumerate(foods, 1):
        print(fatsecret.format_search_result(food, i))
    print(f"\n{ATTRIBUTION}")


# --- Log (search + pick) ---


MICRO_MAP = {
    "saturated_fat": "saturated_fat_g",
    "polyunsaturated_fat": "polyunsaturated_fat_g",
    "monounsaturated_fat": "monounsaturated_fat_g",
    "cholesterol": "cholesterol_mg",
    "sodium": "sodium_mg",
    "potassium": "potassium_mg",
    "fiber": "fiber_g",
    "sugar": "sugar_g",
    "vitamin_a": "vitamin_a",
    "vitamin_c": "vitamin_c",
    "calcium": "calcium",
    "iron": "iron",
}


def _log_fatsecret_item(
    query, pick, servings, serving_name, meal_type, date_str, scale=1.0, dry_run=False
):
    """Search FatSecret, pick a result, and log it. Returns the item dict or None."""
    foods = fatsecret.search_foods(query, max_results=10)
    if not foods:
        print(f"  No results for '{query}'")
        return None

    if pick < 1 or pick > len(foods):
        print(f"  --pick {pick} out of range for '{query}' ({len(foods)} results)")
        for i, food in enumerate(foods, 1):
            print(fatsecret.format_search_result(food, i))
        print(f"\n{ATTRIBUTION}")
        return None

    food = foods[pick - 1]
    food_id = food.get("food_id")
    name = food.get("food_name", "?")
    brand = food.get("brand_name", "")

    servings_data = fatsecret.get_servings(food_id)
    if not servings_data:
        parsed = fatsecret.parse_description(food.get("food_description", ""))
        item = _make_item(name, brand, parsed.get("serving", "1 serving"), parsed)
        if not dry_run:
            _log_meal_entry(item, meal_type, date_str)
        return item

    serving = _pick_serving(servings_data, serving_name)
    if not serving:
        print(f'  No serving matching "{serving_name}" for {name}. Available:')
        for i, s in enumerate(servings_data, 1):
            print(fatsecret.format_serving(s, i))
        return None

    multiplier = servings * scale
    cal = float(serving.get("calories", 0)) * multiplier
    protein = float(serving.get("protein", 0)) * multiplier
    fat = float(serving.get("fat", 0)) * multiplier
    carbs = float(serving.get("carbohydrate", 0)) * multiplier
    serving_desc = serving.get("serving_description", "1 serving")

    qty_label = f"{multiplier} x {serving_desc}" if multiplier != 1 else serving_desc
    macros = {
        "calories": round(cal),
        "protein_g": round(protein, 1),
        "fat_g": round(fat, 1),
        "carbs_g": round(carbs, 1),
    }
    for api_key, db_key in MICRO_MAP.items():
        val = float(serving.get(api_key, 0)) * multiplier
        macros[db_key] = round(val, 2)

    item = _make_item(name, brand, qty_label, macros)
    if not dry_run:
        _log_meal_entry(item, meal_type, date_str)
    return item


def cmd_log(args):
    _log_fatsecret_item(
        args.query,
        args.pick,
        args.servings,
        args.serving_name,
        args.meal,
        getattr(args, "date", None),
    )


def _pick_serving(servings: list[dict], serving_name: str | None) -> dict | None:
    """Find the best matching serving by name, or return the first one."""
    if not serving_name:
        return servings[0] if servings else None
    name_lower = serving_name.lower()
    for s in servings:
        desc = s.get("serving_description", "").lower()
        if name_lower in desc or desc in name_lower:
            return s
    # Try metric_serving_description
    for s in servings:
        metric = s.get("metric_serving_description", "").lower()
        if name_lower in metric or metric in name_lower:
            return s
    return None


def _make_item(name: str, brand: str, serving: str, macros: dict) -> dict:
    item = {
        "name": name,
        "serving": serving,
        "calories": round(macros.get("calories", 0)),
        "protein_g": round(macros.get("protein_g", 0), 1),
        "fat_g": round(macros.get("fat_g", 0), 1),
        "carbs_g": round(macros.get("carbs_g", 0), 1),
    }
    if brand:
        item["brand"] = brand
    # Pass through any micronutrients
    from db import MICRO_COLS

    for col in MICRO_COLS:
        if col in macros:
            item[col] = macros[col]
    return item


def _log_meal_entry(item: dict, meal_type: str, date_str: str | None = None):
    from db import MICRO_COLS

    micros = {col: item.get(col, 0) for col in MICRO_COLS}
    if date_str:
        ts = f"{date_str}T12:00:00+00:00"
    else:
        ts = datetime.now(timezone.utc).isoformat()
    db.insert_meal(
        id=str(uuid.uuid4()),
        timestamp=ts,
        meal_type=meal_type,
        name=item["name"],
        serving=item.get("serving", ""),
        calories=item["calories"],
        protein_g=item["protein_g"],
        fat_g=item["fat_g"],
        carbs_g=item["carbs_g"],
        **micros,
    )
    label = item.get("brand", "")
    if label:
        label = f" ({label})"
    print(f"Logged {meal_type}: {item['name']}{label}")
    print(
        f"  {item['serving']}: {item['calories']} cal | P:{item['protein_g']}g F:{item['fat_g']}g C:{item['carbs_g']}g"
    )


# --- Log manual ---


def cmd_log_manual(args):
    item = _make_item(
        args.name,
        "",
        "manual entry",
        {
            "calories": args.calories,
            "protein_g": args.protein,
            "fat_g": args.fat,
            "carbs_g": args.carbs,
        },
    )
    _log_meal_entry(item, args.meal, getattr(args, "date", None))


# --- Workout ---


def cmd_workout(args):
    db.insert_activity(
        id=str(uuid.uuid4()),
        timestamp=datetime.now(timezone.utc).isoformat(),
        activity_type=args.activity,
        name=args.activity,
        duration_minutes=args.duration,
        calories_burned=args.calories,
        source="manual",
    )
    print(
        f"Logged workout: {args.activity} — {args.duration}min, {args.calories} cal burned"
    )


# --- Weight ---


def cmd_weight(args):
    db.insert_weight(datetime.now(timezone.utc).isoformat(), args.lbs)
    print(f"Logged weight: {args.lbs} lbs")


# --- Today ---


def cmd_today(args):
    config = db.load_config()
    date_str = datetime.now().strftime("%Y-%m-%d")

    meals = db.meals_today()
    totals = db.totals_today()
    burned = db.burned_today()
    activities = db.activities_today()
    weight = db.latest_weight()

    # Calculate exercise hours (exclude passive sources like Oura NEAT)
    exercise_hours = sum(
        a["duration_minutes"] / 60 for a in activities if a.get("source") != "oura"
    )

    print(f"\n=== {date_str} ===\n")

    if meals:
        meal_groups: dict[str, list] = {}
        for m in meals:
            meal_groups.setdefault(m["meal_type"], []).append(m)
        for mt, items in meal_groups.items():
            print(f"  {mt.capitalize()}:")
            for item in items:
                print(f"    - {item['name']}: {item['calories']:.0f} cal")
        print()

    dvs = db.get_daily_values(config, exercise_hours=exercise_hours)

    def pct(val, key):
        dv = dvs.get(key)
        if dv:
            return f" ({val / dv * 100:.0f}%)"
        return ""

    print(
        f"  Calories consumed: {totals['calories']:.0f}{pct(totals['calories'], 'calories')}"
    )
    print(
        f"  Protein: {totals['protein_g']:.1f}g{pct(totals['protein_g'], 'protein_g')}"
        f" | Fat: {totals['fat_g']:.1f}g{pct(totals['fat_g'], 'fat_g')}"
        f" | Carbs: {totals['carbs_g']:.1f}g{pct(totals['carbs_g'], 'carbs_g')}"
    )

    # Micronutrient summary with %DV
    micro_display = [
        ("fiber_g", "Fiber", "g", ".1f"),
        ("sugar_g", "Sugar", "g", ".1f"),
        ("sodium_mg", "Sodium", "mg", ".0f"),
        ("cholesterol_mg", "Chol", "mg", ".0f"),
        ("potassium_mg", "Potassium", "mg", ".0f"),
        ("calcium", "Calcium", "mg", ".0f"),
        ("iron", "Iron", "mg", ".1f"),
        ("vitamin_c", "Vit C", "mg", ".1f"),
    ]
    micros = []
    for key, label, unit, fmt in micro_display:
        val = totals.get(key, 0)
        if val:
            micros.append(f"{label}: {val:{fmt}}{unit}{pct(val, key)}")
    if micros:
        # Print in rows of 3-4 for readability
        for i in range(0, len(micros), 4):
            print(f"  {' | '.join(micros[i : i + 4])}")

    if burned:
        print(f"  Calories burned (exercise): {burned:.0f}")
    if weight:
        print(f"  Weight: {weight} lbs")

    if config:
        deficit_info = db.compute_deficit(
            {"calories": totals["calories"], "burned": burned}, config
        )
        print(f"\n  TDEE: {deficit_info['tdee']} cal")
        print(f"  Net intake: {deficit_info['net']} cal (consumed - burned)")
        remaining = deficit_info["deficit"]
        label = "remaining" if remaining > 0 else "over"
        print(f"  {abs(remaining)} cal {label}")
    else:
        print("\n  (Run 'config' to set your stats for TDEE calculation)")

    print()


# --- Week ---


def cmd_week(args):
    end = datetime.now().strftime("%Y-%m-%d")
    start = (datetime.now() - timedelta(days=6)).strftime("%Y-%m-%d")

    daily_totals = db.totals_for_range(start, end)
    daily_burned = db.burned_for_range(start, end)

    if not daily_totals:
        print("No data for the past week.")
        return

    burned_map = {d["date"]: d["burned"] for d in daily_burned}

    print("\n=== Weekly Summary ===\n")
    total_cal = 0.0
    total_protein = 0.0
    total_burned = 0.0
    for day in daily_totals:
        d = day["date"]
        c = day["calories"]
        p = day["protein_g"]
        b = burned_map.get(d, 0)
        total_cal += c
        total_protein += p
        total_burned += b
        b_str = f" | burned:{b:.0f}" if b else ""
        print(f"  {d}: {c:.0f} cal | P:{p:.0f}g{b_str}")

    n = len(daily_totals)
    print(
        f"\n  Avg: {total_cal / n:.0f} cal/day | {total_protein / n:.0f}g protein/day"
    )
    if total_burned:
        print(f"  Total burned: {total_burned:.0f} cal")
    print()


# --- Status ---


def cmd_status(args):
    stats = db.db_stats()
    print("\n=== Database Status ===\n")
    print(f"  Meals logged: {stats['meals']}")
    print(f"  Activities logged: {stats['activities']}")
    print(f"  Weight entries: {stats['weight_entries']}")
    if stats["first_date"]:
        print(f"  Date range: {stats['first_date']} to {stats['last_date']}")
    print()


# --- Config ---


def cmd_config(args):
    config = db.load_config()

    updated = False
    for key in ["weight_kg", "height_cm", "age", "activity_multiplier"]:
        val = getattr(args, key, None)
        if val is not None:
            config[key] = val
            updated = True
    if args.sex:
        config["sex"] = args.sex
        updated = True

    if updated:
        db.save_config(config)
        print("Config updated.")

    if config:
        print("\nCurrent config:")
        for k, v in config.items():
            print(f"  {k}: {v}")
        bmr = db.compute_bmr(config)
        tdee = db.compute_tdee(config)
        print(f"\n  BMR: {bmr:.0f} cal | TDEE: {tdee:.0f} cal")
    else:
        print("No config set. Use flags to configure:")
        print(
            "  --weight-kg 79.4 --height-cm 178 --age 30 --sex male --activity-multiplier 1.2"
        )
    print()


# --- Activity sync commands ---


def cmd_strava_auth(args):
    import strava

    strava.authorize()


def cmd_strava_sync(args):
    import strava

    strava.sync_activities()


def cmd_oura_sync(args):
    import oura

    oura.sync_activity()


def cmd_intervals_sync(args):
    import intervals_icu

    intervals_icu.sync_activities()


# --- Combos ---


def cmd_log_combo(args):
    combos = db.load_combos()
    if args.name not in combos:
        available = ", ".join(combos.keys()) or "(none)"
        print(f"Combo '{args.name}' not found. Available: {available}")
        return

    combo = combos[args.name]
    meal_type = args.meal or combo.get("meal_type", "snack")
    scale = args.scale
    date_str = getattr(args, "date", None)
    dry_run = args.dry_run

    mode = "DRY RUN" if dry_run else "Logging"
    print(f"{mode} combo '{args.name}' (scale {scale}x):\n")

    from db import MICRO_COLS

    for item_def in combo.get("items", []):
        if item_def.get("manual"):
            micros = {}
            for col in MICRO_COLS:
                if col in item_def:
                    micros[col] = round(item_def[col] * scale, 2)
            item = _make_item(
                item_def["name"],
                "",
                item_def.get("serving", "manual"),
                {
                    "calories": round(item_def.get("calories", 0) * scale),
                    "protein_g": round(item_def.get("protein_g", 0) * scale, 1),
                    "fat_g": round(item_def.get("fat_g", 0) * scale, 1),
                    "carbs_g": round(item_def.get("carbs_g", 0) * scale, 1),
                    **micros,
                },
            )
            if dry_run:
                print(
                    f"  [manual] {item['name']}: {item['calories']} cal | "
                    f"P:{item['protein_g']}g F:{item['fat_g']}g C:{item['carbs_g']}g"
                )
            else:
                _log_meal_entry(item, meal_type, date_str)
        else:
            result = _log_fatsecret_item(
                item_def.get("query", ""),
                item_def.get("pick", 1),
                item_def.get("servings", 1),
                item_def.get("serving_name"),
                meal_type,
                date_str,
                scale=scale,
                dry_run=dry_run,
            )
            if dry_run and result:
                print(
                    f"  [search] {result['name']}: {result['calories']} cal | "
                    f"P:{result['protein_g']}g F:{result['fat_g']}g C:{result['carbs_g']}g"
                )

    if dry_run:
        print("\n(Dry run — nothing logged)")


def cmd_combo_list(args):
    combos = db.load_combos()
    if not combos:
        print("No combos defined. Add them to ~/.config/nutrition-tracker/combos.json")
        return
    print("\nAvailable combos:\n")
    for name, combo in combos.items():
        meal = combo.get("meal_type", "snack")
        items = combo.get("items", [])
        print(f"  {name} ({meal}, {len(items)} items)")
        for item_def in items:
            if item_def.get("manual"):
                print(f"    - [manual] {item_def['name']}")
            else:
                print(f"    - [search] {item_def.get('query', '?')}")
    print()


# --- Delete ---


def cmd_delete_last(args):
    recent = db.recent_meals(args.n)
    if not recent:
        print("No meals to delete.")
        return
    print(f"Deleting {len(recent)} most recent meal(s):")
    for m in recent:
        print(f"  {m['name']}: {m['calories']:.0f} cal ({m['meal_type']})")
    db.delete_meals_by_ids([m["id"] for m in recent])
    print("Deleted.")


# --- Main ---


def main():
    parser = argparse.ArgumentParser(description="Nutrition tracker CLI")
    parser.add_argument("--profile", default="default", help="User profile")
    sub = parser.add_subparsers(dest="command", required=True)

    # search
    p = sub.add_parser("search", help="Search foods")
    p.add_argument("query", help="Food search query")
    p.add_argument("--max", type=int, default=10, help="Max results")
    p.set_defaults(func=cmd_search)

    # log
    p = sub.add_parser("log", help="Search + pick + log a meal")
    p.add_argument("query", help="Food search query")
    p.add_argument(
        "--meal", default="snack", choices=["breakfast", "lunch", "dinner", "snack"]
    )
    p.add_argument("--pick", type=int, default=1, help="Pick Nth search result")
    p.add_argument("--servings", type=float, default=1, help="Number of servings")
    p.add_argument("--serving-name", default=None, help="Serving size name to match")
    p.add_argument("--date", default=None, help="Backdate entry (YYYY-MM-DD)")
    p.set_defaults(func=cmd_log)

    # log-manual
    p = sub.add_parser("log-manual", help="Log a meal with manual macros")
    p.add_argument("--name", required=True)
    p.add_argument("--calories", type=float, required=True)
    p.add_argument("--protein", type=float, default=0)
    p.add_argument("--fat", type=float, default=0)
    p.add_argument("--carbs", type=float, default=0)
    p.add_argument(
        "--meal", default="snack", choices=["breakfast", "lunch", "dinner", "snack"]
    )
    p.add_argument("--date", default=None, help="Backdate entry (YYYY-MM-DD)")
    p.set_defaults(func=cmd_log_manual)

    # workout
    p = sub.add_parser("workout", help="Log a workout")
    p.add_argument("--duration", type=int, required=True, help="Duration in minutes")
    p.add_argument("--activity", default="exercise", help="Activity type")
    p.add_argument("--calories", type=int, required=True, help="Calories burned")
    p.set_defaults(func=cmd_workout)

    # weight
    p = sub.add_parser("weight", help="Log body weight")
    p.add_argument("lbs", type=float, help="Weight in pounds")
    p.set_defaults(func=cmd_weight)

    # today
    p = sub.add_parser("today", help="Today's summary")
    p.set_defaults(func=cmd_today)

    # week
    p = sub.add_parser("week", help="Weekly summary")
    p.set_defaults(func=cmd_week)

    # status
    p = sub.add_parser("status", help="Database status")
    p.set_defaults(func=cmd_status)

    # config
    p = sub.add_parser("config", help="View/set user stats")
    p.add_argument("--weight-kg", type=float, dest="weight_kg")
    p.add_argument("--height-cm", type=float, dest="height_cm")
    p.add_argument("--age", type=int)
    p.add_argument("--sex", choices=["male", "female"])
    p.add_argument("--activity-multiplier", type=float, dest="activity_multiplier")
    p.set_defaults(func=cmd_config)

    # strava-auth
    p = sub.add_parser("strava-auth", help="Authorize Strava (one-time OAuth)")
    p.set_defaults(func=cmd_strava_auth)

    # strava-sync
    p = sub.add_parser("strava-sync", help="Sync activities from Strava")
    p.set_defaults(func=cmd_strava_sync)

    # oura-sync
    p = sub.add_parser("oura-sync", help="Sync daily activity from Oura Ring")
    p.set_defaults(func=cmd_oura_sync)

    # intervals-sync
    p = sub.add_parser("intervals-sync", help="Sync activities from Intervals.icu")
    p.set_defaults(func=cmd_intervals_sync)

    # log-combo
    p = sub.add_parser("log-combo", help="Log a predefined meal combo")
    p.add_argument("name", help="Combo name from combos.json")
    p.add_argument("--scale", type=float, default=1.0, help="Scale all servings")
    p.add_argument(
        "--meal",
        default=None,
        choices=["breakfast", "lunch", "dinner", "snack"],
        help="Override combo's default meal type",
    )
    p.add_argument("--date", default=None, help="Backdate entry (YYYY-MM-DD)")
    p.add_argument("--dry-run", action="store_true", help="Show what would be logged")
    p.set_defaults(func=cmd_log_combo)

    # combo-list
    p = sub.add_parser("combo-list", help="List available combos")
    p.set_defaults(func=cmd_combo_list)

    # delete-last
    p = sub.add_parser("delete-last", help="Delete N most recent meals")
    p.add_argument("n", type=int, help="Number of recent meals to delete")
    p.set_defaults(func=cmd_delete_last)

    args = parser.parse_args()
    db.set_profile(args.profile)
    args.func(args)


if __name__ == "__main__":
    main()
