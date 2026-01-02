#!/usr/bin/env bash

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.file // ""')

if [[ "$file_path" == *.py && -f "$file_path" ]]; then
    ty_output=$(uv run ty check "$file_path" 2>&1)
    ty_exit=$?

    if [[ $ty_exit -ne 0 && -n "$ty_output" ]]; then
        jq -n --arg reason "Type errors found in $file_path:
$ty_output" '{
            "decision": "block",
            "reason": $reason
        }'
        exit 0
    fi
fi

exit 0
