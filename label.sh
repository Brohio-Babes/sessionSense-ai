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
  local raw
  raw=$(tty 2>/dev/null)
  # Extract numeric portion: /dev/ttys003 → 003
  printf '%s' "$raw" | sed 's|/dev/ttys*||'
}

_ss_label_file()     { echo "${_SS_HOME}/$(_ss_tty_id)"; }
_ss_timestamp_file() { echo "${_SS_HOME}/$(_ss_tty_id).time"; }

# ── Stale TTY pruning ────────────────────────────────────────────────────────

_ss_prune_stale() {
  [[ -d "$_SS_HOME" ]] || return
  for f in "${_SS_HOME}"/[0-9]*; do
    [[ -f "$f" ]] || continue
    local tty_id
    tty_id=$(basename "$f" .time)
    # Skip .time files — they're paired with their label file
    [[ "$tty_id" == *.time ]] && continue
    if [[ ! -e "/dev/ttys${tty_id}" ]]; then
      rm -f "$f" "${f}.time"
    fi
  done
}
