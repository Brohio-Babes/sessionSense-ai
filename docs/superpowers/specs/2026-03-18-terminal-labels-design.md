# SessionSense AI — Design Spec
**Date:** 2026-03-18
**Status:** Approved
**Repo:** `Documents/git2/sessionsense-ai`
**Audience:** Public — including non-technical Claude Code, Cursor, and Gemini CLI users

---

## Problem

When running 5+ terminal windows/tabs simultaneously and context-switching constantly, it is difficult to remember what each terminal session is for. The current directory and shell prompt give technical state, but not cognitive context — what conversation, task, or goal is this window serving right now?

---

## Goal

A lightweight, zero-dependency shell tool that lets users stamp a **human-readable context label** on each terminal window/tab so they can orient themselves instantly with a glance. Built for AI-assisted development workflows (Claude Code, Cursor, Gemini CLI, and beyond).

---

## User Experience

```bash
# Set label for this terminal
label "🧠 building sessionsense-ai"

# Update when context shifts
label "🔥 debugging helix-admin deploy"

# Clear label — removes stored label, resets tab title to shell default, clears badge
label --clear
```

The label appears in:
- **iTerm2 badge** — semi-transparent overlay inside the viewport (always visible)
- **Tab/window title** — visible in title bar and tab strip
- **Tab color** — auto-assigned by emoji/keyword for pre-attentive scanning

On a new shell in the same window, the label **restores automatically** from TTY-keyed persistence.

---

## Architecture

### Two-Layer Detection

```
label "🧠 building sessionsense-ai"
        │
        ▼
[ detect $TERM_PROGRAM ]
        │
   iTerm2? ──yes──► iTerm2 Layer
        │              ├─ Proprietary badge escape sequence
        │              ├─ Tab title (xterm + iTerm2)
        │              └─ Tab color (iTerm2 proprietary)
        │
        no
        │
        ▼
   Shell Fallback (Cursor, Terminal.app, etc.)
        └─ xterm tab title escape code only
```

### Persistence

Labels persist to `~/.sessionsense/<tty_id>` (keyed by TTY device, e.g. `s001`).
On shell init, the `PROMPT_COMMAND` hook reads the file and restores the label (controlled by `RESTORE_ON_INIT=true` in config — on by default).
Stale TTY files (from closed windows) are pruned on shell init by checking active TTY devices via `ls /dev/ttys*`.

### Module System

Config at `~/.sessionsense/config`:

```bash
BADGE=true              # Show iTerm2 badge
TAB_TITLE=true          # Set tab/window title
TAB_COLOR=true          # Auto-color tab by emoji keyword
TIME_HINT=false         # Append time since label was set
GIT_CONTEXT=false       # Append current git branch (opt-in)
RESTORE_ON_INIT=true    # Restore label when opening new shell in same window
```

All modules default to sane values. Non-iTerm2 environments automatically ignore iTerm2-specific modules.

### Tab Color Mapping (Psychology)

Emoji keyword → tab color, processed pre-attentively (~200ms recognition):

| Keyword | Color | Use case |
|---------|-------|----------|
| 🧠 | Blue | Brainstorming / planning |
| 🔥 | Red | Debugging / incident |
| 🚀 | Green | Deploy / ship |
| 🔧 | Orange | Infra / config |
| 📋 | Purple | Review / docs |
| (none) | Default | General |

---

## POC Variants

Three self-contained scripts to validate UX before building the full system:

| File | Purpose |
|------|---------|
| `poc/v1-title-only.sh` | Tab + window title only — minimal, max compatibility |
| `poc/v2-badge-title.sh` | Badge + tab title + tab color by emoji |
| `poc/v3-full.sh` | Badge + title + color + time hint + TTY persistence |

User tries each in a live terminal session and selects the winner before full implementation.

---

## Install Experience

Single command, non-technical friendly:

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/sessionsense-ai/main/install.sh | bash
```

Installer actions:
1. Creates `~/.sessionsense/` directory
2. Downloads `label.sh` into it
3. Writes default `config` with all options documented inline
4. Detects shell (bash/zsh) and appends `source` line to rc file
5. Prints friendly success message with first example command

No brew, npm, Python, or elevated permissions required.

---

## Terminal Compatibility

| Feature | iTerm2 | Cursor | Terminal.app | Any xterm |
|---------|--------|--------|--------------|-----------|
| Tab title | ✅ | ✅ | ✅ | ✅ |
| Badge overlay | ✅ | ❌ | ❌ | ❌ |
| Tab color | ✅ | ❌ | ❌ | ❌ |
| TTY persistence | ✅ | ✅ | ✅ | ✅ |

---

## Repo Structure

```
sessionsense-ai/
├── label.sh                  # Main script (source this)
├── install.sh                # One-command installer
├── config.default            # Default config with inline docs
├── poc/
│   ├── v1-title-only.sh
│   ├── v2-badge-title.sh
│   └── v3-full.sh
├── docs/
│   └── superpowers/specs/
│       └── 2026-03-18-terminal-labels-design.md
└── README.md
```

---

## Non-Goals (v1)

- No GUI / dashboard
- No tmux integration (future module)
- No automatic AI-based label suggestion
- No sync across machines
- No fish/nushell install support (manual `source` instructions in README)

---

## Success Criteria

- `label "text"` updates badge + tab visibly immediately (shell escape sequences are synchronous)
- Label survives shell reload in the same window when `RESTORE_ON_INIT=true`
- Install completes in under 30 seconds on a fresh machine
- Works without modification on bash and zsh
- iTerm2 features gracefully absent on other terminals (no errors, no broken output)

**Note:** Install URL `<user>` placeholder must be replaced with the GitHub username before publishing.
