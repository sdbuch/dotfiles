#!/usr/bin/env bash

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.file // ""')

has_uv_project() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        [[ -f "$dir/pyproject.toml" ]] && return 0
        dir=$(dirname "$dir")
    done
    return 1
}

if [[ "$file_path" == *.py ]]; then
    if has_uv_project; then
        uv run ruff format "$file_path"
        uv run ruff check --select I --fix --quiet "$file_path"
        uv run ruff check --fix --quiet --ignore E501,F401,E731,E741 "$file_path"
    else
        uvx ruff format "$file_path"
        uvx ruff check --select I --fix --quiet "$file_path"
        uvx ruff check --fix --quiet --ignore E501,F401,E731,E741 "$file_path"
    fi
fi

exit 0
