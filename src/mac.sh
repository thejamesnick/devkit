#!/usr/bin/env bash
# mac.sh — macOS-specific installs

# ── Package manager (Homebrew) ──────────────────────────────────────────────
install_pkg_manager() {
  if has brew; then
    success "Homebrew already installed"
    # Ensure brew is on PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    return 0
  fi

  info "Installing Homebrew..."
  local attempt=0
  while [ $attempt -lt 3 ]; do
    attempt=$((attempt + 1))
    info "Attempt $attempt of 3..."
    if /bin/bash -c "$(safe_curl 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh')"; then
      # Add to PATH immediately for Apple Silicon
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
      success "Homebrew installed"
      return 0
    fi
    if [ $attempt -lt 3 ]; then
      warn "Homebrew install failed. Retrying in 5s..."
      sleep 5
    fi
  done
  error "Failed to install Homebrew after 3 attempts. Check your connection and run the script again."
  exit 1
}

# ── Internal: brew install with state tracking ──────────────────────────────
_brew_install() {
  local pkg="$1"
  local label="${2:-$1}"
  local step_key="core_${label}"

  if step_done "$step_key"; then
    return 0
  fi

  if brew list --formula "$pkg" &>/dev/null 2>&1 || brew list --cask "$pkg" &>/dev/null 2>&1 || has "$label"; then
    success "$label already installed"
    mark_done "$step_key"
    return 0
  fi

  info "Installing $label..."
  if brew install "$pkg"; then
    success "$label installed"
    mark_done "$step_key"
    INSTALLED_TOOLS+=("$label")
  else
    error "Failed to install $label — check your connection and run the script again."
    exit 1
  fi
}

# ── Core tools ──────────────────────────────────────────────────────────────
install_core_tools() {
  header "Core tools"

  _brew_install git git
  _brew_install gh gh
  _brew_install curl curl
  _brew_install wget wget

  # nvm
  if ! step_done "core_nvm"; then
    if [ -d "$HOME/.nvm" ]; then
      success "nvm already installed"
    else
      info "Installing nvm..."
      if bash -c "$(safe_curl 'https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh')"; then
        success "nvm installed"
        INSTALLED_TOOLS+=("nvm")
      else
        error "Failed to install nvm — check your connection and run again."
        exit 1
      fi
    fi
    mark_done "core_nvm"
  fi

  # Load nvm for this session
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

  # Node LTS via nvm
  if ! step_done "core_node"; then
    if has node; then
      success "node already installed"
    else
      info "Installing Node.js LTS via nvm..."
      if nvm install --lts && nvm use --lts && nvm alias default 'lts/*'; then
        success "Node.js LTS installed"
        INSTALLED_TOOLS+=("node")
      else
        error "Failed to install Node.js via nvm — run the script again."
        exit 1
      fi
    fi
    mark_done "core_node"
  fi

  # yarn
  if ! step_done "core_yarn"; then
    if has yarn; then
      success "yarn already installed"
    else
      info "Installing yarn..."
      npm install -g yarn
      success "yarn installed"
      INSTALLED_TOOLS+=("yarn")
    fi
    mark_done "core_yarn"
  fi

  # pnpm
  if ! step_done "core_pnpm"; then
    if has pnpm; then
      success "pnpm already installed"
    else
      info "Installing pnpm..."
      npm install -g pnpm
      success "pnpm installed"
      INSTALLED_TOOLS+=("pnpm")
    fi
    mark_done "core_pnpm"
  fi

  # pyenv
  if ! step_done "core_pyenv"; then
    if has pyenv || [ -d "$HOME/.pyenv" ]; then
      success "pyenv already installed"
    else
      info "Installing pyenv..."
      if brew install pyenv; then
        success "pyenv installed"
        INSTALLED_TOOLS+=("pyenv")
      else
        error "Failed to install pyenv."
        exit 1
      fi
    fi
    mark_done "core_pyenv"
  fi

  # Load pyenv for this session
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  if has pyenv; then
    eval "$(pyenv init -)"
  fi

  # Python (latest stable via pyenv)
  if ! step_done "core_python"; then
    if pyenv versions --bare 2>/dev/null | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      success "python already managed by pyenv"
    else
      info "Installing latest stable Python via pyenv..."
      local py_version
      py_version=$(pyenv install --list 2>/dev/null | grep -E '^\s+[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
      pyenv install "$py_version"
      pyenv global "$py_version"
      success "Python $py_version installed"
      INSTALLED_TOOLS+=("python@$py_version")
    fi
    mark_done "core_python"
  fi
}

# ── Shell RC patching ────────────────────────────────────────────────────────
patch_shell_rc() {
  # shellcheck disable=SC2016  # single-quoted blocks intentional — expand at shell startup
  # nvm
  patch_rc "NVM_DIR" \
'# nvm — managed by devkit
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

  # pyenv
  # shellcheck disable=SC2016
  patch_rc "pyenv init" \
'# pyenv — managed by devkit
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"'

  # Homebrew (Apple Silicon)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    # shellcheck disable=SC2016
    patch_rc "homebrew shellenv" \
'# Homebrew (Apple Silicon) — managed by devkit
eval "$(/opt/homebrew/bin/brew shellenv)"'
  fi
}

# ── Stack tools ──────────────────────────────────────────────────────────────
install_stack_tools() {
  local dev_type="$1"
  case "$dev_type" in
    web)
      success "Web / Frontend — core tools already cover it (nvm, node, yarn, pnpm) ✓"
      ;;

    backend)
      _brew_install docker docker
      _brew_install docker-compose docker-compose
      ;;

    mobile)
      _brew_install openjdk java
      info "Installing Xcode Command Line Tools..."
      if ! xcode-select -p &>/dev/null; then
        xcode-select --install
        warn "Follow the Xcode CLI installer popup, then re-run devkit."
      else
        success "Xcode CLI tools already installed"
      fi
      warn "Android Studio must be installed manually."
      info "→ Download: https://developer.android.com/studio"
      ;;

    data)
      info "Installing data / ML / AI tools via pip..."
      pip install --upgrade pip
      pip install jupyter numpy pandas matplotlib scikit-learn virtualenv ipykernel
      success "Core data tools installed"
      INSTALLED_TOOLS+=("jupyter" "numpy" "pandas" "scikit-learn")

      ask "Install deep learning tools (torch CPU build)? (y/N):"
      read -r _dl_ans
      if [[ "$_dl_ans" =~ ^[Yy]$ ]]; then
        pip install torch --index-url https://download.pytorch.org/whl/cpu
        success "torch installed"
        INSTALLED_TOOLS+=("torch")
      fi

      ask "Install OpenAI / LLM tools (openai, langchain)? (y/N):"
      read -r _llm_ans
      if [[ "$_llm_ans" =~ ^[Yy]$ ]]; then
        pip install openai langchain
        success "openai + langchain installed"
        INSTALLED_TOOLS+=("openai" "langchain")
      fi
      ;;

    devops)
      _brew_install docker docker
      _brew_install docker-compose docker-compose
      _brew_install kubectl kubectl

      ask "Which cloud CLI? [ 1 ] AWS  [ 2 ] GCP  [ 3 ] Azure  [ 4 ] Skip:"
      read -r _cloud
      case "$_cloud" in
        1) _brew_install awscli aws ;;
        2) _brew_install google-cloud-sdk gcloud ;;
        3) _brew_install azure-cli az ;;
        *) info "Skipping cloud CLI install." ;;
      esac
      ;;

    general)
      _brew_install docker docker
      ;;
  esac
}

# ── VS Code (optional) ───────────────────────────────────────────────────────
install_vscode() {
  if has code; then
    success "VS Code already installed"
    return 0
  fi
  info "Installing VS Code..."
  if brew install --cask visual-studio-code; then
    success "VS Code installed — run 'code' from your terminal."
    INSTALLED_TOOLS+=("vscode")
  else
    error "Failed to install VS Code. Download manually: https://code.visualstudio.com"
  fi
}
