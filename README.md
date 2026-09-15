# win-terminal-setup

A one-script bootstrap for a modern, beautiful PowerShell + Windows Terminal environment on any fresh Windows 11 machine.

## What it installs

| Component | Purpose |
|-----------|---------|
| **PowerShell 7** | Modern shell (replaces Windows PowerShell 5.1) |
| **Oh My Posh** | Prompt engine — the Oh My Zsh equivalent for Windows |
| **JetBrainsMono Nerd Font** | Full glyph/icon/ligature support |
| **fzf** | Fuzzy finder binary |
| **Terminal-Icons** | File/folder icons in `ls` output |
| **PSReadLine** | Fish-style inline autocomplete & history search |
| **z** | Jump to frecent directories (`z proj`) |
| **PSFzf** | Fuzzy history (`Ctrl+R`) and file picker (`Ctrl+T`) |

**Theme:** Tokyo Night Storm (dark, translucent acrylic Windows Terminal)

---

## Requirements

- Windows 11 (or Windows 10 21H2+)
- Windows Terminal installed — get it from the [Microsoft Store](https://aka.ms/terminal) if missing
- `winget` available (ships with Windows 11 via *App Installer*)
- Internet connection (for first-time package downloads)

---

## Quick start

```powershell
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/win-terminal-setup.git
cd win-terminal-setup

# 2. Allow scripts to run for your user (one-time)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# 3. Run the bootstrap
.\Install.ps1

# 4. Restart Windows Terminal
```

That's it. On next launch you'll have a fully styled PS7 prompt with all tooling active.

---

## Flags

```powershell
.\Install.ps1 -SkipFont           # Skip font install (already installed)
.\Install.ps1 -SkipTerminalConfig # Skip Windows Terminal settings overwrite
.\Install.ps1 -SkipFont -SkipTerminalConfig
```

---

## What gets installed where

| File | Destination |
|------|-------------|
| `profile\Microsoft.PowerShell_profile.ps1` | `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| `terminal\settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| `omp-themes\tokyonight_storm.omp.json` | `~\.config\omp-themes\tokyonight_storm.omp.json` |

Any existing files are backed up with a `.bak-YYYYMMDD-HHmmss` suffix before being replaced.

---

## Key bindings (in your new shell)

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Fuzzy history search |
| `Ctrl+T` | Fuzzy file picker |
| `↑ / ↓` | History search matching current input |
| `Tab` | Scrollable completion menu |

## Handy aliases & functions

| Command | Does |
|---------|------|
| `z <partial>` | Jump to a frecent directory |
| `ll` | `ls` with icons and hidden files |
| `la` | `ls` showing hidden files only |
| `lh` | `ls` with human-readable sizes |
| `..` / `...` | Go up one/two directories |
| `ex` | Open current folder in Explorer |
| `gs` / `gl` / `ga` / `gc` / `gp` | git shortcuts |
| `Reload-Profile` | Reload profile without restarting |
| `Edit-Profile` | Open profile in VS Code |

---

## Changing the Oh My Posh theme

1. Browse themes at [ohmyposh.dev/docs/themes](https://ohmyposh.dev/docs/themes)
2. In `profile\Microsoft.PowerShell_profile.ps1`, change `tokyonight_storm` to your chosen theme name (both the filename and the `$themeUrl` line)
3. Delete `~\.config\omp-themes\` to force a re-download, then restart the terminal

---

## Repository layout

```
win-terminal-setup/
├── Install.ps1                          # Bootstrap script — run this
├── profile/
│   └── Microsoft.PowerShell_profile.ps1 # PS7 profile
├── terminal/
│   └── settings.json                    # Windows Terminal config
├── omp-themes/
│   └── tokyonight_storm.omp.json        # Cached OMP theme (offline installs)
└── README.md
```

---

## Updating your dotfiles

Made changes to your profile or WT settings? Sync them back to the repo:

```powershell
# From the repo directory
Copy-Item "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" .\profile\
Copy-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" .\terminal\
git add -A
git commit -m "chore: sync dotfiles"
git push
```
