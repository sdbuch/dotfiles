#!/usr/bin/env bash
# Claude Code status line — mirrors typewritten singleline_verbose layout
# Colors from TYPEWRITTEN_COLOR_MAPPINGS:
#   primary:   #9FA0E1  (lavender)
#   secondary: #81D0C9  (teal)
#   accent:    #E4E3E1  (light gray)
#   notice:    #F0C66F  (yellow)

input=$(cat)

user=$(whoami)
host=$(hostname -s)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten cwd: show ~ for home, otherwise basename only
home="$HOME"
if [ "$cwd" = "$home" ]; then
    short_cwd="~"
else
    short_cwd="$(basename "$cwd")"
fi

# Git branch (skip optional locks for speed)
git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)

# Build right side: dir -> git_branch [ctx%]
right=""
right="${right}$(printf '\033[38;2;159;160;225m%s\033[0m' "$short_cwd")"
if [ -n "$git_branch" ]; then
    right="${right} $(printf '\033[38;2;225;227;225m%s\033[0m' "->")"
    right="${right} $(printf '\033[38;2;129;208;201m%s\033[0m' "$git_branch")"
fi
if [ -n "$used_pct" ]; then
    used_int=${used_pct%.*}
    right="${right}   $(printf '\033[38;2;166;205;119mctx:%2d%%\033[0m' "$used_int")"
fi

# Build left side: user@host
left="$(printf '\033[38;2;240;141;113m%s\033[0m' "$user")$(printf '\033[38;2;225;227;225m%s\033[0m' "@")$(printf '\033[38;2;159;160;225m%s\033[0m' "$host")"

printf '%s    %s\n' "$left" "$right"
