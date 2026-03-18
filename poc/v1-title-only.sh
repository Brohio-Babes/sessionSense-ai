#!/usr/bin/env bash
# SessionSense AI — POC v1: Title Only
# Sets tab and window title. Works in all xterm-compatible terminals.
# Usage: source this file, then run: label "your context"

label() {
  if [[ "$1" == "--clear" ]]; then
    printf '\e]0;\a'
    echo "SessionSense: label cleared"
    return
  fi

  local text="$*"
  if [[ -z "$text" ]]; then
    echo "Usage: label \"your context here\""
    echo "       label --clear"
    return 1
  fi

  # Set both window title and tab title
  printf '\e]0;%s\a' "$text"
  echo "SessionSense: labeled → $text"
}
