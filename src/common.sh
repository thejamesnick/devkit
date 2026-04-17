
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

info()    { printf "${CYAN}  →${RESET} %s\n" "$1"; }
success() { printf "${GREEN}  ✓${RESET} %s\n" "$1"; }
warn()    { printf "${YELLOW}  ⚠${RESET} %s\n" "$1"; }
error()   { printf "${RED}  ✗${RESET} %s\n" "$1"; }
header()  { printf "\n${BOLD}${BLUE}▶ %s${RESET}\n" "$1"; }
ask()     { printf "${YELLOW}  ?${RESET} %s " "$1"; }

# ── State file ─────────────────────────────────────────────────────────────
STATE_FILE="$HOME/.devkit_state"

step_done() {
  grep -qx "$1" "$STATE_FILE" 2>/dev/null
}

mark_done() {
  echo "$1" >> "$STATE_FILE"
}

reset_state() {
  rm -f "$STATE_FILE"
  success "State cleared — starting fresh"
}

# ── Safe curl with retries ──────────────────────────────────────────────────
safe_curl() {
  local url="$1"
  local out="$2"
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
  local rc
  rc=$(get_rc_file)
  local marker="$1"
  local block="$2"
  if ! grep -q "$marker" "$rc" 2>/dev/null; then
    printf "\n%s\n" "$block" >> "$rc"
    success "Patched $rc"
  else
    info "$(basename "$rc") already patched — skipping"
  fi
}
