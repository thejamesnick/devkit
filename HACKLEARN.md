# HACKLEARN — devkit

> What I learned building this. Raw notes, updated as we go.

---

## HACK #2 — devkit

### Shell Scripting

- Heredocs (`<< 'EOF'`) are the cleanest way to write multiline strings in bash without escaping issues
- Always quote the heredoc delimiter (`'EOF'` not `EOF`) to prevent variable expansion inside the block
- `$SHELL` gives you the current shell path — use it to detect bash vs zsh for rc file patching
- ANSI escape codes work in bash but need `echo -e` or `printf` to render — `printf` is more portable
- `read -p` doesn't work in zsh the same way — use `printf` then `read` separately for cross-shell compatibility
- Always use `--retry 3 --retry-delay 5` on curl calls — network drops are real, especially on fresh machines
- `curl -s` silences ALL output, including progress — use `--progress-bar` for file downloads so users know something is happening; pipe-to-bash calls must stay silent because stdout IS the script
- `&>/dev/null` already redirects both stdout and stderr — `&>/dev/null 2>&1` is redundant
- Avoid `cd` inside functions — it changes directory for the whole process and `cd -` won't run if the install fails. Use absolute paths with `-d` flags on `unzip` instead
- Always clean up temp files after installs — `/tmp/` is not automatically cleared between script runs

### State / Resume System

- A flat text file is genuinely the right tool here — no JSON, no database, just `grep` to check if a key exists
- `grep -qx "key" ~/.devkit_state` checks for an exact line match — clean and fast
- Write the state key immediately after a step succeeds, not at the end of the script
- Store data values (not just completion flags) in the state file using `key=value` lines — lets you resume without re-asking questions
- Sub-steps (e.g. `core_git`, `core_nvm`) inside a bigger step (e.g. `core_tools`) give you fine-grained resume without outer step locks

### Cross-Platform

- macOS and Linux look similar but aren't — `sed -i` behaves differently (needs `''` arg on mac)
- Always test on both, don't assume bash is bash
- PowerShell on Windows is a completely different world — keep it in its own files, don't try to share logic
- dnf's GitHub CLI setup used to run `dnf install -y gh` twice — once in the fallback branch and unconditionally after. Always trace every code path carefully when conditional logic has side effects
- GitHub CLI needs a custom repo setup on both apt and dnf — it's not in the default repos

### pyenv on Linux

- pyenv requires a long list of build dependencies before it can compile Python — skip them and `pyenv install` will fail silently or with cryptic errors
- The dependency list differs between apt (Ubuntu/Debian) and dnf (Fedora/RHEL) — test both
- Install deps with `|| true` so a missing optional package doesn't abort the whole script

### npm Globals as AI Tools

- `@anthropic-ai/claude-code` and `@openai/codex` are both npm globals — same install command on every platform, no platform-specific logic needed
- Make optional extras warn-on-fail rather than exit — a failed AI tool install should never block the rest of setup
- Track each AI tool as its own state key so they can be retried independently

### General

- Zero-dependency constraint is a forcing function for good decisions — if you can't use a library, you learn the primitive
- Ship the simplest thing that works first, then layer on top
- Idempotency is free if you track state — always check before installing, never assume a clean slate

---

## Format

Each entry = something that tripped me up, surprised me, or clicked during this build.
Updated as the project progresses. 🔥
