# install.ps1 — devkit Windows entry point
# Usage: .\scripts\install.ps1 [--reset]
#
# One-liner:
#   irm https://raw.githubusercontent.com/thejamesnick/devkit/main/scripts/install.ps1 | iex

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load shared helpers
. "$ScriptDir\..\src\common.ps1"

# ── --reset flag ──────────────────────────────────────────────────────────
if ($args -contains "--reset") {
  Reset-State
}

# ── Never run as Administrator ────────────────────────────────────────────
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-DkError "devkit should not be run as Administrator. Please run as a normal user."
  exit 1
}

# ── Step: greet ───────────────────────────────────────────────────────────
if (-not (Test-StepDone "greet")) {
  Write-Host ""
  Write-Host "  Hey! Let's set up your machine for development." -ForegroundColor Green
  Write-Host ""
  Mark-Done "greet"
}

# ── Step: get_name ────────────────────────────────────────────────────────
if (-not (Test-StepDone "get_name")) {
  $devkitName = Read-Host "  ? What's your name"
  Write-DkSuccess "Hey $devkitName! Let's go"
  Mark-Done "get_name"
}

# ── Step: pkg_manager ─────────────────────────────────────────────────────
if (-not (Test-StepDone "pkg_manager")) {
  Write-DkHeader "Package manager"
  if (Test-Cmd winget) {
    Write-DkSuccess "winget is available"
  } else {
    Write-DkError "winget not found. Install 'App Installer' from the Microsoft Store:"
    Write-DkInfo  "https://aka.ms/getwinget"
    exit 1
  }
  Mark-Done "pkg_manager"
}

# ── Step: core_tools ──────────────────────────────────────────────────────
Write-DkHeader "Core tools"

if (-not (Test-StepDone "core_git")) {
  Install-WithWinget "Git.Git" "git" "git"
  Mark-Done "core_git"
}

if (-not (Test-StepDone "core_gh")) {
  Install-WithWinget "GitHub.cli" "gh" "gh"
  Mark-Done "core_gh"
}

if (-not (Test-StepDone "core_curl")) {
  Install-WithWinget "cURL.cURL" "curl" "curl"
  Mark-Done "core_curl"
}

# nvm for Windows
if (-not (Test-StepDone "core_nvm")) {
  if (Test-Cmd nvm) {
    Write-DkSuccess "nvm already installed"
  } else {
    Write-DkInfo "Installing nvm for Windows..."
    Install-WithWinget "CoreyButler.NVMforWindows" "nvm" "nvm"
  }
  Mark-Done "core_nvm"
}

# Node LTS via nvm
if (-not (Test-StepDone "core_node")) {
  if (Test-Cmd node) {
    Write-DkSuccess "node already installed"
  } else {
    Write-DkInfo "Installing Node.js LTS via nvm..."
    nvm install lts
    nvm use lts
    Write-DkSuccess "Node.js LTS installed"
    $global:InstalledTools += "node"
  }
  Mark-Done "core_node"
}

# yarn + pnpm
if (-not (Test-StepDone "core_yarn")) {
  if (Test-Cmd yarn) {
    Write-DkSuccess "yarn already installed"
  } else {
    npm install -g yarn
    Write-DkSuccess "yarn installed"
    $global:InstalledTools += "yarn"
  }
  Mark-Done "core_yarn"
}

if (-not (Test-StepDone "core_pnpm")) {
  if (Test-Cmd pnpm) {
    Write-DkSuccess "pnpm already installed"
  } else {
    npm install -g pnpm
    Write-DkSuccess "pnpm installed"
    $global:InstalledTools += "pnpm"
  }
  Mark-Done "core_pnpm"
}

# pyenv-win
if (-not (Test-StepDone "core_pyenv")) {
  if (Test-Cmd pyenv) {
    Write-DkSuccess "pyenv already installed"
  } else {
    Write-DkInfo "Installing pyenv-win..."
    Install-WithWinget "pyenv-win.pyenv-win" "pyenv-win" "pyenv"
  }
  Mark-Done "core_pyenv"
}

# Python via pyenv
if (-not (Test-StepDone "core_python")) {
  if (Test-Cmd python) {
    Write-DkSuccess "python already installed"
  } else {
    Write-DkInfo "Installing latest stable Python via pyenv..."
    $latestPy = (pyenv install --list | Where-Object { $_ -match '^\s*\d+\.\d+\.\d+\s*$' } |
      Select-Object -Last 1).Trim()
    pyenv install $latestPy
    pyenv global $latestPy
    Write-DkSuccess "Python $latestPy installed"
    $global:InstalledTools += "python@$latestPy"
  }
  Mark-Done "core_python"
}

# Shell RC patching — not applicable on Windows, just mark done
if (-not (Test-StepDone "shell_rc_patch")) {
  Mark-Done "shell_rc_patch"
}

# ── Step: dev_type ────────────────────────────────────────────────────────
$devType = ""
if (-not (Test-StepDone "dev_type")) {
  Write-DkHeader "What kind of dev work do you do?"
  Write-Host ""
  Write-Host "  [ 1 ] Web / Frontend"         -ForegroundColor Cyan
  Write-Host "  [ 2 ] Backend / APIs"          -ForegroundColor Cyan
  Write-Host "  [ 3 ] Mobile (React Native / Flutter)" -ForegroundColor Cyan
  Write-Host "  [ 4 ] Data / ML / AI"          -ForegroundColor Cyan
  Write-Host "  [ 5 ] DevOps / Cloud"          -ForegroundColor Cyan
  Write-Host "  [ 6 ] General / Not sure yet"  -ForegroundColor Cyan
  Write-Host ""
  $choice = Read-Host "  ? Enter a number [1-6]"
  switch ($choice) {
    "1" { $devType = "web" }
    "2" { $devType = "backend" }
    "3" { $devType = "mobile" }
    "4" { $devType = "data" }
    "5" { $devType = "devops" }
    "6" { $devType = "general" }
    default {
      Write-DkWarn "Invalid choice — defaulting to General."
      $devType = "general"
    }
  }
  Add-Content -Path $StateFile -Value "dev_type_value=$devType" -Encoding UTF8
  Mark-Done "dev_type"
}

# Resume dev_type from state
if ([string]::IsNullOrEmpty($devType)) {
  $line = Get-Content $StateFile -ErrorAction SilentlyContinue |
    Where-Object { $_ -match "^dev_type_value=" } |
    Select-Object -First 1
  $devType = if ($line) { $line -replace "^dev_type_value=", "" } else { "general" }
}

# ── Step: stack_tools ─────────────────────────────────────────────────────
if (-not (Test-StepDone "stack_tools")) {
  Write-DkHeader "Stack tools"
  Write-DkInfo "Dev type: $devType"

  switch ($devType) {
    "web" {
      Write-DkSuccess "Web / Frontend — core tools already cover it (node, yarn, pnpm)"
    }
    "backend" {
      Install-WithWinget "Docker.DockerDesktop" "Docker Desktop" "docker"
    }
    "mobile" {
      Install-WithWinget "Oracle.JDK.17" "Java 17" "java"
      Write-DkWarn "Android Studio must be installed manually."
      Write-DkInfo  "-> Download: https://developer.android.com/studio"
    }
    "data" {
      pip install --upgrade pip
      pip install jupyter numpy pandas matplotlib scikit-learn virtualenv ipykernel
      Write-DkSuccess "Core data tools installed"
      $global:InstalledTools += @("jupyter", "numpy", "pandas", "scikit-learn")

      $dlAns = Read-Host "  ? Install deep learning tools (torch CPU build)? (y/N)"
      if ($dlAns -match "^[Yy]$") {
        pip install torch --index-url https://download.pytorch.org/whl/cpu
        Write-DkSuccess "torch installed"
        $global:InstalledTools += "torch"
      }

      $llmAns = Read-Host "  ? Install OpenAI / LLM tools (openai, langchain)? (y/N)"
      if ($llmAns -match "^[Yy]$") {
        pip install openai langchain
        Write-DkSuccess "openai + langchain installed"
        $global:InstalledTools += @("openai", "langchain")
      }
    }
    "devops" {
      Install-WithWinget "Docker.DockerDesktop" "Docker Desktop" "docker"
      Install-WithWinget "Kubernetes.kubectl" "kubectl" "kubectl"

      $cloudChoice = Read-Host "  ? Which cloud CLI? [ 1 ] AWS  [ 2 ] GCP  [ 3 ] Azure  [ 4 ] Skip"
      switch ($cloudChoice) {
        "1" { Install-WithWinget "Amazon.AWSCLI"         "AWS CLI"       "aws"    }
        "2" { Install-WithWinget "Google.CloudSDK"       "gcloud"        "gcloud" }
        "3" { Install-WithWinget "Microsoft.AzureCLI"   "Azure CLI"     "az"     }
        default { Write-DkInfo "Skipping cloud CLI install." }
      }
    }
    "general" {
      Install-WithWinget "Docker.DockerDesktop" "Docker Desktop" "docker"
    }
  }

  Mark-Done "stack_tools"
}

# ── Step: github ──────────────────────────────────────────────────────────
if (-not (Test-StepDone "github")) {
  Write-DkHeader "GitHub"
  $ghAns = Read-Host "  ? Do you have a GitHub account? (y/N)"
  if ($ghAns -match "^[Yy]$") {
    Write-DkInfo "Running gh auth login..."
    gh auth login
  } else {
    Write-DkInfo "Skipping — gh is installed and ready for when you need it."
  }
  Mark-Done "github"
}

# ── Step: ssh_key ─────────────────────────────────────────────────────────
if (-not (Test-StepDone "ssh_key")) {
  Write-DkHeader "SSH key"
  $sshAns = Read-Host "  ? Want to generate an SSH key? (y/N)"
  if ($sshAns -match "^[Yy]$") {
    $sshEmail = Read-Host "  ? Enter your email address for the SSH key"
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
    $sshKey = "$sshDir\id_ed25519"
    if (-not (Test-Path $sshKey)) {
      ssh-keygen -t ed25519 -C $sshEmail -f $sshKey -N '""'
      Write-DkSuccess "SSH key generated at $sshKey"
    } else {
      Write-DkSuccess "SSH key already exists at $sshKey"
    }
    Write-DkInfo "Your public key (add this to GitHub -> Settings -> SSH keys):"
    Write-Host ""
    Get-Content "$sshKey.pub"
    Write-Host ""
  } else {
    Write-DkInfo "Skipping SSH key generation."
  }
  Mark-Done "ssh_key"
}

# ── Step: vscode ──────────────────────────────────────────────────────────
if (-not (Test-StepDone "vscode")) {
  Write-DkHeader "VS Code (optional)"
  $codeAns = Read-Host "  ? Want to install VS Code? (y/N)"
  if ($codeAns -match "^[Yy]$") {
    Install-WithWinget "Microsoft.VisualStudioCode" "VS Code" "code"
  } else {
    Write-DkInfo "Skipping VS Code — download it any time from https://code.visualstudio.com"
  }
  Mark-Done "vscode"
}

# ── Step: done ────────────────────────────────────────────────────────────
if (-not (Test-StepDone "done")) {
  Print-Summary
  Mark-Done "done"
}
