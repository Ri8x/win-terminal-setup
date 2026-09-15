#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstraps a modern PowerShell + Windows Terminal environment on a fresh Windows 11 machine.

.DESCRIPTION
    1. Installs PowerShell 7 (via winget)
    2. Installs Oh My Posh (via winget)
    3. Installs JetBrainsMono Nerd Font (via oh-my-posh font install)
    4. Installs fzf (via winget)
    5. Installs PowerShell modules: Terminal-Icons, z, PSFzf  (PSReadLine ships with PS7)
    6. Copies the PowerShell profile to the correct location
    7. Copies the Windows Terminal settings to the correct location
    8. Copies the Oh My Posh theme to ~/.config/omp-themes/

.NOTES
    Run from an elevated-or-normal PowerShell session. Module installs use -Scope CurrentUser.
    Restart Windows Terminal after the script completes.

.EXAMPLE
    # From a normal (non-admin) PowerShell prompt:
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    .\Install.ps1
#>

[CmdletBinding()]
param(
    [switch]$SkipFont,          # Skip font install (e.g. font already installed)
    [switch]$SkipTerminalConfig # Skip Windows Terminal settings overwrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step  { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Skip  { param($msg) Write-Host "    [--] $msg" -ForegroundColor DarkGray }
function Write-Warn  { param($msg) Write-Host "    [!!] $msg" -ForegroundColor Yellow }

function Assert-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget is not available. Install 'App Installer' from the Microsoft Store and re-run."
    }
}

function Install-WingetPackage {
    param([string]$Id, [string]$Name)
    $existing = winget list --id $Id --exact --accept-source-agreements 2>&1 |
                Select-String $Id
    if ($existing) {
        Write-Skip "$Name already installed"
    } else {
        Write-Host "    Installing $Name..." -ForegroundColor Yellow
        winget install $Id --silent --accept-package-agreements --accept-source-agreements
        Write-Ok "$Name installed"
    }
}

function Install-PSModule {
    param([string]$Name)
    $existing = Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Skip "$Name already installed (v$($existing[0].Version))"
    } else {
        Write-Host "    Installing $Name..." -ForegroundColor Yellow
        Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
        Write-Ok "$Name installed"
    }
}

# ── Step 1: winget ────────────────────────────────────────────────────────────

Write-Step "Checking prerequisites"
Assert-Winget
Write-Ok "winget found"

# ── Step 2: PowerShell 7 ──────────────────────────────────────────────────────

Write-Step "PowerShell 7"
Install-WingetPackage -Id 'Microsoft.PowerShell' -Name 'PowerShell 7'

# Resolve pwsh path (MSIX Store install lands in WindowsApps)
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $pwsh) {
    $pwsh = Get-Item "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe" -ErrorAction SilentlyContinue
}
if (-not $pwsh) {
    Write-Warn "pwsh not on PATH yet. You may need to restart your shell after this script."
    $pwshExe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
} else {
    $pwshExe = $pwsh.Source
}
Write-Ok "pwsh: $pwshExe"

# ── Step 3: Oh My Posh ────────────────────────────────────────────────────────

Write-Step "Oh My Posh"
Install-WingetPackage -Id 'JanDeDobbeleer.OhMyPosh' -Name 'Oh My Posh'

# ── Step 4: JetBrainsMono Nerd Font ──────────────────────────────────────────

if ($SkipFont) {
    Write-Step "JetBrainsMono Nerd Font"
    Write-Skip "Skipped (-SkipFont)"
} else {
    Write-Step "JetBrainsMono Nerd Font"
    $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($omp) {
        oh-my-posh font install JetBrainsMono
        Write-Ok "JetBrainsMono Nerd Font installed (may require logout/reboot to register)"
    } else {
        Write-Warn "oh-my-posh not found on PATH yet. Restart your shell and re-run, or install the font manually."
    }
}

# ── Step 5: fzf ───────────────────────────────────────────────────────────────

Write-Step "fzf"
Install-WingetPackage -Id 'junegunn.fzf' -Name 'fzf'

# ── Step 6: PowerShell modules ────────────────────────────────────────────────

Write-Step "PowerShell modules (Terminal-Icons, z, PSFzf)"

# Trust PSGallery silently
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue

# If we have PS7, install into it; otherwise fall back to current session
$installScript = {
    param($scriptDir)
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    foreach ($mod in @('Terminal-Icons', 'z', 'PSFzf')) {
        $existing = Get-Module -Name $mod -ListAvailable -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Host "    [--] $mod already installed (v$($existing[0].Version))" -ForegroundColor DarkGray
        } else {
            Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
            Write-Host "    [OK] $mod installed" -ForegroundColor Green
        }
    }
}

if (Test-Path $pwshExe) {
    & $pwshExe -NoProfile -ExecutionPolicy Bypass -Command $installScript -args $scriptDir
} else {
    # Run in current session
    & $installScript $scriptDir
}

# ── Step 7: PowerShell profile ────────────────────────────────────────────────

Write-Step "PowerShell profile"

# PS7 profile location
$ps7ProfileDir  = Join-Path $env:USERPROFILE "Documents\PowerShell"
$ps7ProfilePath = Join-Path $ps7ProfileDir   "Microsoft.PowerShell_profile.ps1"
$sourceProfile  = Join-Path $scriptDir       "profile\Microsoft.PowerShell_profile.ps1"

if (-not (Test-Path $sourceProfile)) {
    Write-Warn "Source profile not found at: $sourceProfile"
} else {
    $null = New-Item -ItemType Directory -Force -Path $ps7ProfileDir
    if (Test-Path $ps7ProfilePath) {
        $backup = "$ps7ProfilePath.bak-$(Get-Date -f 'yyyyMMdd-HHmmss')"
        Copy-Item $ps7ProfilePath $backup
        Write-Skip "Existing profile backed up to: $backup"
    }
    Copy-Item $sourceProfile $ps7ProfilePath -Force
    Write-Ok "Profile installed to: $ps7ProfilePath"
}

# ── Step 8: Oh My Posh theme ─────────────────────────────────────────────────

Write-Step "Oh My Posh theme"

$ompThemeDir  = Join-Path $env:USERPROFILE ".config\omp-themes"
$ompThemeSrc  = Join-Path $scriptDir "omp-themes\tokyonight_storm.omp.json"
$ompThemeDest = Join-Path $ompThemeDir "tokyonight_storm.omp.json"

$null = New-Item -ItemType Directory -Force -Path $ompThemeDir

if (Test-Path $ompThemeSrc) {
    Copy-Item $ompThemeSrc $ompThemeDest -Force
    Write-Ok "Theme copied to: $ompThemeDest"
} else {
    # Download it
    $themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/tokyonight_storm.omp.json"
    try {
        Invoke-WebRequest -Uri $themeUrl -OutFile $ompThemeDest -UseBasicParsing -TimeoutSec 15
        Write-Ok "Theme downloaded to: $ompThemeDest"
        # Also save it back into the repo for future offline installs
        Copy-Item $ompThemeDest $ompThemeSrc -Force
        Write-Ok "Theme cached in repo: $ompThemeSrc"
    } catch {
        Write-Warn "Could not download theme. The profile will fall back to the default OMP theme."
    }
}

# ── Step 9: Windows Terminal settings ────────────────────────────────────────

if ($SkipTerminalConfig) {
    Write-Step "Windows Terminal settings"
    Write-Skip "Skipped (-SkipTerminalConfig)"
} else {
    Write-Step "Windows Terminal settings"

    $wtPackageDirs = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState"
    )
    $wtSettingsSrc = Join-Path $scriptDir "terminal\settings.json"

    if (-not (Test-Path $wtSettingsSrc)) {
        Write-Warn "terminal\settings.json not found in repo."
    } else {
        $installed = $false
        foreach ($dir in $wtPackageDirs) {
            if (Test-Path $dir) {
                $dest = Join-Path $dir "settings.json"
                if (Test-Path $dest) {
                    $backup = "$dest.bak-$(Get-Date -f 'yyyyMMdd-HHmmss')"
                    Copy-Item $dest $backup
                    Write-Skip "Existing WT settings backed up to: $backup"
                }
                Copy-Item $wtSettingsSrc $dest -Force
                Write-Ok "WT settings installed to: $dest"
                $installed = $true
            }
        }
        if (-not $installed) {
            Write-Warn "Windows Terminal not found. Install it from the Microsoft Store, then re-run with -SkipFont."
        }
    }
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Setup complete!  Restart Windows Terminal to apply.       " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Things to do after restart:" -ForegroundColor White
Write-Host "    - If icons look like boxes, log out and back in (font registration)" -ForegroundColor DarkGray
Write-Host "    - To change OMP theme: edit profile and replace 'tokyonight_storm'" -ForegroundColor DarkGray
Write-Host "    - Browse themes at: https://ohmyposh.dev/docs/themes" -ForegroundColor DarkGray
Write-Host ""
