# common.ps1 — shared PowerShell helpers, colours, state management

# ── State file ─────────────────────────────────────────────────────────────
$StateFile = "$env:USERPROFILE\.devkit_state"

function Test-StepDone {
  param([string]$Key)
  if (-not (Test-Path $StateFile)) { return $false }
  $lines = Get-Content $StateFile -ErrorAction SilentlyContinue
  return ($null -ne $lines) -and ($lines -contains $Key)
}

function Mark-Done {
  param([string]$Key)
  if (-not (Test-StepDone $Key)) {
    Add-Content -Path $StateFile -Value $Key -Encoding UTF8
  }
}

function Reset-State {
  if (Test-Path $StateFile) { Remove-Item $StateFile -Force }
  Write-DkSuccess "State cleared — starting fresh"
}

# ── Output helpers ──────────────────────────────────────────────────────────
function Write-DkInfo    { param([string]$Msg); Write-Host "  -> $Msg" -ForegroundColor Cyan }
function Write-DkSuccess { param([string]$Msg); Write-Host "  + $Msg" -ForegroundColor Green }
function Write-DkWarn    { param([string]$Msg); Write-Host "  ! $Msg" -ForegroundColor Yellow }
function Write-DkError   { param([string]$Msg); Write-Host "  x $Msg" -ForegroundColor Red }
function Write-DkHeader  { param([string]$Msg); Write-Host "`n>> $Msg" -ForegroundColor Blue }
function Ask-User        { param([string]$Prompt); Write-Host "  ? $Prompt " -ForegroundColor Yellow -NoNewline }

# ── Safe download with retries ──────────────────────────────────────────────
function Invoke-SafeDownload {
  param(
    [string]$Url,
    [string]$OutPath = ""
  )
  $attempt = 0
  while ($attempt -lt 3) {
    $attempt++
    try {
      if ($OutPath) {
        Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing
      } else {
        return (Invoke-WebRequest -Uri $Url -UseBasicParsing).Content
      }
      return
    } catch {
      if ($attempt -lt 3) {
        Write-DkWarn "Download failed (attempt $attempt of 3). Retrying in 5s..."
        Start-Sleep -Seconds 5
      } else {
        Write-DkError "Failed to download $Url after 3 attempts. Check your connection and run again."
        exit 1
      }
    }
  }
}

# ── Command existence check ─────────────────────────────────────────────────
function Test-Cmd {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ── winget install helper ───────────────────────────────────────────────────
function Install-WithWinget {
  param(
    [string]$Id,
    [string]$Label,
    [string]$Cmd = ""
  )
  $checkCmd = if ($Cmd) { $Cmd } else { $Label }
  if (Test-Cmd $checkCmd) {
    Write-DkSuccess "$Label already installed"
    return
  }
  Write-DkInfo "Installing $Label via winget..."
  try {
    winget install --id $Id --silent --accept-source-agreements --accept-package-agreements
    Write-DkSuccess "$Label installed"
    $global:InstalledTools += $Label
  } catch {
    Write-DkError "Failed to install $Label — you can install it manually."
  }
}

# ── Installed tools tracker ─────────────────────────────────────────────────
$global:InstalledTools = @()

# ── Summary ─────────────────────────────────────────────────────────────────
function Print-Summary {
  Write-Host ""
  Write-Host ("=" * 60) -ForegroundColor Green
  Write-Host "  devkit setup complete!" -ForegroundColor Green
  Write-Host ("=" * 60) -ForegroundColor Green
  Write-Host ""

  if ($global:InstalledTools.Count -gt 0) {
    Write-Host "  Installed this run:" -ForegroundColor Cyan
    foreach ($tool in $global:InstalledTools) {
      Write-Host "    + $tool" -ForegroundColor Green
    }
    Write-Host ""
  }

  Write-Host "  Next steps:" -ForegroundColor Cyan
  Write-Host "    -> Restart your terminal for all tools to load"
  Write-Host "    -> Run 'gh auth login' to authenticate with GitHub"
  Write-Host "    -> Run 'nvm use lts' to activate Node.js"
  Write-Host "    -> Run 'claude' or 'codex' inside a project to start coding with AI"
  Write-Host ""
  Write-Host "  State file: $env:USERPROFILE\.devkit_state" -ForegroundColor Cyan
  Write-Host "  To reset and start fresh: .\scripts\install.ps1 --reset"
  Write-Host ""
}
