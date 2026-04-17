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

### State / Resume System

- A flat text file is genuinely the right tool here — no JSON, no database, just `grep` to check if a key exists
- `grep -qx "key" ~/.devkit_state` checks for an exact line match — clean and fast
- Write the state key immediately after a step succeeds, not at the end of the script

### Cross-Platform

- macOS and Linux look similar but aren't — `sed -i` behaves differently (needs `''` arg on mac)
- Always test on both, don't assume bash is bash
- PowerShell on Windows is a completely different world — keep it in its own files, don't try to share logic

### General

- Zero-dependency constraint is a forcing function for good decisions — if you can't use a library, you learn the primitive
- Ship the simplest thing that works first, then layer on top

---

## Format

Each entry = something that tripped me up, surprised me, or clicked during this build.
Updated as the project progresses. 🔥
