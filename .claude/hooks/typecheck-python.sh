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

if [[ "$file_path" == *.py && -f "$file_path" ]]; then
    if has_uv_project; then
        ty_output=$(uv run ty check --output-format concise "$file_path" 2>&1)
    else
        ty_output=$(uvx ty check --output-format concise "$file_path" 2>&1)
    fi
    ty_exit=$?

    if [[ $ty_exit -ne 0 && -n "$ty_output" ]]; then
        echo "Type warnings in $file_path:"
        echo "$ty_output"
    fi
fi

exit 0
