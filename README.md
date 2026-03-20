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
4. Install **GitHub CLI** + **gh-copilot** extension for AI-powered command suggestions
5. Copy **starship.toml** to `~/.config/`
6. Set up the **PowerShell profile** (handles OneDrive vs local Documents automatically)
7. Check **Windows Terminal** and **VSCode** font settings and provide guidance

Use `-Force` to overwrite existing configs without prompting, or `-SkipFontInstall` to skip the font step:

```powershell
.\Install-Windows.ps1 -Force
.\Install-Windows.ps1 -SkipFontInstall
```

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
> if (Test-Path -Path $localprofile) {
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
- Green-heavy color theme with teal, lime, and warm accent colors

### PSReadLine (PowerShell)

- Predictive IntelliSense with history-based list view
- Syntax coloring matched to the green Starship theme
- `Ctrl+RightArrow` accepts the next word from inline prediction

### Terminal-Icons (PowerShell)

- Nerd Font icons for files and folders in `Get-ChildItem` output

### GitHub Copilot CLI (PowerShell)

- `ghcs` — Copilot Suggest: suggests shell commands from natural language descriptions
- `ghce` — Copilot Explain: explains what a command does in plain English
- Requires GitHub CLI (`gh`) and the `gh-copilot` extension
