#!/usr/bin/env bash
# SessionSense AI — POC v2: Badge + Title + Tab Color (iTerm2)
# Falls back to title-only on non-iTerm2 terminals.
# Usage: source this file, then run: label "your context"

_ss_is_iterm() { [[ "$TERM_PROGRAM" == "iTerm.app" ]]; }

_ss_set_badge() {
  local text="$1"
  local encoded
  encoded=$(printf '%s' "$text" | base64)
  printf '\e]1337;SetBadgeFormat=%s\a' "$encoded"
}

_ss_clear_badge() {
  printf '\e]1337;SetBadgeFormat=\a'
}

_ss_set_tab_color() {
  local r=$1 g=$2 b=$3
  printf '\e]6;1;bg;red;brightness;%d\a' "$r"
  printf '\e]6;1;bg;green;brightness;%d\a' "$g"
  printf '\e]6;1;bg;blue;brightness;%d\a' "$b"
}

_ss_reset_tab_color() {
  printf '\e]6;1;bg;*;default\a'
}

_ss_apply_color() {
  local text="$1"
  case "$text" in
    *🧠*) _ss_set_tab_color 59  130 246 ;;  # Blue  — brainstorm/plan
    *🔥*) _ss_set_tab_color 239 68  68  ;;  # Red   — debug/incident
    *🚀*) _ss_set_tab_color 34  197 94  ;;  # Green — deploy/ship
    *🔧*) _ss_set_tab_color 249 115 22  ;;  # Orange — infra/config
    *📋*) _ss_set_tab_color 168 85  247 ;;  # Purple — review/docs
    *)    _ss_reset_tab_color ;;
  esac
}

label() {
  if [[ "$1" == "--clear" ]]; then
    printf '\e]0;\a'
    if _ss_is_iterm; then
      _ss_clear_badge
      _ss_reset_tab_color
    fi
    echo "SessionSense: label cleared"
    return
  fi

  local text="$*"
  if [[ -z "$text" ]]; then
    echo "Usage: label \"your context here\""
    echo "       label --clear"
    return 1
  fi

  # Always set tab title (works everywhere)
  printf '\e]0;%s\a' "$text"

  # iTerm2-only enhancements
  if _ss_is_iterm; then
    _ss_set_badge "$text"
    _ss_apply_color "$text"
  fi

  echo "SessionSense: labeled → $text"
}
