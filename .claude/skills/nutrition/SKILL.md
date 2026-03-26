---
name: nutrition
description: >-
  Personal nutrition tracker. Search foods via FatSecret API, log meals/workouts/weight,
  compute daily calorie deficit with TDEE and %DV micronutrient tracking.
  SQLite-backed local storage with Strava, Oura, and Intervals.icu activity integrations.
  Use when the user wants to track food, log meals, check calorie intake, or manage nutrition.
allowed-tools: Bash(uv run:*), Bash(source ~/.zshrc:*)
---

# Nutrition Tracker CLI

Track meals, workouts, and weight with FatSecret food search, micronutrient %DV tracking, and local SQLite storage.

## Quick Reference

```bash
# All commands run from ~/.claude/skills/nutrition/
uv run python nutrition_cli.py <command>
```

| Command | Description |
|---|---|
| `search "query"` | Search FatSecret for foods |
| `log "query" --meal lunch --pick 1` | Search + pick + log meal |
| `log-manual --name "X" --calories 300 ...` | Log meal with manual macros |
| `workout --duration 45 --activity running --calories 400` | Log manual workout |
| `weight 174.8` | Log body weight (lbs) |
| `today` | Daily summary with %DV |
| `week` | 7-day rolling summary |
| `status` | Database stats |
| `config --weight-kg 73.9 ...` | Set user stats for TDEE |
| `intervals-sync` | Sync activities from Intervals.icu |
| `oura-sync` | Sync daily NEAT from Oura Ring |
| `strava-sync` | Sync activities from Strava |
| `strava-auth` | One-time Strava OAuth |
| `log-combo "name" --scale 0.6` | Log a predefined meal combo |
| `combo-list` | List available combos |
| `delete-last N` | Delete N most recent meals |

## Setup

### Environment Variables (`~/.zshrc`)

```bash
# Required — FatSecret food search
export FATSECRET_CLIENT_ID="..."
export FATSECRET_CLIENT_SECRET="..."

# Optional — activity integrations
export STRAVA_CLIENT_ID="..."
export STRAVA_CLIENT_SECRET="..."
export OURA_TOKEN="..."
export INTERVALS_API_KEY="..."
export INTERVALS_ATHLETE_ID="i12345"
```

### User Config (BMR/TDEE)

```bash
uv run python nutrition_cli.py config --weight-kg 75 --height-cm 175 --age 30 --sex male --activity-multiplier 1.2
```

## Logging Meals

### Search + pick

```bash
# Pick 1st result, default serving
uv run python nutrition_cli.py log "TJ orange chicken" --meal lunch --pick 1

# Multiple servings of a specific serving size
uv run python nutrition_cli.py log "strawberries" --meal breakfast --pick 1 --servings 8 --serving-name "1 medium"

# Backdate an entry
uv run python nutrition_cli.py log "coffee" --meal breakfast --pick 1 --date 2026-03-08
```

Options: `--meal` (breakfast/lunch/dinner/snack), `--pick N` (Nth result), `--servings N` (multiplier), `--serving-name "desc"` (fuzzy match), `--date YYYY-MM-DD` (backdate).

**Serving size tip**: `--serving-name` does fuzzy substring matching, which can silently pick the wrong size (e.g. "1 tsp" matches "1 tbsp"). When the desired size isn't available, use `--servings` as a fraction of a known serving instead (e.g. 1 tsp = `--servings 0.333 --serving-name "1 tbsp"`).

### Manual entry

```bash
uv run python nutrition_cli.py log-manual --name "Smoothie" --calories 330 --protein 16 --fat 14 --carbs 36 --meal breakfast
```

**Prefer `log` over `log-manual` for composite meals** (e.g. smoothies, salads). Log each ingredient separately via FatSecret search so micronutrients are captured. Only use `log-manual` for items not in FatSecret (see/create `manual_foods.md`).

### Partial composite meals

For "3/4 of a smoothie with 1 avocado, 10 strawberries, 3 scoops whey, 1 lime", multiply each ingredient count by the fraction and use `--servings`:

```bash
uv run python nutrition_cli.py log "avocado" --meal snack --pick 1 --servings 0.75 --serving-name "avocado"
uv run python nutrition_cli.py log "strawberries" --meal snack --pick 1 --servings 7.5 --serving-name "1 medium"
uv run python nutrition_cli.py log "naked whey protein" --meal snack --pick 1 --servings 2.25 --serving-name "1 scoop"
uv run python nutrition_cli.py log "lime" --meal snack --pick 1 --servings 0.75
```

Formula: `--servings = ingredient_count × fraction`. This preserves all FatSecret micronutrients.

## Meal Combos

Predefined meal templates in `~/.config/nutrition-tracker/combos.json`. Each combo has a default meal type and a list of items (FatSecret searches or manual entries with inline nutrition).

```bash
# Log supplements
uv run python nutrition_cli.py log-combo "morning supplements"

# Log 60% of oatmeal mix
uv run python nutrition_cli.py log-combo "oatmeal mix" --scale 0.6

# Preview without logging
uv run python nutrition_cli.py log-combo "oatmeal mix" --scale 0.6 --dry-run

# Override meal type or backdate
uv run python nutrition_cli.py log-combo "oatmeal mix" --meal snack --date 2026-03-08
```

Options: `--scale N` (multiply all servings/amounts), `--meal` (override default), `--date` (backdate), `--dry-run` (preview only).

Combo items are either `{"query": "...", "pick": 1, "servings": 2}` (FatSecret search) or `{"manual": true, "name": "...", "vitamin_c": 100, ...}` (manual with inline micros). See `combo-list` for current combos.

## Micronutrients & Daily Values

FatSecret returns 12 micronutrients per serving: saturated/poly/mono fat, cholesterol, sodium, potassium, fiber, sugar, vitamin A, vitamin C, calcium, iron. All stored in the DB and shown as %DV in `today`.

### Daily Value Targets

Targets are exercise-adjusted and body-weight-scaled:

| Nutrient | Target | Source |
|---|---|---|
| Calories | TDEE (BMR × activity multiplier) | Mifflin-St Jeor |
| Protein | 1.6 g/kg bodyweight | Athletic recommendation |
| Sodium | 2,300mg + 600mg/hr exercise | FDA + ACSM sweat loss |
| Potassium | 4,700mg + 175mg/hr exercise | FDA + Baker et al. 2019 |
| Other micros | FDA Daily Values | Fixed, not exercise-scaled |

Exercise hours are computed from Intervals.icu/Strava/manual activities (Oura NEAT excluded since it's passive). Uses `elapsed_time` from Intervals.icu (includes stops, when you're still sweating).

### Configurable Overrides (in config.json)

```json
{
  "protein_g_per_kg": 1.6,
  "sodium_mg_per_exercise_hr": 600,
  "potassium_mg_per_exercise_hr": 175,
  "daily_values": {
    "fiber_g": 35
  }
}
```

## Activity Integrations

### Sync Order

Sync Intervals.icu/Strava **before** Oura. Oura subtracts workout calories from other sources to compute NEAT (non-exercise activity thermogenesis), avoiding double-counting.

```bash
uv run python nutrition_cli.py intervals-sync   # structured workouts first
uv run python nutrition_cli.py oura-sync         # NEAT = active_calories - workout_calories
```

**Always sync before showing daily summaries.** Oura NEAT for today may not be available until the ring syncs later (typically evening/overnight), so yesterday's data is most reliable. For multi-profile, sync each profile separately:

```bash
uv run python nutrition_cli.py --profile other oura-sync
```

### Intervals.icu

Primary source for cycling and structured workouts (synced from Strava automatically). Syncs last 30 days. API key auth. Uses `elapsed_time` for duration.

### Oura Ring

Daily non-exercise active calories (walking, steps, general movement). Syncs last 7 days. Subtracts known workout calories from Intervals.icu/Strava/manual to avoid overlap. Oura API field for date is `day`, not `date`. Today's data may not be available until the ring syncs later.

### Strava

Direct Strava sync. Mostly redundant if using Intervals.icu (which auto-syncs from Strava). Useful for runs/swims not in Intervals.icu. Requires one-time OAuth via `strava-auth`.

## Architecture

```
~/.config/nutrition-tracker/
├── nutrition.db          SQLite database (meals, weight, activities)
├── config.json           User stats, DV overrides
├── combos.json           Predefined meal combos
├── fatsecret_token.json  Cached FatSecret API token
└── strava_token.json     Strava OAuth tokens (after strava-auth)
```

### Database Schema

**meals**: id, timestamp, meal_type, name, serving, calories, protein_g, fat_g, carbs_g, + 12 micronutrient columns (saturated_fat_g, polyunsaturated_fat_g, monounsaturated_fat_g, cholesterol_mg, sodium_mg, potassium_mg, fiber_g, sugar_g, vitamin_a, vitamin_c, calcium, iron)

**weight**: id, timestamp, weight_lbs

**activities**: id, timestamp, activity_type, name, duration_minutes, calories_burned, distance_km, source

Activity sources: `manual`, `strava`, `oura`, `intervals.icu`

### Deficit Calculation

```
TDEE = BMR (Mifflin-St Jeor) × activity_multiplier
Net  = calories_consumed - calories_burned
Deficit = TDEE - Net
```

## Notes

- FatSecret attribution required: results display "Powered by FatSecret"
- `--serving-name` does fuzzy substring matching (both directions) on serving descriptions
- All timestamps stored as ISO 8601 UTC; queries use local timezone
- Items not in FatSecret can be logged via `log-manual` or direct DB insert with micronutrients — see `manual_foods.md` for a reference of known items with full nutrition data
