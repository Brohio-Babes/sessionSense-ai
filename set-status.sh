#!/usr/bin/env bash
# SessionSense AI — Status Indicator
# Called by Claude Code hooks to show AI activity state via tab color.
# Writes to /dev/tty directly — hook stdout is captured by Claude Code.
#
# Usage: set-status.sh [working|paused|idle]
#   working — green  (AI is executing a tool)
#   paused  — yellow (AI is between tools / composing response)
#   idle    — red    (AI done, your turn)

[[ "${TERM_PROGRAM:-}" != "iTerm.app" ]] && exit 0

_ss_color() {
  printf '\e]6;1;bg;red;brightness;%d\a\e]6;1;bg;green;brightness;%d\a\e]6;1;bg;blue;brightness;%d\a' \
    "$1" "$2" "$3" > /dev/tty 2>/dev/null
}

_ss_restore_label_color() {
  local tty_id
  tty_id=$(tty 2>/dev/null | sed 's|/dev/ttys*||')
  # Bail out if not a real TTY
  [[ "$tty_id" =~ ^[0-9]+$ ]] || { printf '\e]6;1;bg;*;default\a' > /dev/tty 2>/dev/null; return; }

  local label_file="${HOME}/.sessionsense/${tty_id}"
  if [[ -f "$label_file" ]]; then
    local label
    label=$(cat "$label_file")
    case "$label" in
      *🧠*) _ss_color 59  130 246 ;;
      *🔥*) _ss_color 239 68  68  ;;
      *🚀*) _ss_color 34  197 94  ;;
      *🔧*) _ss_color 249 115 22  ;;
      *📋*) _ss_color 168 85  247 ;;
      *)    printf '\e]6;1;bg;*;default\a' > /dev/tty 2>/dev/null ;;
    esac
  else
    printf '\e]6;1;bg;*;default\a' > /dev/tty 2>/dev/null
  fi
}

case "${1:-idle}" in
  working) _ss_color 34  197 94  ;;  # Green  — AI running a tool
  paused)  _ss_color 234 179 8   ;;  # Yellow — AI thinking / between tools
  idle)    _ss_restore_label_color ;; # Restore emoji color (or default)
esac
