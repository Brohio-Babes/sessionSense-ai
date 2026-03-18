# SessionSense AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a zero-dependency shell tool that labels terminal windows/tabs with human-readable context for AI-assisted development workflows, with full iTerm2 support and graceful fallback for all other terminals.

**Architecture:** A sourced shell script (`label.sh`) exposes a `label` command that detects the terminal environment and applies the appropriate display outputs — iTerm2 badge + tab title + tab color for iTerm2, xterm title escape for everything else. Labels persist to `~/.sessionsense/<tty_id>` and restore automatically on new shells. Three POC scripts ship first for UX validation before the full system is assembled.

**Tech Stack:** Pure bash (no dependencies), iTerm2 proprietary escape sequences, xterm ANSI escape codes, base64 (macOS built-in)

---

## File Map

| File | Responsibility |
|------|---------------|
| `poc/v1-title-only.sh` | POC: tab + window title via xterm escape only |
| `poc/v2-badge-title.sh` | POC: badge + tab title + tab color (iTerm2) |
| `poc/v3-full.sh` | POC: badge + title + color + time hint + TTY persistence |
| `label.sh` | Main script — source this in `.bashrc`/`.zshrc` |
| `config.default` | Default config template with inline documentation |
| `install.sh` | One-command installer (curl-pipe-bash friendly) |
| `README.md` | User-facing docs, install instructions, examples |

---

## Task 1: Repo scaffold

**Files:**
- Create: `poc/.gitkeep`
- Create: `.gitignore`

- [ ] **Step 1: Create .gitignore**

```bash
cat > /Users/schmidt/Documents/git2/sessionsense-ai/.gitignore << 'EOF'
.DS_Store
*.swp
EOF
```

- [ ] **Step 2: Create poc directory**

```bash
mkdir -p /Users/schmidt/Documents/git2/sessionsense-ai/poc
```

- [ ] **Step 3: Commit scaffold**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add .gitignore poc/
git commit -m "chore: repo scaffold"
```

---

## Task 2: POC v1 — title only

**Files:**
- Create: `poc/v1-title-only.sh`

This is the most compatible variant. Works in iTerm2, Cursor, Terminal.app, and any xterm-compatible terminal.

- [ ] **Step 1: Write v1-title-only.sh**

```bash
cat > /Users/schmidt/Documents/git2/sessionsense-ai/poc/v1-title-only.sh << 'SCRIPT'
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
SCRIPT
chmod +x /Users/schmidt/Documents/git2/sessionsense-ai/poc/v1-title-only.sh
```

- [ ] **Step 2: Smoke test v1 in your terminal**

```bash
source /Users/schmidt/Documents/git2/sessionsense-ai/poc/v1-title-only.sh
label "🧠 testing v1 title-only"
```

Expected: Tab title changes to `🧠 testing v1 title-only`. Run `label --clear` to reset.

- [ ] **Step 3: Commit**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add poc/v1-title-only.sh
git commit -m "feat: POC v1 title-only label"
```

---

## Task 3: POC v2 — badge + title + tab color

**Files:**
- Create: `poc/v2-badge-title.sh`

iTerm2-enhanced variant. Badge overlays the viewport. Tab color gives instant visual categorization.

**Key escape sequences:**
- Badge: `\e]1337;SetBadgeFormat=<base64>\a`
- Tab title: `\e]0;text\a`
- Tab color: `\e]6;1;bg;red;brightness;N\a` (repeated for R, G, B)

- [ ] **Step 1: Write v2-badge-title.sh**

```bash
cat > /Users/schmidt/Documents/git2/sessionsense-ai/poc/v2-badge-title.sh << 'SCRIPT'
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
SCRIPT
chmod +x /Users/schmidt/Documents/git2/sessionsense-ai/poc/v2-badge-title.sh
```

- [ ] **Step 2: Smoke test v2 in iTerm2**

```bash
source /Users/schmidt/Documents/git2/sessionsense-ai/poc/v2-badge-title.sh

label "🧠 brainstorming sessionsense"
# Expected: blue tab, badge shows text, tab title updates

label "🔥 debugging something"
# Expected: red tab color

label "🚀 deploying to prod"
# Expected: green tab color

label --clear
# Expected: badge gone, tab color reset, title blank
```

- [ ] **Step 3: Commit**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add poc/v2-badge-title.sh
git commit -m "feat: POC v2 badge + title + tab color"
```

---

## Task 4: POC v3 — full (badge + title + color + time hint + TTY persistence)

**Files:**
- Create: `poc/v3-full.sh`

Adds TTY-keyed persistence (label survives shell reload) and optional time hint showing how long the label has been set.

- [ ] **Step 1: Write v3-full.sh**

```bash
cat > /Users/schmidt/Documents/git2/sessionsense-ai/poc/v3-full.sh << 'SCRIPT'
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
SCRIPT
chmod +x /Users/schmidt/Documents/git2/sessionsense-ai/poc/v3-full.sh
```

- [ ] **Step 2: Smoke test v3 in iTerm2**

```bash
source /Users/schmidt/Documents/git2/sessionsense-ai/poc/v3-full.sh

label "🧠 building sessionsense POC v3"
# Expected: badge + blue tab + title set

# Wait a minute, then press Enter — time hint should update
# Expected: badge shows "🧠 building sessionsense POC v3 · 1m"

# Open a NEW shell tab in the same window and run:
source /Users/schmidt/Documents/git2/sessionsense-ai/poc/v3-full.sh
# Expected: label restores automatically from persistence file

label --clear
# Expected: badge gone, color reset, title blank, persistence file removed
```

- [ ] **Step 3: Commit**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add poc/v3-full.sh
git commit -m "feat: POC v3 full — badge + title + color + time hint + persistence"
```

---

## Task 5: Core label.sh — config loading + environment detection

**Files:**
- Create: `label.sh`
- Create: `config.default`

The production script reads a user config file and gracefully handles missing values with defaults.

- [ ] **Step 1: Write config.default**

```bash
cat > /Users/schmidt/Documents/git2/sessionsense-ai/config.default << 'EOF'
# SessionSense AI — Default Configuration
# Copy to ~/.sessionsense/config to customize.
# All values shown are the defaults.

# ── Display modules ──────────────────────────────────────────────────────────
BADGE=true              # iTerm2 badge overlay inside viewport
TAB_TITLE=true          # Tab and window title
TAB_COLOR=true          # Auto-color tab by emoji keyword (iTerm2 only)

# ── Context modules (opt-in) ─────────────────────────────────────────────────
TIME_HINT=false         # Append elapsed time to label (e.g. "· 12m")
GIT_CONTEXT=false       # Append current git branch (e.g. "· main-ams")

# ── Behavior ─────────────────────────────────────────────────────────────────
RESTORE_ON_INIT=true    # Restore label when opening new shell in same window
EOF
```

- [ ] **Step 2: Write label.sh — skeleton with config loading**

```bash
cat > /Users/schmidt/Documents/git2/sessionsense-ai/label.sh << 'SCRIPT'
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

SCRIPT
```

- [ ] **Step 3: Commit skeleton**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add label.sh config.default
git commit -m "feat: label.sh skeleton with config loading and environment detection"
```

---

## Task 6: Core label.sh — display functions

**Files:**
- Modify: `label.sh` (append display functions)

- [ ] **Step 1: Append display functions to label.sh**

```bash
cat >> /Users/schmidt/Documents/git2/sessionsense-ai/label.sh << 'SCRIPT'

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

SCRIPT
```

- [ ] **Step 2: Commit**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add label.sh
git commit -m "feat: label.sh display functions — badge, title, color, hints"
```

---

## Task 7: Core label.sh — persistence + PROMPT_COMMAND hook + public API

**Files:**
- Modify: `label.sh` (append persistence and public `label` function)

- [ ] **Step 1: Append persistence, hook, and label() to label.sh**

```bash
cat >> /Users/schmidt/Documents/git2/sessionsense-ai/label.sh << 'SCRIPT'

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

SCRIPT
```

- [ ] **Step 2: Smoke test the full label.sh**

```bash
source /Users/schmidt/Documents/git2/sessionsense-ai/label.sh

# Test set
label "🧠 testing full label.sh"
# Expected: badge (iTerm2) + blue tab + title set + "SessionSense: labeled →" message

# Test status
label --status
# Expected: "SessionSense: 🧠 testing full label.sh"

# Test clear
label --clear
# Expected: badge cleared, tab color reset, title blank

# Test restore — close and reopen a shell IN THE SAME window (same TTY).
# In iTerm2: Cmd+W to close tab, then re-open with Cmd+T won't work (new TTY).
# Instead: run `exec bash` or `exec zsh` to reload the shell in-place.
exec bash  # or: exec zsh
source /Users/schmidt/Documents/git2/sessionsense-ai/poc/v3-full.sh
# Expected: label restores because TTY is unchanged

# Test no-args help
label
# Expected: usage printed
```

- [ ] **Step 3: Commit**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add label.sh
git commit -m "feat: label.sh persistence, PROMPT_COMMAND hook, public label() API"
```

---

## Task 8: install.sh

**Files:**
- Create: `install.sh`

One-command installer. Must work when piped from curl. Writes config, sources label.sh, detects shell.

- [ ] **Step 1: Write install.sh**

```bash
cat > /Users/schmidt/Documents/git2/sessionsense-ai/install.sh << 'SCRIPT'
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
SCRIPT
chmod +x /Users/schmidt/Documents/git2/sessionsense-ai/install.sh
```

- [ ] **Step 2: Smoke test install.sh locally (dry run)**

```bash
# Simulate what curl | bash does by running directly
# (Don't use your real RC file — just check the output)
bash /Users/schmidt/Documents/git2/sessionsense-ai/install.sh
```

Expected: prints green messages, label.sh downloaded, source line added to `.bash_profile` or `.zshrc`, `label` command available immediately.

Note: The `YOUR_USERNAME` placeholder must be replaced before publishing to GitHub.

- [ ] **Step 3: Commit**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add install.sh
git commit -m "feat: one-command installer with shell detection"
```

---

## Task 9: README.md

**Files:**
- Create: `README.md`

Optimized for non-technical users and SEO. Lead with the problem, not the solution.

- [ ] **Step 1: Write README.md**

```bash
cat > /Users/schmidt/Documents/git2/sessionsense-ai/README.md << 'EOF'
# SessionSense AI

**Terminal session labeling for AI-assisted development.**
Know what every terminal is doing at a glance — Claude Code, Cursor, Gemini CLI, and beyond.

---

## The Problem

You're running 5+ terminals at once. You're context-switching constantly between Claude sessions, deployments, and debugging. 30 seconds after switching windows, you've forgotten what that terminal was for.

## The Solution

One command stamps a human-readable label on your terminal:

```bash
label "🧠 building sessionsense-ai"
label "🔥 debugging helix-admin deploy"
label "🚀 deploying gov-stage"
```

Your tab title updates instantly. In iTerm2, a badge overlays the viewport and the tab turns color — so you always know where you are.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/sessionsense-ai/main/install.sh | bash
```

That's it. Open a new terminal tab and you're ready.

**Requirements:** bash or zsh. No brew, npm, or Python needed.

---

## Usage

```bash
label "🧠 planning new feature"    # Set label
label --clear                       # Clear label
label --status                      # Show current label
```

### Emoji color codes (iTerm2)

| Emoji | Tab color | Use for |
|-------|-----------|---------|
| 🧠 | Blue | Brainstorming, planning |
| 🔥 | Red | Debugging, incidents |
| 🚀 | Green | Deploys, shipping |
| 🔧 | Orange | Infra, config |
| 📋 | Purple | Reviews, docs |

---

## Terminal Support

| Feature | iTerm2 | Cursor | Terminal.app | Any xterm |
|---------|--------|--------|--------------|-----------|
| Tab title | ✅ | ✅ | ✅ | ✅ |
| Badge overlay | ✅ | ❌ | ❌ | ❌ |
| Tab color | ✅ | ❌ | ❌ | ❌ |
| Label persistence | ✅ | ✅ | ✅ | ✅ |

---

## Configuration

Edit `~/.sessionsense/config` to customize:

```bash
BADGE=true           # iTerm2 badge overlay
TAB_TITLE=true       # Tab and window title
TAB_COLOR=true       # Auto-color tab by emoji (iTerm2)
TIME_HINT=false      # Show elapsed time: "🧠 planning · 12m"
GIT_CONTEXT=false    # Show git branch: "🧠 planning · main-ams"
RESTORE_ON_INIT=true # Restore label when opening new shell in same window
```

---

## Manual Install (fish, nushell, or no curl)

1. Download `label.sh` and place it anywhere (e.g. `~/.sessionsense/label.sh`)
2. Add to your shell config: `source ~/.sessionsense/label.sh`
3. Reload your shell

---

## License

MIT
EOF
```

- [ ] **Step 2: Commit**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git add README.md
git commit -m "docs: README with install, usage, compatibility table"
```

---

## Task 10: Final integration smoke test

No new files. Verify the complete system works end-to-end.

- [ ] **Step 1: Verify repo structure**

```bash
ls /Users/schmidt/Documents/git2/sessionsense-ai/
# Expected:
# .gitignore  README.md  config.default  install.sh  label.sh  poc/  docs/
```

- [ ] **Step 2: Source and test all label() behaviors**

```bash
source /Users/schmidt/Documents/git2/sessionsense-ai/label.sh

label                              # → usage printed
label "🧠 integration test"       # → badge + blue tab + title
label --status                     # → "SessionSense: 🧠 integration test"
label "🔥 switching context"      # → badge updates + red tab
label --clear                      # → everything cleared
label --status                     # → "SessionSense: no label set"
```

- [ ] **Step 3: Test persistence across shell reload**

```bash
label "🚀 persisting across reload"
# Open new terminal tab (same window)
source /Users/schmidt/Documents/git2/sessionsense-ai/label.sh
label --status
# Expected: "SessionSense: 🚀 persisting across reload"
```

- [ ] **Step 4: Test on non-iTerm2 (Cursor terminal)**

Open Cursor's integrated terminal and run:
```bash
source /Users/schmidt/Documents/git2/sessionsense-ai/label.sh
label "🧠 cursor test"
# Expected: tab title updates, no badge/color (no errors)
```

- [ ] **Step 5: Final commit and tag**

```bash
cd /Users/schmidt/Documents/git2/sessionsense-ai
git tag -a v0.1.0 -m "SessionSense AI v0.1.0 — POC complete"
```

---

## Pre-publish checklist

Before pushing to GitHub:
- [ ] Replace `YOUR_USERNAME` in `install.sh` and `README.md` with actual GitHub username
- [ ] Push repo and verify raw URLs resolve correctly
- [ ] Test the curl one-liner on a fresh shell
