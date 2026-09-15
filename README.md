# dotfiles - Windows Terminal

My PowerShell 7 + Windows Terminal setup. Tokyo Night Storm theme, JetBrainsMono Nerd Font, acrylic background.

## Stack

- **Oh My Posh** - prompt (tokyonight_storm theme)
- **JetBrainsMono Nerd Font** - with Nerd Font glyphs
- **Terminal-Icons** - icons in directory listings
- **PSReadLine** - history search, inline suggestions
- **z** - frecent directory jumps
- **PSFzf + fzf** - fuzzy history (`Ctrl+R`) and file picker (`Ctrl+T`)

## Fresh install

Requires Windows Terminal and winget (both ship with Windows 11).

```powershell
git clone https://github.com/Ri8x/win-terminal-setup.git
cd win-terminal-setup
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
.\Install.ps1
```

Restart Windows Terminal after.

```powershell
# Skip steps you don't need
.\Install.ps1 -SkipFont           # font already installed
.\Install.ps1 -SkipTerminalConfig # keep existing WT settings
```

## Syncing changes back

```powershell
Copy-Item "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" .\profile\
Copy-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" .\terminal\
git add -A && git commit -m "chore: sync" && git push
```

## Changing the OMP theme

Edit `profile\Microsoft.PowerShell_profile.ps1`, replace `tokyonight_storm` with any theme name from [ohmyposh.dev/docs/themes](https://ohmyposh.dev/docs/themes), then delete `~\.config\omp-themes\` and restart.
