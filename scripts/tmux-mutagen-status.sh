#!/bin/bash
# Render once for the shared tmux maintenance timer. Never poll from status-right.

command -v mutagen >/dev/null 2>&1 || exit 0
# A status query must not start a stopped daemon.
mutagen daemon running >/dev/null 2>&1 || exit 0
sessions="$(mutagen sync list --template '{{range .}}{{printf "%s\t%s\t%v\t%s\n" .Name .Status .Paused .Alpha.Path}}{{end}}' 2>/dev/null)" || exit 1

set_status_icon() {
  local status="$1" paused="$2"
  if [[ "$paused" == true ]]; then
    icon='⏸'
  elif [[ "$status" == Watching ]]; then
    icon='✓'
  elif [[ "$status" =~ ^(Staging|Reconciling|Saving|Scanning|Transitioning|Waiting) ]]; then
    icon='⟳'
  elif [[ "$status" =~ ^Halted ]]; then
    icon='✗'
  elif [[ "$status" =~ ^(Connecting|Disconnected) ]]; then
    icon='…'
  else
    icon='?'
  fi
}

output=''
wt_healthy=0
wt_paused=0
wt_unhealthy=0
wt_unhealthy_icons=()
wt_unhealthy_names=()
while IFS=$'\t' read -r name status paused alpha_path; do
  [[ -n "$name" ]] || continue
  set_status_icon "$status" "$paused"
  case "$name" in
    olympus)
      output+=" ${icon} ${name}"
      [[ "$icon" != '?' ]] || output+=":${status:-unknown}"
      ;;
    olympus-wt-*)
      if [[ "$paused" == true ]]; then
        ((wt_paused += 1))
      elif [[ "$status" == Watching ]]; then
        ((wt_healthy += 1))
      else
        wt_unhealthy_icons+=("$icon")
        wt_unhealthy_names+=("${alpha_path##*/}")
        ((wt_unhealthy += 1))
      fi
      ;;
  esac
done <<< "$sessions"

if ((wt_healthy + wt_paused + wt_unhealthy > 0)); then
  output+=" | wt: ${wt_healthy}✓"
  if ((wt_paused > 0)); then
    output+=" ${wt_paused}⏸"
  fi
  for ((i = 0; i < wt_unhealthy && i < 3; i++)); do
    output+=" ${wt_unhealthy_icons[$i]} ${wt_unhealthy_names[$i]}"
  done
  if ((wt_unhealthy > 3)); then
    output+=" +$((wt_unhealthy - 3))"
  fi
fi

if [[ -n "$output" ]]; then
  printf 'mut:%s\n' "$output"
fi
