# devkit

> HACK #2 — thejamesnick HACK Series

Zero-dependency dev environment setup tool. Works on a completely fresh machine — no Node, no Python, nothing required to run it. Just a terminal.

One command detects your OS, asks what kind of dev you are, and installs + configures everything. If it gets interrupted, just run it again — it picks up where it left off.

---

## Quick Start

### macOS / Linux
```bash
curl -fsSL https://raw.githubusercontent.com/thejamesnick/devkit/main/scripts/install.sh | bash
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/thejamesnick/devkit/main/scripts/install.ps1 | iex
```

---

## What It Does

Walks you through a simple setup flow:

1. Detects your OS
2. Asks your name
3. Installs a package manager
4. Installs core tools (git, gh, nvm → node, pyenv → python, yarn, pnpm, curl)
5. Asks what kind of dev you are and installs the right stack
6. Optionally sets up GitHub auth, SSH key, and VS Code
7. Optionally installs AI coding assistants (Claude Code, Codex CLI)
8. Prints a summary of everything installed and what to do next

---

## Dev Types

| # | Type | Extra tools |
|---|------|-------------|
| 1 | Web / Frontend | Core covers it |
| 2 | Backend / APIs | docker, docker-compose |
| 3 | Mobile | java, Xcode CLI (mac), Android Studio instructions |
| 4 | Data / ML / AI | jupyter, numpy, pandas, scikit-learn, optional torch + openai/langchain |
| 5 | DevOps / Cloud | docker, kubectl, cloud CLI of choice (AWS / GCP / Azure) |
| 6 | General | docker |

After your dev type, everyone is optionally asked about **AI coding assistants**:
- **Claude Code** (`claude`) — Anthropic's terminal-native AI pair programmer
- **OpenAI Codex CLI** (`codex`) — OpenAI's agentic coding tool

Both are npm globals, installed in about 30 seconds, and work inside any project folder.

---

## Resume / Retry

State is tracked in `~/.devkit_state` (or `$env:USERPROFILE\.devkit_state` on Windows). Each completed step is written there — re-running the script skips anything already done.

To start fresh:
```bash
bash scripts/install.sh --reset
```

---

## Safety

- Never runs as root
- Never stores or transmits user data
- All installs from official sources only
- Prints every action before doing it — no silent installs
- Shows a progress bar on file downloads so you always know something is happening
- Safe to run multiple times

---

## File Structure

```
devkit/
├── scripts/
│   ├── install.sh        # macOS + Linux entry point
│   └── install.ps1       # Windows entry point
├── src/
│   ├── mac.sh            # macOS-specific installs
│   ├── linux.sh          # Linux-specific installs
│   ├── common.sh         # Shared bash helpers + prompts
│   └── common.ps1        # Shared PowerShell helpers + prompts
├── SPEC.md               # Full spec
├── STACK.md              # Stack decisions
├── README.md             # This file
├── HACKLEARN.md          # Learnings log
└── TODO.txt              # Task tracker
```

---

## Phase

**Phase 1 complete** — shell scripts for macOS, Linux, and Windows. All steps implemented, all platforms tested. 🔥

**Phase 2 ideas** — dotfiles management, team profiles, web UI, plugin system, cloud sync.
