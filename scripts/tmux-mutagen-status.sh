#!/usr/bin/env bash
# tmux-mutagen-status.sh — mutagen sync status for tmux statusline

if ! command -v mutagen &>/dev/null; then
  exit 0
fi

# Check if daemon is running
if ! mutagen daemon running &>/dev/null; then
  exit 0
fi

output=""
while IFS=$'\t' read -r name status paused; do
  [[ -z "$name" ]] && continue
  if [[ "$paused" == "true" ]]; then
    icon="⏸"
    output+=" ${icon} ${name}"
  elif [[ "$status" == "Watching" ]]; then
    icon="✓"
    output+=" ${icon} ${name}"
  elif [[ "$status" =~ ^Staging || "$status" =~ ^Reconciling || "$status" =~ ^Saving || "$status" =~ ^Scanning ]]; then
    icon="⟳"
    output+=" ${icon} ${name}"
  elif [[ "$status" =~ ^Halted ]]; then
    icon="✗"
    output+=" ${icon} ${name}"
  elif [[ "$status" =~ ^"Connecting" ]]; then
    icon="…"
    output+=" ${icon} ${name}"
  else
    icon="?"
    output+=" ${icon} ${name}"
  fi
done < <(mutagen sync list --template '{{range .}}{{printf "%s\t%s\t%v" .Name .Status .Paused}}{{"\n"}}{{end}}' 2>/dev/null)

if [[ -n "$output" ]]; then
  echo "mut:${output}"
fi
