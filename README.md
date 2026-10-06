# Shell Configurations

My shell profile configurations, including a customizable Starship prompt and setup scripts for various environments.

## Prerequisites

- [Starship](https://starship.rs/) prompt installed
- A [Nerd Font](https://www.nerdfonts.com/) installed and configured in your terminal
- PowerShell 7+ (for PSReadLine predictive IntelliSense)

### Optional PowerShell Modules

```powershell
Install-Module -Name Terminal-Icons -Scope CurrentUser
```

## Structure

| Path                                          | Description                                                    |
| --------------------------------------------- | -------------------------------------------------------------- |
| `.config/starship.toml`                       | Starship prompt configuration (cross-platform, green theme)    |
| `.bashrc`                                     | Bash shell configuration with Starship init                    |
| `PowerShell/Microsoft.PowerShell_profile.ps1` | PowerShell profile (Starship + PSReadLine + Terminal-Icons)    |
| `Install-Windows.ps1`                         | Automated setup script for Windows 10/11                       |
| `Install-Unix.sh`                             | Symlink-based setup for Linux/macOS (installs Starship)        |

## Quick Start (Windows)

Clone the repo and run the install script from an elevated PowerShell 7+ terminal:

```powershell
git clone https://github.com/rbcmgs/shell-configurations.git
cd shell-configurations
.\Install-Windows.ps1
```

The script will:

1. Install **Starship** via winget (if not already installed)
2. Install **CaskaydiaCove Nerd Font** to the user font directory
3. Install **Terminal-Icons** PowerShell module
4. Install **GitHub CLI**, **Git for Windows**, **GitHub Copilot CLI** (`copilot`) and **Claude Code** (`claude`) via winget
5. Copy **starship.toml** to `~/.config/`
6. Set up the **PowerShell profile** (handles OneDrive vs local Documents automatically)
7. Check **Windows Terminal** and **VSCode** font settings and provide guidance

Use `-Force` to overwrite existing configs without prompting, or `-SkipFontInstall` to skip the font step:

```powershell
.\Install-Windows.ps1 -Force
.\Install-Windows.ps1 -SkipFontInstall
```

## Quick Start (Linux / macOS)

```sh
./Install-Unix.sh
```

## Machine-specific overrides

Untracked per-machine settings go in `~/.bashrc.local` (bash) or `profile.local.ps1` next to your `PowerShell` profile.

## Manual Setup

### Starship

Copy (or symlink) the config to the default Starship location:

```sh
# Linux / macOS
cp .config/starship.toml ~/.config/starship.toml

# Windows (PowerShell)
Copy-Item .config\starship.toml $HOME\.config\starship.toml
```

### Bash

Append or source the `.bashrc` in your shell profile:

```sh
cp .bashrc ~/.bashrc
# or
echo 'source ~/path/to/shell-configurations/.bashrc' >> ~/.bashrc
```

### PowerShell

Copy the profile to your local PowerShell profile directory:

```powershell
Copy-Item PowerShell\Microsoft.PowerShell_profile.ps1 "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
```

> **Note:** If your main profile is synced via OneDrive, you can source this as a local profile instead. Add the following to your OneDrive-synced profile:
>
> ```powershell
> $localprofile = "$HOME\Documents\PowerShell\$($MyInvocation.MyCommand.Name)"
> if ((Test-Path -Path $localprofile) -and ((Resolve-Path -Path $localprofile).Path -ne $PSCommandPath)) {
>   . $localprofile
> }
> ```

## VSCode Compatibility

Starship works in VSCode's integrated terminal out of the box. The PowerShell profile skips Starship only for the **PowerShell Extension Host** terminal (PSES) where heavy prompt customization can cause timeouts. Regular integrated terminals (`ConsoleHost`) load Starship normally.

For the best experience in VSCode, set a Nerd Font as your terminal font:

```json
{
  "terminal.integrated.fontFamily": "'CaskaydiaCove Nerd Font', 'FiraCode Nerd Font', monospace"
}
```

## Features

### Starship Prompt

- Two-line prompt with git status, kubernetes context, and OS detection
- **Dev toolchain**: Node.js version, Python version + virtualenv, package version
- **Command duration**: shows elapsed time for commands taking >2s
- **Transient prompt** (PowerShell): previous prompts collapse to `❯` to keep scrollback clean
- Cached init script for faster PowerShell startup
- Green-heavy color theme with teal, lime, and warm accent colors

### PSReadLine (PowerShell)

- Predictive IntelliSense with history-based list view
- Syntax coloring matched to the green Starship theme
- `Ctrl+RightArrow` accepts the next word from inline prediction

### Terminal-Icons (PowerShell)

- Nerd Font icons for files and folders in `Get-ChildItem` output

### AI coding agents

- `copilot` (GitHub Copilot CLI) and `claude` (Claude Code) are installed by `Install-Windows.ps1`; sign in on first run (`/login`).
- The old `gh-copilot` extension (`ghcs`/`ghce`) is retired and no longer used.
- Claude Code needs Git for Windows; set `CLAUDE_CODE_GIT_BASH_PATH` if Git is installed in a non-default location.
- Starship is skipped inside Claude Code's shell (`CLAUDECODE` set) and in the PowerShell Extension terminal, and `.bashrc` only configures interactive shells, so agent-run commands get clean output.