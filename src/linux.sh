#!/usr/bin/env bash
# linux.sh — Linux-specific installs (Ubuntu/Debian + Fedora/RHEL)

# Detect package manager and set globals
_init_pkg_manager() {
  if has apt-get; then
    PKG_MANAGER="apt"
    PKG_INSTALL="sudo apt-get install -y"
    PKG_UPDATE="sudo apt-get update -y"
  elif has dnf; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="sudo dnf install -y"
    PKG_UPDATE="sudo dnf check-update -y; true"
  else
    error "No supported package manager found (expected apt or dnf)."
    exit 1
  fi
}

# ── Package manager ─────────────────────────────────────────────────────────
install_pkg_manager() {
  _init_pkg_manager
  info "Package manager: $PKG_MANAGER"
  info "Updating package index..."
  eval "$PKG_UPDATE" || true
  success "Package index updated"
}

# ── Internal: install a package with state tracking ─────────────────────────
_pkg_install() {
  local pkg="$1"
  local label="${2:-$1}"
  local cmd="${3:-$label}"
  local step_key="core_${label}"

  if step_done "$step_key"; then
    return 0
  fi

  if has "$cmd"; then
    success "$label already installed"
    mark_done "$step_key"
    return 0
  fi

  info "Installing $label..."
  if eval "$PKG_INSTALL $pkg"; then
    success "$label installed"
    mark_done "$step_key"
    INSTALLED_TOOLS+=("$label")
  else
    error "Failed to install $label — check your connection and run again."
    exit 1
  fi
}

# ── Core tools ──────────────────────────────────────────────────────────────
install_core_tools() {
  _init_pkg_manager
  header "Core tools"

  _pkg_install git git git
  _pkg_install curl curl curl
  _pkg_install wget wget wget

  # GitHub CLI (needs special repo setup)
  if ! step_done "core_gh"; then
    if has gh; then
      success "gh already installed"
    else
      info "Installing GitHub CLI..."
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        sudo apt-get install -y ca-certificates
        safe_curl "https://cli.github.com/packages/githubcli-archive-keyring.gpg" "/tmp/dk-gh-keyring.gpg"
        sudo dd if=/tmp/dk-gh-keyring.gpg of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
          | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update -y
        sudo apt-get install -y gh
      else
        sudo dnf install -y 'dnf-command(config-manager)' 2>/dev/null || true
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || true
        sudo dnf install -y gh
      fi
      success "gh installed"
      INSTALLED_TOOLS+=("gh")
    fi
    mark_done "core_gh"
  fi

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
        error "Failed to install Node.js via nvm — run again."
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
      if npm install -g yarn; then
        success "yarn installed"
        INSTALLED_TOOLS+=("yarn")
      else
        error "Failed to install yarn — run the script again."
        exit 1
      fi
    fi
    mark_done "core_yarn"
  fi

  # pnpm
  if ! step_done "core_pnpm"; then
    if has pnpm; then
      success "pnpm already installed"
    else
      info "Installing pnpm..."
      if npm install -g pnpm; then
        success "pnpm installed"
        INSTALLED_TOOLS+=("pnpm")
      else
        error "Failed to install pnpm — run the script again."
        exit 1
      fi
    fi
    mark_done "core_pnpm"
  fi

  # pyenv — install dependencies first, then pyenv itself
  if ! step_done "core_pyenv"; then
    if has pyenv || [ -d "$HOME/.pyenv" ]; then
      success "pyenv already installed"
    else
      info "Installing pyenv build dependencies..."
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        sudo apt-get install -y \
          make build-essential libssl-dev zlib1g-dev libbz2-dev \
          libreadline-dev libsqlite3-dev llvm libncurses5-dev \
          libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev || true
      else
        sudo dnf groupinstall -y "Development Tools" 2>/dev/null || true
        sudo dnf install -y \
          openssl-devel bzip2-devel libffi-devel zlib-devel \
          readline-devel sqlite-devel xz-devel || true
      fi
      info "Installing pyenv..."
      if bash -c "$(safe_curl 'https://pyenv.run')"; then
        success "pyenv installed"
        INSTALLED_TOOLS+=("pyenv")
      else
        error "Failed to install pyenv — check your connection and run again."
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
  patch_rc "NVM_DIR" \
'# nvm — managed by devkit
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

  # shellcheck disable=SC2016
  patch_rc "pyenv init" \
'# pyenv — managed by devkit
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"'
}

# ── Stack tools ──────────────────────────────────────────────────────────────
install_stack_tools() {
  _init_pkg_manager
  local dev_type="$1"

  case "$dev_type" in
    web)
      success "Web / Frontend — core tools already cover it (nvm, node, yarn, pnpm) ✓"
      ;;

    backend)
      _install_docker
      ;;

    mobile)
      info "Installing Java..."
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        _pkg_install default-jdk java java
      else
        _pkg_install java-17-openjdk java java
      fi
      warn "Android Studio must be installed manually."
      info "→ Download: https://developer.android.com/studio"
      ;;

    data)
      info "Installing data / ML / AI tools via pip..."
      if pip install --upgrade pip && \
         pip install jupyter numpy pandas matplotlib scikit-learn virtualenv ipykernel; then
        success "Core data tools installed"
        INSTALLED_TOOLS+=("jupyter" "numpy" "pandas" "scikit-learn")
      else
        error "Failed to install data tools via pip — check your Python setup and run again."
        exit 1
      fi

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
      _install_docker
      _install_kubectl
      ask "Which cloud CLI? [ 1 ] AWS  [ 2 ] GCP  [ 3 ] Azure  [ 4 ] Skip:"
      read -r _cloud
      case "$_cloud" in
        1) _install_awscli ;;
        2) _install_gcloud ;;
        3) _install_azurecli ;;
        *) info "Skipping cloud CLI install." ;;
      esac
      ;;

    general)
      _install_docker
      ;;
  esac
}

# ── Docker ───────────────────────────────────────────────────────────────────
_install_docker() {
  if has docker; then
    success "Docker already installed"
    return 0
  fi
  info "Installing Docker..."
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt-get install -y ca-certificates gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings
    safe_curl "https://download.docker.com/linux/ubuntu/gpg" "/tmp/dk-docker.gpg"
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/dk-docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  else
    sudo dnf install -y docker docker-compose
    sudo systemctl enable --now docker
  fi
  sudo usermod -aG docker "$USER"
  success "Docker installed — you may need to log out and back in for group membership."
  INSTALLED_TOOLS+=("docker")
}

# ── kubectl ──────────────────────────────────────────────────────────────────
_install_kubectl() {
  if has kubectl; then
    success "kubectl already installed"
    return 0
  fi
  info "Installing kubectl..."
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt-get install -y apt-transport-https ca-certificates gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    safe_curl "https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key" "/tmp/dk-k8s.key"
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg /tmp/dk-k8s.key
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' \
      | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y kubectl
  else
    sudo dnf install -y kubectl
  fi
  success "kubectl installed"
  INSTALLED_TOOLS+=("kubectl")
}

# ── AWS CLI ──────────────────────────────────────────────────────────────────
_install_awscli() {
  if has aws; then
    success "AWS CLI already installed"
    return 0
  fi
  info "Installing AWS CLI..."
  if ! has unzip; then
    info "Installing unzip..."
    if [[ "$PKG_MANAGER" == "apt" ]]; then
      sudo apt-get install -y unzip
    else
      sudo dnf install -y unzip
    fi
  fi
  safe_curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" "/tmp/dk-awscliv2.zip"
  unzip -q /tmp/dk-awscliv2.zip -d /tmp/dk-awscli
  sudo /tmp/dk-awscli/aws/install
  rm -rf /tmp/dk-awscliv2.zip /tmp/dk-awscli
  success "AWS CLI installed"
  INSTALLED_TOOLS+=("aws-cli")
}

# ── Google Cloud SDK ─────────────────────────────────────────────────────────
_install_gcloud() {
  if has gcloud; then
    success "gcloud already installed"
    return 0
  fi
  info "Installing Google Cloud SDK..."
  bash -c "$(safe_curl 'https://sdk.cloud.google.com')" -- --disable-prompts
  success "Google Cloud SDK installed"
  INSTALLED_TOOLS+=("gcloud")
}

# ── Azure CLI ────────────────────────────────────────────────────────────────
_install_azurecli() {
  if has az; then
    success "Azure CLI already installed"
    return 0
  fi
  info "Installing Azure CLI..."
  bash -c "$(safe_curl 'https://aka.ms/InstallAzureCLIDeb')"
  success "Azure CLI installed"
  INSTALLED_TOOLS+=("az")
}

# ── VS Code (optional) ───────────────────────────────────────────────────────
install_vscode() {
  if has code; then
    success "VS Code already installed"
    return 0
  fi
  info "Installing VS Code..."
  if [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    safe_curl "https://packages.microsoft.com/keys/microsoft.asc" "/tmp/dk-ms.asc"
    sudo gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg /tmp/dk-ms.asc
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
      | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y code
  else
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    printf '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
      | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    sudo dnf install -y code
  fi
  success "VS Code installed — run 'code' from your terminal."
  INSTALLED_TOOLS+=("vscode")
}
