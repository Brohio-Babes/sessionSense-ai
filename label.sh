#!/usr/bin/env bash
# SessionSense AI — Main Script
# Source this file in your .bashrc or .zshrc:
#   source ~/.sessionsense/label.sh
#
# Usage:
#   label "🧠 your context here"   — set label
#   label --clear                  — clear label
#   label --status                 — show current label

# ── Config ───────────────────────────────────────────────────────────────────

_SS_HOME="${HOME}/.sessionsense"
_SS_CONFIG="${_SS_HOME}/config"

# Load user config, falling back to defaults
_ss_load_config() {
  # Defaults
  BADGE=true
  TAB_TITLE=true
  TAB_COLOR=true
  TIME_HINT=false
  GIT_CONTEXT=false
  RESTORE_ON_INIT=true

  # Override with user config if present
  [[ -f "$_SS_CONFIG" ]] && source "$_SS_CONFIG"
}

_ss_load_config

# ── Environment detection ────────────────────────────────────────────────────

_ss_is_iterm() { [[ "$TERM_PROGRAM" == "iTerm.app" ]]; }

_ss_tty_id() {
  local raw id
  raw=$(tty 2>/dev/null)
  id=$(printf '%s' "$raw" | sed 's|/dev/ttys*||')
  # Only return numeric IDs — guard against "not a tty" in non-interactive contexts
  [[ "$id" =~ ^[0-9]+$ ]] && printf '%s' "$id"
}

_ss_label_file()     { echo "${_SS_HOME}/$(_ss_tty_id)"; }
_ss_timestamp_file() { echo "${_SS_HOME}/$(_ss_tty_id).time"; }

# ── Stale TTY pruning ────────────────────────────────────────────────────────

_ss_prune_stale() {
  [[ -d "$_SS_HOME" ]] || return
  for f in "${_SS_HOME}"/[0-9]*; do
    [[ -f "$f" ]] || continue
    # Skip .time files — they're paired with their label file
    [[ "$f" == *.time ]] && continue
    local tty_id
    tty_id=$(basename "$f")
    if [[ ! -e "/dev/ttys${tty_id}" ]]; then
      rm -f "$f" "${f}.time"
    fi
  done
}

# ── Display functions ────────────────────────────────────────────────────────

_ss_set_badge() {
  local encoded
  encoded=$(printf '%s' "$1" | base64)
  printf '\e]1337;SetBadgeFormat=%s\a' "$encoded"
}

_ss_clear_badge() {
  printf '\e]1337;SetBadgeFormat=\a'
}

_ss_set_tab_color() {
  printf '\e]6;1;bg;red;brightness;%d\a'   "$1"
  printf '\e]6;1;bg;green;brightness;%d\a' "$2"
  printf '\e]6;1;bg;blue;brightness;%d\a'  "$3"
}

_ss_reset_tab_color() {
  printf '\e]6;1;bg;*;default\a'
}

_ss_apply_color() {
  [[ "$TAB_COLOR" != "true" ]] && return
  ! _ss_is_iterm && return
  case "$1" in
    *🧠*) _ss_set_tab_color 59  130 246 ;;  # Blue   — brainstorm/plan
    *🔥*) _ss_set_tab_color 239 68  68  ;;  # Red    — debug/incident
    *🚀*) _ss_set_tab_color 34  197 94  ;;  # Green  — deploy/ship
    *🔧*) _ss_set_tab_color 249 115 22  ;;  # Orange — infra/config
    *📋*) _ss_set_tab_color 168 85  247 ;;  # Purple — review/docs
    *)    _ss_reset_tab_color ;;
  esac
}

_ss_time_hint() {
  [[ "$TIME_HINT" != "true" ]] && return
  local ts_file
  ts_file=$(_ss_timestamp_file)
  [[ ! -f "$ts_file" ]] && return
  local elapsed mins
  elapsed=$(( $(date +%s) - $(cat "$ts_file") ))
  mins=$(( elapsed / 60 ))
  if (( mins < 60 )); then
    printf '· %dm' "$mins"
  else
    printf '· %dh' "$(( mins / 60 ))"
  fi
}

_ss_git_context() {
  [[ "$GIT_CONTEXT" != "true" ]] && return
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
  printf '· %s' "$branch"
}

_ss_build_display() {
  local base="$1"
  local hint git_ctx extras
  hint=$(_ss_time_hint)
  git_ctx=$(_ss_git_context)
  extras="${hint}${git_ctx:+ $git_ctx}"
  [[ -n "$extras" ]] && printf '%s %s' "$base" "$extras" || printf '%s' "$base"
}

_ss_apply_label() {
  local text="$1"
  local display
  display=$(_ss_build_display "$text")

  [[ "$TAB_TITLE" == "true" ]] && printf '\e]0;%s\a' "$display"

  if _ss_is_iterm; then
    [[ "$BADGE" == "true" ]] && _ss_set_badge "$display"
    _ss_apply_color "$text"
  fi
}

# ── Persistence ──────────────────────────────────────────────────────────────

_ss_save_label() {
  mkdir -p "$_SS_HOME"
  printf '%s' "$1" > "$(_ss_label_file)"
  date +%s > "$(_ss_timestamp_file)"
}

_ss_load_label() {
  local lf
  lf=$(_ss_label_file)
  [[ -f "$lf" ]] && cat "$lf"
}

_ss_restore() {
  [[ "$RESTORE_ON_INIT" != "true" ]] && return
  local stored
  stored=$(_ss_load_label)
  [[ -z "$stored" ]] && return
  _ss_apply_label "$stored"
}

# ── PROMPT_COMMAND hook (refreshes time hint each prompt) ────────────────────

_ss_prompt_hook() {
  local stored
  stored=$(_ss_load_label)
  [[ -z "$stored" ]] && return
  _ss_apply_label "$stored"
}

if [[ -n "$BASH_VERSION" ]]; then
  if [[ "$PROMPT_COMMAND" != *"_ss_prompt_hook"* ]]; then
    PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }_ss_prompt_hook"
  fi
elif [[ -n "$ZSH_VERSION" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _ss_prompt_hook
fi

# ── Public API ───────────────────────────────────────────────────────────────

label() {
  case "$1" in
    --clear)
      rm -f "$(_ss_label_file)" "$(_ss_timestamp_file)"
      printf '\e]0;\a'
      if _ss_is_iterm; then
        _ss_clear_badge
        _ss_reset_tab_color
      fi
      echo "SessionSense: label cleared"
      ;;

    --status)
      local stored
      stored=$(_ss_load_label)
      if [[ -z "$stored" ]]; then
        echo "SessionSense: no label set"
      else
        echo "SessionSense: $stored"
      fi
      ;;

    "")
      echo "Usage:"
      echo "  label \"🧠 your context\"   — set label"
      echo "  label --clear             — clear label"
      echo "  label --status            — show current label"
      ;;

    *)
      local text="$*"
      _ss_save_label "$text"
      _ss_apply_label "$text"
      echo "SessionSense: labeled → $text"
      ;;
  esac
}

# ── Init ─────────────────────────────────────────────────────────────────────

_ss_prune_stale
_ss_restore
