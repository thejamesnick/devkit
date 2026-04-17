#!/usr/bin/env bash
# install.sh — devkit macOS + Linux entry point
# Usage: bash scripts/install.sh [--reset]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load shared helpers ─────────────────────────────────────────────────────
# shellcheck source=../src/common.sh
source "$SCRIPT_DIR/../src/common.sh"

# ── --reset flag ────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--reset" ]]; then
  reset_state
fi

# ── Never run as root ───────────────────────────────────────────────────────
if [[ "$(id -u)" -eq 0 ]]; then
  error "devkit should not be run as root. Please run as a normal user."
  exit 1
fi

# ── OS detection ────────────────────────────────────────────────────────────
if ! step_done "os_detect"; then
  OS=""
  case "$(uname -s)" in
    Darwin)
      OS="mac"
      ;;
    Linux)
      OS="linux"
      if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO="${ID:-unknown}"
      else
        DISTRO="unknown"
      fi
      case "${DISTRO:-}" in
        ubuntu|debian|pop|linuxmint|raspbian)
          ;;
        fedora|rhel|centos|rocky|alma|ol)
          ;;
        *)
          error "Unsupported Linux distro: ${DISTRO:-unknown}"
          error "devkit supports: Ubuntu, Debian, Fedora, RHEL, CentOS, Rocky, AlmaLinux."
          exit 1
          ;;
      esac
      ;;
    *)
      error "Unsupported OS. devkit supports macOS and Linux."
      error "For Windows: irm https://raw.githubusercontent.com/thejamesnick/devkit/main/scripts/install.ps1 | iex"
      exit 1
      ;;
  esac
  echo "devkit_os=$OS" >> "$STATE_FILE"
  mark_done "os_detect"
fi

# Read OS from state on resume
OS="${OS:-$(grep "^devkit_os=" "$STATE_FILE" 2>/dev/null | cut -d= -f2)}"

# ── Load platform-specific functions ────────────────────────────────────────
if [[ "$OS" == "mac" ]]; then
  # shellcheck source=../src/mac.sh
  source "$SCRIPT_DIR/../src/mac.sh"
elif [[ "$OS" == "linux" ]]; then
  # shellcheck source=../src/linux.sh
  source "$SCRIPT_DIR/../src/linux.sh"
fi

# ── Step: greet ─────────────────────────────────────────────────────────────
if ! step_done "greet"; then
  printf '\n%s\n\n' "${BOLD}${GREEN}  Hey! Let's set up your machine for development.${RESET}"
  mark_done "greet"
fi

# ── Step: get_name ──────────────────────────────────────────────────────────
if ! step_done "get_name"; then
  ask "What is your name?"
  read -r DEVKIT_NAME
  success "Hey ${DEVKIT_NAME}! Let's go"
  mark_done "get_name"
fi

# ── Step: pkg_manager ───────────────────────────────────────────────────────
if ! step_done "pkg_manager"; then
  header "Package manager"
  install_pkg_manager
  mark_done "pkg_manager"
fi

# ── Step: core_tools ────────────────────────────────────────────────────────
install_core_tools

# ── Step: shell_rc_patch ────────────────────────────────────────────────────
if ! step_done "shell_rc_patch"; then
  header "Shell config"
  patch_shell_rc
  mark_done "shell_rc_patch"
fi

# ── Step: dev_type ──────────────────────────────────────────────────────────
DEV_TYPE=""
if ! step_done "dev_type"; then
  header "What kind of dev work do you do?"
  printf '\n'
  printf '  %s Web / Frontend\n'                 "${CYAN}[ 1 ]${RESET}"
  printf '  %s Backend / APIs\n'                 "${CYAN}[ 2 ]${RESET}"
  printf '  %s Mobile (React Native / Flutter)\n' "${CYAN}[ 3 ]${RESET}"
  printf '  %s Data / ML / AI\n'                 "${CYAN}[ 4 ]${RESET}"
  printf '  %s DevOps / Cloud\n'                 "${CYAN}[ 5 ]${RESET}"
  printf '  %s General / Not sure yet\n'         "${CYAN}[ 6 ]${RESET}"
  printf '\n'
  ask "Enter a number [1-6]:"
  read -r _choice
  case "$_choice" in
    1) DEV_TYPE="web" ;;
    2) DEV_TYPE="backend" ;;
    3) DEV_TYPE="mobile" ;;
    4) DEV_TYPE="data" ;;
    5) DEV_TYPE="devops" ;;
    6) DEV_TYPE="general" ;;
    *)
      warn "Invalid choice — defaulting to General."
      DEV_TYPE="general"
      ;;
  esac
  echo "dev_type_value=$DEV_TYPE" >> "$STATE_FILE"
  mark_done "dev_type"
fi

# Resume: read dev_type from state file
if [ -z "$DEV_TYPE" ]; then
  DEV_TYPE="$(grep "^dev_type_value=" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || true)"
  DEV_TYPE="${DEV_TYPE:-general}"
fi

# ── Step: stack_tools ───────────────────────────────────────────────────────
if ! step_done "stack_tools"; then
  header "Stack tools"
  info "Dev type: $DEV_TYPE"
  install_stack_tools "$DEV_TYPE"
  mark_done "stack_tools"
fi

# ── Step: github ────────────────────────────────────────────────────────────
if ! step_done "github"; then
  header "GitHub"
  ask "Do you have a GitHub account? (y/N):"
  read -r _gh_ans
  if [[ "$_gh_ans" =~ ^[Yy]$ ]]; then
    info "Running gh auth login..."
    gh auth login
  else
    info "Skipping — gh is installed and ready for when you need it."
  fi
  mark_done "github"
fi

# ── Step: ssh_key ───────────────────────────────────────────────────────────
if ! step_done "ssh_key"; then
  header "SSH key"
  ask "Want to generate an SSH key? (y/N):"
  read -r _ssh_ans
  if [[ "$_ssh_ans" =~ ^[Yy]$ ]]; then
    ask "Enter your email address for the SSH key:"
    read -r _ssh_email
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
      ssh-keygen -t ed25519 -C "$_ssh_email" -f "$HOME/.ssh/id_ed25519" -N ""
      success "SSH key generated at ~/.ssh/id_ed25519"
    else
      success "SSH key already exists at ~/.ssh/id_ed25519"
    fi
    info "Public key (add to GitHub Settings > SSH keys):"
    printf '\n'
    cat "$HOME/.ssh/id_ed25519.pub"
    printf '\n'
  else
    info "Skipping SSH key generation."
  fi
  mark_done "ssh_key"
fi

# ── Step: vscode ────────────────────────────────────────────────────────────
if ! step_done "vscode"; then
  header "VS Code (optional)"
  ask "Want to install VS Code? (y/N):"
  read -r _code_ans
  if [[ "$_code_ans" =~ ^[Yy]$ ]]; then
    install_vscode
  else
    info "Skipping VS Code — download any time from https://code.visualstudio.com"
  fi
  mark_done "vscode"
fi

# ── Step: ai_coding_tools ───────────────────────────────────────────────────
if ! step_done "ai_coding_tools"; then
  install_ai_coding_tools
  mark_done "ai_coding_tools"
fi

# ── Step: done ──────────────────────────────────────────────────────────────
if ! step_done "done"; then
  print_summary
  mark_done "done"
fi
