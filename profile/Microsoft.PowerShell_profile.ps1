# ============================================================
#  PowerShell Profile  –  Modern Setup
#  Requires: Oh My Posh, Terminal-Icons, PSReadLine, z, PSFzf
#  Font:     JetBrainsMono Nerd Font (set in Windows Terminal)
# ============================================================

# ── Oh My Posh ──────────────────────────────────────────────
# Theme: tokyonight_storm  |  Change to any theme at:
#   https://ohmyposh.dev/docs/themes
#
# Oh My Posh 31+ can use the theme name directly or a local/URL path.
# We cache a local copy in the user config dir for offline use.

$ompCmd = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($ompCmd) {
    $themeDir = Join-Path $env:USERPROFILE ".config\omp-themes"
    $themePath = Join-Path $themeDir "tokyonight_storm.omp.json"

    # Download theme once if not cached
    if (-not (Test-Path $themePath)) {
        $null = New-Item -ItemType Directory -Force -Path $themeDir
        $themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/tokyonight_storm.omp.json"
        try {
            Invoke-WebRequest -Uri $themeUrl -OutFile $themePath -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        } catch {
            # Fall back to built-in jandedobbeleer theme if download fails
            Remove-Item $themePath -ErrorAction SilentlyContinue
        }
    }

    if (Test-Path $themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
    } else {
        # Use jandedobbeleer (bundled default) as fallback
        oh-my-posh init pwsh | Invoke-Expression
    }
}

# ── Terminal Icons ───────────────────────────────────────────
# Adds file/folder icons to Get-ChildItem output
$termIcons = Get-Module -Name Terminal-Icons -ListAvailable -ErrorAction SilentlyContinue
if ($termIcons) { Import-Module Terminal-Icons }

# ── PSReadLine  ──────────────────────────────────────────────
# Fish/zsh-style smart completion and history
$rl = Get-Module -Name PSReadLine -ListAvailable -ErrorAction SilentlyContinue
if ($rl) {
    Import-Module PSReadLine

    Set-PSReadLineOption -EditMode Windows

    # Inline auto-suggestions — requires VT-capable terminal (Windows Terminal, etc.)
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch { <# silently skip in non-VT contexts (e.g. ISE, CI) #> }

    # History search with Up/Down arrows
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Tab completion menu (like zsh Tab)
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Ctrl+D exits like Unix shells
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

    # History options
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -MaximumHistoryCount 10000

    # Color scheme: Tokyo Night Storm palette
    Set-PSReadLineOption -Colors @{
        Command            = '#7aa2f7'   # blue
        Parameter          = '#bb9af7'   # purple
        String             = '#9ece6a'   # green
        Number             = '#ff9e64'   # orange
        Variable           = '#73daca'   # teal
        Comment            = '#565f89'   # muted gray
        Keyword            = '#f7768e'   # red/pink
        Type               = '#2ac3de'   # cyan
        Operator           = '#c0caf5'   # light foreground
        InlinePrediction   = '#565f89'   # ghost text
        ListPrediction     = '#7aa2f7'
        ListPredictionSelected = '#3b4261'
    }
}

# ── z  ───────────────────────────────────────────────────────
# Jump to frequently visited directories: z <partial-path>
$zMod = Get-Module -Name z -ListAvailable -ErrorAction SilentlyContinue
if ($zMod) { Import-Module z }

# ── PSFzf ────────────────────────────────────────────────────
# Ctrl+r  fuzzy history search
# Ctrl+t  fuzzy file picker
# Alt+c   fuzzy cd
$fzfAvailable = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
$fzfMod = Get-Module -Name PSFzf -ListAvailable -ErrorAction SilentlyContinue
if ($fzfAvailable -and $fzfMod) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# ── Environment ──────────────────────────────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding             = [System.Text.Encoding]::UTF8

# ── Aliases & Functions ──────────────────────────────────────

# Unix-ish
Set-Alias -Name which -Value Get-Command
Set-Alias -Name grep  -Value Select-String

function touch { New-Item -ItemType File @args }

# Navigation
function ..  { Set-Location .. }
function ... { Set-Location ..\.. }

# Directory listing with icons
function ll  { Get-ChildItem -Force @args }
function la  { Get-ChildItem -Force -Hidden @args }
function lh  {
    Get-ChildItem -Force @args |
    Format-Table Name, LastWriteTime,
        @{ L='Size'; E={
            if ($_.PSIsContainer) { '<DIR>' }
            else { '{0:N1} KB' -f ($_.Length / 1KB) }
        }}
}

# Open current folder in Explorer
function ex { explorer . }

# Git shortcuts
if (Get-Command git -ErrorAction SilentlyContinue) {
    function gs  { git status }
    function ga  { git add @args }
    function gc  { git commit -m @args }
    function gp  { git push @args }
    function gl  { git log --oneline --graph --decorate --all }
    function gd  { git diff @args }
    function gco { git checkout @args }
    function gb  { git branch @args }
}

# Profile management
function Edit-Profile   { code $PROFILE }
function Reload-Profile { . $PROFILE; Write-Host "Profile reloaded." -ForegroundColor Green }
