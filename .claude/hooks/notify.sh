#!/bin/bash
# Requires: brew install terminal-notifier

MSG="Claude needs your attention"
TITLE="Claude Code"

get_bundle_id() {
    if [[ -n "$__CFBundleIdentifier" ]]; then
        echo "$__CFBundleIdentifier"
        return
    fi

    case "$TERM_PROGRAM" in
        WezTerm) echo "com.github.wez.wezterm" ;;
        iTerm.app) echo "com.googlecode.iterm2" ;;
        Apple_Terminal) echo "com.apple.Terminal" ;;
        vscode)
            if [[ -n "$CURSOR_TRACE_ID" ]]; then
                echo "com.todesktop.230313mzl4w4u92"
            else
                echo "com.microsoft.VSCode"
            fi
            ;;
        *)
            osascript -e 'tell application "System Events" to get bundle identifier of (first process whose frontmost is true)' 2>/dev/null
            ;;
    esac
}

BUNDLE=$(get_bundle_id)

if ! command -v terminal-notifier &>/dev/null; then
    osascript -e "display notification \"$MSG\" with title \"$TITLE\""
    printf '\a'
    exit 0
fi

if [[ -n "$TMUX" && -n "$TMUX_PANE" ]]; then
    TMUX_BIN=$(command -v tmux)
    if [[ -n "$BUNDLE" ]]; then
        terminal-notifier -message "$MSG" -title "$TITLE" \
            -execute "osascript -e 'activate application id \"$BUNDLE\"' && sleep 0.1 && $TMUX_BIN switch-client -t '$TMUX_PANE'"
    else
        terminal-notifier -message "$MSG" -title "$TITLE" \
            -execute "$TMUX_BIN switch-client -t '$TMUX_PANE'"
    fi
elif [[ -n "$BUNDLE" ]]; then
    terminal-notifier -message "$MSG" -title "$TITLE" -activate "$BUNDLE"
else
    terminal-notifier -message "$MSG" -title "$TITLE"
fi

printf '\a'
