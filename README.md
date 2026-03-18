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
