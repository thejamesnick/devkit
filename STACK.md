# devkit — Stack Decisions

> Why each tool was chosen. Every decision has a reason.

---

## Core Principle

**Zero dependencies to run the installer.** No Node, no Python, no package manager pre-installed.
The only requirement is a terminal. That constraint drives every decision below.

---

## Language Choice

| Platform | Language | Why |
|----------|----------|-----|
| macOS / Linux | Bash | Ships on every Unix system by default. No install needed. |
| Windows | PowerShell | Built into every modern Windows machine. No install needed. |

We are not using Node, Python, Ruby, or any scripting language that requires a runtime install.
The installer cannot depend on the thing it is trying to install.

---

## Package Managers

| OS | Package Manager | Why |
|----|----------------|-----|
| macOS | Homebrew | The de facto standard. Massive package coverage. |
| Ubuntu / Debian | apt | Built in. No choice needed. |
| Fedora / RHEL | dnf | Built in. No choice needed. |
| Windows | winget | Ships with Windows 10+. No install needed. Chocolatey as fallback. |

Homebrew is the only one that needs installing — handled as the first step on mac, with 3 retries.

---

## Version Managers (not direct installs)

| Tool | Manager | Why |
|------|---------|-----|
| Node | nvm | Avoids version lock-in. Devs switch Node versions constantly. Direct installs cause pain. |
| Python | pyenv | Same reason. Python 2 vs 3, project-specific versions — pyenv handles it cleanly. |

We never install Node or Python directly via a package manager.
Always via a version manager. This is intentional.

---

## Core Tools

| Tool | Why |
|------|-----|
| git | Non-negotiable. Every dev needs it. |
| gh (GitHub CLI) | Auth + clone without browser hassle. Saves time on first setup. |
| curl / wget | Required for downloads throughout the script. |
| yarn + pnpm | Both included — projects use different ones, no point picking sides. |
| pip | Comes free with pyenv Python. No extra install. |

---

## Prompts + Output

| Feature | Approach | Why |
|---------|----------|-----|
| User prompts | Native `read` (bash) / `Read-Host` (PS) | Zero deps. Built into the shell. |
| Coloured output | ANSI escape codes (bash) / Write-Host -ForegroundColor (PS) | Pretty output, still zero deps. |
| Progress / state | Flat text file (`~/.devkit_state`) | Simple, portable, no database needed. |

---

## Resume System

A flat text file at `~/.devkit_state` tracks completed steps (one key per line).
On re-run, the script reads this file and skips completed steps.

Chosen over alternatives because:
- No JSON parser needed (zero deps)
- Human readable — user can inspect or edit it
- Works identically on mac, linux, and windows

---

## What We Deliberately Did Not Use

| Rejected | Reason |
|----------|--------|
| Node / npm scripts | Requires Node — defeats the whole point |
| Python scripts | Requires Python — same problem |
| Ansible / Chef / Puppet | Way too heavy for a personal setup tool |
| Docker | Overkill, and not available on a fresh machine |
| GUI / Electron | Phase 2+ idea. Ship the shell version first. |
| dotfiles management | Out of scope for Phase 1 |
| Cloud sync / team profiles | Out of scope for Phase 1 |

---

## Phase 2+ Ideas (not now)

- Web UI / dashboard
- Dotfiles management
- Team profiles (share a devkit config with your team)
- Plugin system
- Cloud sync

Ship Phase 1 first. 🔥
