#!/usr/bin/env bash
# common.sh — shared helpers, colours, state management

# ── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Each helper keeps user content in %s to avoid SC2059 warnings.
# The ANSI prefix/suffix are safe constants passed as arguments.
info()    { printf '%s %s\n'   "${CYAN}  →${RESET}"   "$1"; }
success() { printf '%s %s\n'   "${GREEN}  ✓${RESET}"  "$1"; }
warn()    { printf '%s %s\n'   "${YELLOW}  ⚠${RESET}" "$1"; }
error()   { printf '%s %s\n'   "${RED}  ✗${RESET}"    "$1"; }
header()  { printf '\n%s %s%s\n' "${BOLD}${BLUE}▶" "$1" "${RESET}"; }
ask()     { printf '%s %s '    "${YELLOW}  ?${RESET}"  "$1"; }

# ── State file ─────────────────────────────────────────────────────────────
STATE_FILE="$HOME/.devkit_state"

step_done() {
  grep -qx "$1" "$STATE_FILE" 2>/dev/null
}

mark_done() {
  # Only write if not already present (idempotent)
  if ! grep -qx "$1" "$STATE_FILE" 2>/dev/null; then
    echo "$1" >> "$STATE_FILE"
  fi
}

reset_state() {
  rm -f "$STATE_FILE"
  success "State cleared — starting fresh"
}

# ── Safe curl with retries ──────────────────────────────────────────────────
safe_curl() {
  local url="$1"
  local out="${2:-}"
  if [ -n "$out" ]; then
    curl -fsSL --retry 3 --retry-delay 5 "$url" -o "$out"
  else
    curl -fsSL --retry 3 --retry-delay 5 "$url"
  fi
}

# ── Command existence check ─────────────────────────────────────────────────
has() {
  command -v "$1" &>/dev/null
}

# ── Shell rc patching ───────────────────────────────────────────────────────
get_rc_file() {
  if [[ "$SHELL" == */zsh ]]; then
    echo "$HOME/.zshrc"
  else
    echo "$HOME/.bashrc"
  fi
}

patch_rc() {
  local marker="$1"
  local block="$2"
  local rc
  rc=$(get_rc_file)
  touch "$rc"
  if ! grep -q "$marker" "$rc" 2>/dev/null; then
    printf '\n%s\n' "$block" >> "$rc"
    success "Patched $(basename "$rc")"
  else
    info "$(basename "$rc") already patched — skipping"
  fi
}

# ── Installed tools tracker (populated by platform scripts) ────────────────
INSTALLED_TOOLS=()

# ── Summary ────────────────────────────────────────────────────────────────
print_summary() {
  local sep="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf '\n%s\n' "${BOLD}${GREEN}${sep}${RESET}"
  printf '%s\n'   "${BOLD}${GREEN}  🎉 devkit setup complete!${RESET}"
  printf '%s\n\n' "${BOLD}${GREEN}${sep}${RESET}"

  if [ "${#INSTALLED_TOOLS[@]}" -gt 0 ]; then
    printf '%s\n' "${CYAN}  Installed this run:${RESET}"
    for tool in "${INSTALLED_TOOLS[@]}"; do
      printf '    %s %s\n' "${GREEN}✓${RESET}" "$tool"
    done
    printf '\n'
  fi

  printf '%s\n' "${CYAN}  Next steps:${RESET}"
  printf '    → Restart your terminal (or source your shell rc) for all tools to load\n'
  printf '    → Run %s to authenticate with GitHub\n' "${BOLD}gh auth login${RESET}"
  printf '    → Run %s to activate Node.js\n' "${BOLD}nvm use --lts${RESET}"
  printf '\n%s ~/.devkit_state\n' "${CYAN}  State file:${RESET}"
  printf '  To reset and start fresh: %s\n\n' "${BOLD}bash scripts/install.sh --reset${RESET}"
}
