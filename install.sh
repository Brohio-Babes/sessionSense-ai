#!/usr/bin/env bash
# SessionSense AI — Installer
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/sessionsense-ai/main/install.sh | bash

set -e

SS_HOME="${HOME}/.sessionsense"
SS_LABEL_SH="${SS_HOME}/label.sh"
SS_CONFIG="${SS_HOME}/config"
REPO_RAW="https://raw.githubusercontent.com/YOUR_USERNAME/sessionsense-ai/main"

_ss_print() { printf '\033[0;32m[SessionSense]\033[0m %s\n' "$1"; }
_ss_warn()  { printf '\033[0;33m[SessionSense]\033[0m %s\n' "$1"; }
_ss_err()   { printf '\033[0;31m[SessionSense]\033[0m %s\n' "$1"; }

_ss_print "Installing SessionSense AI..."

# Create config directory
mkdir -p "$SS_HOME"

# Download label.sh
if command -v curl &>/dev/null; then
  curl -fsSL "${REPO_RAW}/label.sh" -o "$SS_LABEL_SH"
elif command -v wget &>/dev/null; then
  wget -qO "$SS_LABEL_SH" "${REPO_RAW}/label.sh"
else
  _ss_err "curl or wget required. Please install one and retry."
  exit 1
fi

chmod +x "$SS_LABEL_SH"
_ss_print "Downloaded label.sh → ${SS_LABEL_SH}"

# Write default config if not already present
if [[ ! -f "$SS_CONFIG" ]]; then
  curl -fsSL "${REPO_RAW}/config.default" -o "$SS_CONFIG" 2>/dev/null \
    || wget -qO "$SS_CONFIG" "${REPO_RAW}/config.default" 2>/dev/null \
    || cat > "$SS_CONFIG" << 'CONFIG'
BADGE=true
TAB_TITLE=true
TAB_COLOR=true
TIME_HINT=false
GIT_CONTEXT=false
RESTORE_ON_INIT=true
CONFIG
  _ss_print "Created config → ${SS_CONFIG}"
else
  _ss_warn "Config already exists at ${SS_CONFIG} — not overwritten."
fi

# Detect shell and add source line
SOURCE_LINE="source \"${SS_LABEL_SH}\"  # SessionSense AI"
RC_FILE=""

if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == */zsh ]]; then
  RC_FILE="${HOME}/.zshrc"
elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == */bash ]]; then
  RC_FILE="${HOME}/.bashrc"
  [[ "$(uname)" == "Darwin" ]] && RC_FILE="${HOME}/.bash_profile"
fi

if [[ -n "$RC_FILE" ]]; then
  if grep -q "sessionsense" "$RC_FILE" 2>/dev/null; then
    _ss_warn "Source line already in ${RC_FILE} — skipping."
  else
    echo "" >> "$RC_FILE"
    echo "$SOURCE_LINE" >> "$RC_FILE"
    _ss_print "Added source line to ${RC_FILE}"
  fi
else
  _ss_warn "Could not detect shell rc file. Add this manually:"
  echo "  $SOURCE_LINE"
fi

# Activate in current session
source "$SS_LABEL_SH"

_ss_print "Done! Try it now:"
echo ""
echo "  label \"🧠 building something great\""
echo "  label --clear"
echo ""
echo "Edit ${SS_CONFIG} to customize modules."
