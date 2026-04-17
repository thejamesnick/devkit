> HACK #2 — thejamesnick HACK Series
> Phase 1: Shell scripts. No Node required. Ship fast. 🔥

---

## 🎯 What We Are Building

A zero-dependency dev environment setup tool that works on a completely fresh machine.
One command — it detects your OS, asks what kind of dev you are, and installs + configures everything.
No Node, no Python, no nothing required to run it. Just a terminal.

If the install is interrupted (network drop, timeout, Ctrl+C) — just run it again. It picks up where it left off.

---

## 🛠️ Stack

| Layer | Choice | Why |
|---|---|---|
| macOS / Linux | Bash (`install.sh`) | Built into every Unix system, zero deps |
| Windows | PowerShell (`install.ps1`) | Built into every Windows machine |
| Prompts | Native shell `read` / PS `Read-Host` | No external libs needed |
| Output | ANSI escape codes / PS colors | Pretty output, zero deps |
| Package managers | Homebrew (mac), apt/dnf (linux), winget/choco (win) | Native to each OS |

**No Node. No Python. No install required to run the installer. That is the whole point.**

---

## 📁 File Structure

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
├── SPEC.md
├── STACK.md
├── README.md
├── HACKLEARN.md
└── TODO.txt
```

State file location: `~/.devkit_state` (bash) / `$env:USERPROFILE\.devkit_state` (PowerShell)

---

## ⚙️ How To Run (fresh machine, zero installs needed)

### macOS / Linux
```bash
curl -fsSL https://raw.githubusercontent.com/thejamesnick/devkit/main/scripts/install.sh | bash
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/thejamesnick/devkit/main/scripts/install.ps1 | iex
```

---

## 🔄 Flow

Each step has a named key. On completion, that key is written to `~/.devkit_state`. On re-run, completed steps are skipped automatically.

```
1.  [os_detect]          Detect OS (macOS / Ubuntu / Debian / Fedora / Windows)
                          → Unsupported distro: print clear message + exit cleanly
2.  [greet]              "Hey! Let's set up your machine for development."
3.  [get_name]           Ask: What's your name?
4.  [pkg_manager]        Install package manager (Homebrew / apt / winget)
                          → Everything else depends on this — retry up to 3x on failure
5.  [core_tools]         Install core tools (always — see below)
                          → Each tool is its own sub-step (e.g. core_git, core_nvm, core_pyenv)
                          → Shell rc patching for nvm + pyenv happens here
6.  [dev_type]           Ask: What kind of dev work do you do?
                          [ 1 ] Web / Frontend
                          [ 2 ] Backend / APIs
                          [ 3 ] Mobile (React Native / Flutter)
                          [ 4 ] Data / ML / AI  ⚡
                          [ 5 ] DevOps / Cloud
                          [ 6 ] General / Not sure yet
7.  [stack_tools]        Install stack tools based on choice
8.  [github]             Ask: Do you have a GitHub account? (y/N)
                          → yes: run gh auth login
                          → no:  skip, gh is installed and ready for later
9.  [ssh_key]            Ask: Want to generate an SSH key? (y/N)
10. [vscode]             Ask: Want to install VS Code? (y/N)  ← optional, default NO
11. [ai_coding_tools]    Ask: Install Claude Code? (y/N) — then: Install Codex CLI? (y/N)
                          → Both are optional and prompted independently
                          → Installed as npm globals (requires node from step 5)
                          → Failures warn rather than exit — these are extras, not blockers
12. [done]               Print summary — what was installed, next steps
```

---

## 📦 What Gets Installed

### Always (core — no exceptions)
- Package manager (Homebrew on mac, apt/dnf on linux, winget on windows)
- `git` — version control
- `gh` — GitHub CLI (auth + clone without browser hassle)
- `curl` / `wget`
- `nvm` — Node version manager (then installs latest LTS Node + npm via nvm)
- `yarn` + `pnpm` — both, projects use different ones
- `pyenv` — Python version manager (then installs latest stable Python via pyenv)
- `pip` — comes with pyenv Python

### Web / Frontend
- Nothing extra — core covers it (nvm + node + yarn + pnpm)

### Backend / APIs
- `docker` + `docker-compose`

### Mobile
- `java` (via package manager)
- Xcode CLI tools (mac only — `xcode-select --install`)
- Android Studio install link + instructions printed at end

### Data / ML / AI ⚡
- `jupyter` (via pip)
- `numpy`, `pandas`, `matplotlib` (via pip)
- `scikit-learn` (via pip)
- Ask: Deep learning? (y/N) → installs `torch` (CPU build by default)
- Ask: OpenAI / LLM tools? (y/N) → installs `openai`, `langchain`
- `virtualenv` + `ipykernel` for clean notebook environments

### DevOps / Cloud
- `docker` + `docker-compose`
- `kubectl`
- Ask: Which cloud? AWS / GCP / Azure / Skip → installs matching CLI

### General
- `docker`
- Nothing else — core already covers node + python

### AI Coding Assistants (optional — everyone gets asked)
- `@anthropic-ai/claude-code` (via npm) — run `claude` in any project
- `@openai/codex` (via npm) — run `codex` in any project
- Each is prompted independently — install one, both, or neither
- Failures warn rather than exit — these are extras, not blockers

---

## 🔧 VS Code — Optional, Asked Last

VS Code is NOT installed by default. It is the last question asked.

```
Want to install VS Code? (y/N):
```

Default is N. Anyone can download VS Code themselves — but if they say yes,
devkit installs it AND sets up the shell command `code` so it works from terminal immediately.

---

## � Resume / Retry System

This is a first-class requirement, not an afterthought.

### State File
- Location: `~/.devkit_state` (bash) / `$env:USERPROFILE\.devkit_state` (PowerShell)
- Format: one completed step key per line (e.g. `core_git`, `pkg_manager`, `core_nvm`)
- Written immediately after each step succeeds
- On re-run: script reads the state file and skips any step already listed

### Network Failures
- All `curl` / `wget` calls use `--retry 3 --retry-delay 5` — 3 attempts, 5s between each
- If all retries fail: print a clear message ("Failed to download X — check your connection and run the script again"), mark the step as failed (not done), and exit cleanly
- On re-run: failed/incomplete steps run again from scratch, completed steps are skipped

### Shell RC Patching (nvm + pyenv)
- After installing nvm and pyenv, the script patches the user's shell rc file
- Detects active shell: checks `$SHELL` — handles both `bash` (`.bashrc`) and `zsh` (`.zshrc`)
- Checks if the init lines already exist before appending — never duplicates
- This is its own tracked step (`shell_rc_patch`) so it can be retried independently

### Cleanup
- `devkit reset` (or re-running with `--reset` flag) deletes `~/.devkit_state` and starts fresh
- State file is never deleted automatically — user controls it

---

## �🔒 Safety Rules

- Never run as root (warn + exit if sudo is detected on mac/linux)
- Never store or transmit any user data — state file is local only
- All installs from official sources only (Homebrew, apt, winget, official installers, pip)
- Idempotent — safe to run multiple times, skips already-completed steps (via state file)
- Prints every action before doing it (no silent installs)
- Version managers (nvm, pyenv) used instead of direct installs — no version lock-in
- Unsupported OS or distro: print a clear message and exit cleanly, never crash silently
- Android Studio (Mobile track): not auto-installed — print the download link + setup instructions at the end

---

## ✅ Phase 1 Scope

- [x] macOS install script
- [x] Linux install script (Ubuntu/Debian + Fedora/RHEL)
- [x] Windows PowerShell script
- [x] OS detection (with clean exit on unsupported distro)
- [x] Package manager install (first step, always — retry 3x on network failure)
- [x] Core tools: git, gh, curl, nvm→node, yarn, pnpm, pyenv→python, pip
- [x] Shell rc patching for nvm + pyenv (bash + zsh, no duplicates)
- [x] Dev type selection (6 options)
- [x] Stack-specific tools install
- [x] GitHub account check → gh auth login or skip
- [x] SSH key generation (optional)
- [x] VS Code install (optional, last, default NO)
- [x] AI coding assistant install — Claude Code + Codex CLI (optional, prompted individually)
- [x] Pretty coloured output throughout
- [x] Resume / retry system (state file, per-step tracking)
- [x] `--reset` flag to wipe state and start fresh
- [x] Download progress bar on file downloads
- [x] Summary at the end

## ❌ Out of Scope (Phase 1)

- No GUI
- No dotfiles management
- No cloud sync
- No team profiles
- No plugin system

These are Phase 2+ ideas. Ship Phase 1 first. 🔥