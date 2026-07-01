#!/usr/bin/env bash

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.file // ""')

run_ruff() {
    # Prefer uv run if we're inside a uv project that has a working venv with ruff.
    # This respects project-local ruff config/version pins.
    # Fall back to uvx (isolated, always works) for repos that use another
    # build tool instead of uv and don't have ruff in their deps.
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/pyproject.toml" && -d "$dir/.venv" ]]; then
            # Project has both pyproject.toml and a materialized venv; check for ruff in it.
            if [[ -x "$dir/.venv/bin/ruff" ]]; then
                echo "uv run"
                return
            fi
        fi
        dir=$(dirname "$dir")
    done
    echo "uvx"
}

if [[ "$file_path" == *.py ]]; then
    # Skip repos that manage ruff via another tool. Running `uvx ruff` against
    # them uses ruff defaults instead of the project's config, which can
    # silently break code, for example when the repo's pinned ruff knows about
    # lint rules that the latest uvx ruff does not.
    #   - [tool.black]  → repo uses black
    #   - pants.toml    → repo uses pants-wrapped ruff with project rules
    check_dir="$(dirname "$file_path")"
    while [[ "$check_dir" != "/" ]]; do
        if [[ -f "$check_dir/pyproject.toml" ]] && grep -q '\[tool\.black\]' "$check_dir/pyproject.toml" 2>/dev/null; then
            exit 0
        fi
        if [[ -f "$check_dir/pants.toml" ]]; then
            exit 0
        fi
        check_dir=$(dirname "$check_dir")
    done

    # Require an ancestor pyproject.toml with a [tool.ruff] section. Otherwise
    # we'd format files in sibling dirs of ruff-configured projects using ruff
    # defaults (e.g. flash-attention has ruff only in flash_attn/cute/, but
    # the hook was reformatting files in hopper/ and csrc/ with defaults that
    # don't match the project's style). Walk up from the file's dir; if we
    # find a pyproject with [tool.ruff] or [tool.ruff.*], keep formatting.
    # Otherwise the project didn't opt in — skip.
    check_dir="$(dirname "$file_path")"
    has_ruff_config=0
    while [[ "$check_dir" != "/" ]]; do
        if [[ -f "$check_dir/pyproject.toml" ]] && grep -qE '^\[tool\.ruff(\.|])' "$check_dir/pyproject.toml" 2>/dev/null; then
            has_ruff_config=1
            break
        fi
        check_dir=$(dirname "$check_dir")
    done
    if [[ $has_ruff_config == 0 ]]; then
        exit 0
    fi

    runner=$(run_ruff)
    $runner ruff format "$file_path"
    $runner ruff check --select I --fix --quiet "$file_path"
    $runner ruff check --fix --quiet --ignore E501,F401,E731,E741 "$file_path"
fi

exit 0
