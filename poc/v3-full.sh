#!/usr/bin/env bash
# SessionSense AI — POC v3: Full (badge + title + color + time hint + persistence)
# Usage: source this file, then run: label "your context"

_SS_DIR="${HOME}/.sessionsense-poc"
_SS_TIME_HINT=true   # set to false to disable

_ss_is_iterm() { [[ "$TERM_PROGRAM" == "iTerm.app" ]]; }

_ss_tty_id() { tty 2>/dev/null | sed 's|/dev/ttys*||'; }

_ss_label_file() { echo "${_SS_DIR}/$(_ss_tty_id)"; }

_ss_timestamp_file() { echo "${_SS_DIR}/$(_ss_tty_id).time"; }

_ss_set_badge() {
  local encoded
  encoded=$(printf '%s' "$1" | base64)
  printf '\e]1337;SetBadgeFormat=%s\a' "$encoded"
}

_ss_clear_badge() { printf '\e]1337;SetBadgeFormat=\a'; }

_ss_set_tab_color() {
  printf '\e]6;1;bg;red;brightness;%d\a'   "$1"
  printf '\e]6;1;bg;green;brightness;%d\a' "$2"
  printf '\e]6;1;bg;blue;brightness;%d\a'  "$3"
}

_ss_reset_tab_color() { printf '\e]6;1;bg;*;default\a'; }

_ss_apply_color() {
  case "$1" in
    *🧠*) _ss_set_tab_color 59  130 246 ;;
    *🔥*) _ss_set_tab_color 239 68  68  ;;
    *🚀*) _ss_set_tab_color 34  197 94  ;;
    *🔧*) _ss_set_tab_color 249 115 22  ;;
    *📋*) _ss_set_tab_color 168 85  247 ;;
    *)    _ss_reset_tab_color ;;
  esac
}

_ss_time_hint() {
  [[ "$_SS_TIME_HINT" != "true" ]] && return
  local ts_file
  ts_file=$(_ss_timestamp_file)
  [[ ! -f "$ts_file" ]] && return
  local then now elapsed mins
  then=$(cat "$ts_file")
  now=$(date +%s)
  elapsed=$(( now - then ))
  mins=$(( elapsed / 60 ))
  if (( mins < 60 )); then
    echo "${mins}m"
  else
    echo "$(( mins / 60 ))h"
  fi
}

_ss_apply_label() {
  local text="$1"
  local hint
  hint=$(_ss_time_hint)
  local display="$text"
  [[ -n "$hint" ]] && display="${text} · ${hint}"

  printf '\e]0;%s\a' "$display"

  if _ss_is_iterm; then
    _ss_set_badge "$display"
    _ss_apply_color "$text"
  fi
}

_ss_restore() {
  local lf
  lf=$(_ss_label_file)
  [[ -f "$lf" ]] || return
  local stored
  stored=$(cat "$lf")
  [[ -z "$stored" ]] && return
  _ss_apply_label "$stored"
}

# Hook into PROMPT_COMMAND to keep time hint current
_ss_prompt_hook() {
  local lf
  lf=$(_ss_label_file)
  [[ -f "$lf" ]] && _ss_apply_label "$(cat "$lf")"
}

label() {
  mkdir -p "${_SS_DIR}"

  if [[ "$1" == "--clear" ]]; then
    rm -f "$(_ss_label_file)" "$(_ss_timestamp_file)"
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

  # Persist
  echo "$text" > "$(_ss_label_file)"
  date +%s > "$(_ss_timestamp_file)"

  _ss_apply_label "$text"
  echo "SessionSense: labeled → $text"
}

# Register PROMPT_COMMAND hook
if [[ -n "$BASH_VERSION" ]]; then
  if [[ "$PROMPT_COMMAND" != *"_ss_prompt_hook"* ]]; then
    PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }_ss_prompt_hook"
  fi
fi

# Restore label on source
_ss_restore
