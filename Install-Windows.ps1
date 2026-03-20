#Requires -Version 7.0
<#
.SYNOPSIS
    Sets up the shell environment on a Windows 10/11 machine.

.DESCRIPTION
    Installs and configures:
    - Starship prompt (via winget)
    - A Nerd Font (CaskaydiaCove) for icon support
    - Terminal-Icons PowerShell module
    - PSReadLine configuration (green theme)
    - Starship config (~/.config/starship.toml)
    - PowerShell profile (local profile sourced by the main profile)

    Designed to be run from the root of the shell-configurations repository.

.PARAMETER SkipFontInstall
    Skip the Nerd Font installation step.

.PARAMETER Force
    Overwrite existing configuration files without prompting.

.EXAMPLE
    .\Install-Windows.ps1
    .\Install-Windows.ps1 -Force
    .\Install-Windows.ps1 -SkipFontInstall
#>
[CmdletBinding()]
param(
    [switch]$SkipFontInstall,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ---

function Write-Step {
    param([string]$Message)
    Write-Host "`n[$([char]0x2713)] $Message" -ForegroundColor Green
}

function Write-Skipped {
    param([string]$Message)
    Write-Host "  [-] $Message" -ForegroundColor DarkGray
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor Yellow
}

function Confirm-Overwrite {
    param([string]$Path)
    if ($Force) { return $true }
    if (-not (Test-Path $Path)) { return $true }
    $response = Read-Host "  File already exists: $Path. Overwrite? (y/N)"
    return ($response -eq 'y' -or $response -eq 'Y')
}

# --- Validate we're running from the repo root ---

$repoRoot = $PSScriptRoot
$requiredFiles = @(
    '.config\starship.toml',
    'PowerShell\Microsoft.PowerShell_profile.ps1'
)
foreach ($file in $requiredFiles) {
    if (-not (Test-Path (Join-Path $repoRoot $file))) {
        Write-Error "Missing required file: $file. Are you running from the repository root?"
    }
}

Write-Host "`n=== Shell Configurations - Windows Setup ===" -ForegroundColor Green
Write-Host "Repository: $repoRoot"

# ============================================================
# 1. Install Starship via winget
# ============================================================

Write-Step 'Checking Starship installation...'

if (Get-Command starship -ErrorAction SilentlyContinue) {
    $starshipVersion = (starship --version | Select-Object -First 1)
    Write-Skipped "Starship already installed ($starshipVersion)"
} else {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget is not available. Please install App Installer from the Microsoft Store, then re-run this script."
    }
    Write-Info 'Installing Starship via winget...'
    winget install --id Starship.Starship --exact --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Starship installation failed (exit code $LASTEXITCODE)."
    }

    # Refresh PATH for the current session
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"

    if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
        Write-Warn "Starship installed but not yet on PATH. You may need to restart your terminal."
    } else {
        Write-Info "Starship installed successfully."
    }
}

# ============================================================
# 2. Install a Nerd Font (CaskaydiaCove)
# ============================================================

Write-Step 'Checking Nerd Font installation...'

if ($SkipFontInstall) {
    Write-Skipped 'Font installation skipped (-SkipFontInstall).'
} else {
    # Check if the font is already installed by looking in the user and system font directories
    $fontInstalled = $false
    $fontDirs = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Fonts",
        "$env:SystemRoot\Fonts"
    )
    foreach ($dir in $fontDirs) {
        if (Test-Path $dir) {
            $found = Get-ChildItem $dir -Filter '*CaskaydiaCove*' -ErrorAction SilentlyContinue
            if ($found) { $fontInstalled = $true; break }
        }
    }

    # Also check registry for installed font names
    if (-not $fontInstalled) {
        $fontKeys = @(
            'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
            'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        )
        foreach ($key in $fontKeys) {
            if (Test-Path $key) {
                $props = Get-ItemProperty $key -ErrorAction SilentlyContinue
                if ($props) {
                    $names = $props.PSObject.Properties.Name
                    if ($names -match 'CaskaydiaCove|Caskaydia') {
                        $fontInstalled = $true
                        break
                    }
                }
            }
        }
    }

    if ($fontInstalled) {
        Write-Skipped 'CaskaydiaCove Nerd Font already installed.'
    } else {
        Write-Info 'Installing CaskaydiaCove Nerd Font...'

        $fontZipUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip'
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "nerd-font-install-$([System.IO.Path]::GetRandomFileName())"
        $tempZip = "$tempDir.zip"

        try {
            Invoke-WebRequest -Uri $fontZipUrl -OutFile $tempZip -UseBasicParsing
            Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

            # Install fonts to the user font directory
            $userFontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
            if (-not (Test-Path $userFontDir)) {
                New-Item -ItemType Directory -Path $userFontDir -Force | Out-Null
            }

            $fontFiles = Get-ChildItem $tempDir -Filter '*.ttf' -Recurse |
                Where-Object { $_.Name -notmatch 'Windows Compatible' }

            $shell = New-Object -ComObject Shell.Application
            $fontsFolder = $shell.Namespace(0x14) # Special Fonts folder

            foreach ($font in $fontFiles) {
                Copy-Item $font.FullName $userFontDir -Force

                # Register the font in the current user registry
                $fontName = [System.IO.Path]::GetFileNameWithoutExtension($font.Name) + ' (TrueType)'
                $fontPath = Join-Path $userFontDir $font.Name
                Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -Name $fontName -Value $fontPath
            }

            Write-Info "Installed $($fontFiles.Count) font files to $userFontDir"
            Write-Warn 'You may need to restart applications to see the new font.'
        }
        finally {
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ============================================================
# 3. Install Terminal-Icons PowerShell module
# ============================================================

Write-Step 'Checking Terminal-Icons module...'

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    $tiVersion = (Get-Module -ListAvailable -Name Terminal-Icons | Select-Object -First 1).Version
    Write-Skipped "Terminal-Icons already installed (v$tiVersion)"
} else {
    Write-Info 'Installing Terminal-Icons module...'
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
    Write-Info 'Terminal-Icons installed.'
}

# ============================================================
# 4. Install GitHub CLI + Copilot extension
# ============================================================

Write-Step 'Checking GitHub CLI installation...'

if (Get-Command gh -ErrorAction SilentlyContinue) {
    $ghVersion = (gh --version | Select-Object -First 1)
    Write-Skipped "GitHub CLI already installed ($ghVersion)"
} else {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn 'winget is not available. Skipping GitHub CLI installation.'
    } else {
        Write-Info 'Installing GitHub CLI via winget...'
        winget install --id GitHub.cli --exact --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "GitHub CLI installation failed (exit code $LASTEXITCODE). You can install it manually later."
        } else {
            # Refresh PATH for the current session
            $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
            $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
            $env:Path = "$machinePath;$userPath"
            Write-Info 'GitHub CLI installed.'
        }
    }
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Step 'Checking GitHub Copilot CLI extension...'

    $copilotInstalled = gh extension list 2>$null | Select-String 'gh-copilot'
    if ($copilotInstalled) {
        Write-Skipped 'gh-copilot extension already installed.'
    } else {
        # Check if the user is authenticated
        $authStatus = gh auth status 2>&1
        if ($authStatus -match 'Logged in') {
            Write-Info 'Installing gh-copilot extension...'
            gh extension install github/gh-copilot 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Info 'gh-copilot extension installed. Use ghcs (suggest) and ghce (explain) after loading profile.'
            } else {
                Write-Warn 'gh-copilot extension install failed. You can install it manually: gh extension install github/gh-copilot'
            }
        } else {
            Write-Warn 'GitHub CLI is not authenticated. Run "gh auth login" first, then:'
            Write-Info '  gh extension install github/gh-copilot'
        }
    }
} else {
    Write-Skipped 'GitHub CLI not available. Skipping Copilot extension setup.'
}

# ============================================================
# 5. Copy Starship configuration
# ============================================================

Write-Step 'Setting up Starship configuration...'

$starshipConfigDir = Join-Path $HOME '.config'
$starshipConfigFile = Join-Path $starshipConfigDir 'starship.toml'
$sourceStarship = Join-Path $repoRoot '.config\starship.toml'

if (-not (Test-Path $starshipConfigDir)) {
    New-Item -ItemType Directory -Path $starshipConfigDir -Force | Out-Null
}

if (Confirm-Overwrite $starshipConfigFile) {
    Copy-Item $sourceStarship $starshipConfigFile -Force
    Write-Info "Copied starship.toml -> $starshipConfigFile"
} else {
    Write-Skipped 'Starship config not overwritten.'
}

# ============================================================
# 6. Set up PowerShell profile
# ============================================================

Write-Step 'Setting up PowerShell profile...'

$sourceProfile = Join-Path $repoRoot 'PowerShell\Microsoft.PowerShell_profile.ps1'

# Determine the correct profile path. The $PROFILE path may point to OneDrive.
# We need to set up: (a) the local profile with our config, and (b) ensure the
# main profile sources it.

$documentsDir = [Environment]::GetFolderPath('MyDocuments')
$psDir = Join-Path $documentsDir 'PowerShell'
$mainProfilePath = Join-Path $psDir 'Microsoft.PowerShell_profile.ps1'
$isOneDrive = $documentsDir -like '*OneDrive*'

# If OneDrive is in play, the local profile goes to the non-OneDrive Documents
if ($isOneDrive) {
    $localPsDir = Join-Path $HOME 'Documents\PowerShell'
    $localProfilePath = Join-Path $localPsDir 'Microsoft.PowerShell_profile.ps1'

    Write-Info "OneDrive detected. Main profile: $mainProfilePath"
    Write-Info "Local profile target: $localProfilePath"

    # Ensure the local PowerShell directory exists
    if (-not (Test-Path $localPsDir)) {
        New-Item -ItemType Directory -Path $localPsDir -Force | Out-Null
    }

    # Copy our profile as the local profile
    if (Confirm-Overwrite $localProfilePath) {
        Copy-Item $sourceProfile $localProfilePath -Force
        Write-Info "Copied profile -> $localProfilePath"
    } else {
        Write-Skipped 'Local profile not overwritten.'
    }

    # Ensure the main (OneDrive) profile sources the local profile
    $sourcingBlock = @'

# If the local profile exists, source it to get the local profile settings
$localprofile = "$HOME\Documents\PowerShell\$($MyInvocation.MyCommand.Name)"
if (Test-Path -Path $localprofile) {
  . $localprofile
}
'@

    if (Test-Path $mainProfilePath) {
        $mainProfileContent = Get-Content $mainProfilePath -Raw
        if ($mainProfileContent -match 'localprofile') {
            Write-Skipped 'Main profile already sources the local profile.'
        } else {
            Write-Info 'Adding local profile sourcing to main profile...'
            Add-Content -Path $mainProfilePath -Value $sourcingBlock -Encoding UTF8NoBOM
            Write-Info "Updated: $mainProfilePath"
        }
    } else {
        # No main profile exists yet — create one with just the sourcing block
        if (-not (Test-Path $psDir)) {
            New-Item -ItemType Directory -Path $psDir -Force | Out-Null
        }
        Set-Content -Path $mainProfilePath -Value $sourcingBlock.TrimStart() -Encoding UTF8NoBOM
        Write-Info "Created main profile: $mainProfilePath"
    }
} else {
    # No OneDrive — just copy directly to the profile location
    Write-Info "Profile target: $mainProfilePath"

    if (-not (Test-Path $psDir)) {
        New-Item -ItemType Directory -Path $psDir -Force | Out-Null
    }

    if (Confirm-Overwrite $mainProfilePath) {
        Copy-Item $sourceProfile $mainProfilePath -Force
        Write-Info "Copied profile -> $mainProfilePath"
    } else {
        Write-Skipped 'Profile not overwritten.'
    }
}

# ============================================================
# 7. Configure Windows Terminal font (if settings file exists)
# ============================================================

Write-Step 'Checking Windows Terminal font settings...'

$nerdFont = 'CaskaydiaCove Nerd Font'

$wtSettingsPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

$wtSettingsPath = $wtSettingsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($wtSettingsPath) {
    $wtSettings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json -AsHashtable

    $currentFont = $null
    if ($wtSettings.ContainsKey('profiles') -and
        $wtSettings.profiles.ContainsKey('defaults') -and
        $wtSettings.profiles.defaults.ContainsKey('font') -and
        $wtSettings.profiles.defaults.font.ContainsKey('face')) {
        $currentFont = $wtSettings.profiles.defaults.font.face
    }

    if ($currentFont -match 'Nerd|CaskaydiaCove|Caskaydia') {
        Write-Skipped "Windows Terminal already using Nerd Font: $currentFont"
    } else {
        # Ensure the profiles.defaults.font path exists
        if (-not $wtSettings.ContainsKey('profiles')) {
            $wtSettings['profiles'] = @{}
        }
        if (-not $wtSettings.profiles.ContainsKey('defaults')) {
            $wtSettings.profiles['defaults'] = @{}
        }
        if (-not $wtSettings.profiles.defaults.ContainsKey('font')) {
            $wtSettings.profiles.defaults['font'] = @{}
        }
        $wtSettings.profiles.defaults.font['face'] = $nerdFont

        $wtSettings | ConvertTo-Json -Depth 20 | Set-Content $wtSettingsPath -Encoding UTF8NoBOM
        Write-Info "Set Windows Terminal default font to '$nerdFont'."
    }
} else {
    Write-Skipped 'Windows Terminal settings not found (not installed or using portable).'
}

# ============================================================
# 8. Configure VSCode terminal font
# ============================================================

Write-Step 'Checking VSCode terminal font settings...'

$vscodeSettingsPath = Join-Path $env:APPDATA 'Code\User\settings.json'

if (Test-Path $vscodeSettingsPath) {
    $vscodeSettings = Get-Content $vscodeSettingsPath -Raw | ConvertFrom-Json -AsHashtable
    $currentVscodeFont = $null
    if ($vscodeSettings.ContainsKey('terminal.integrated.fontFamily')) {
        $currentVscodeFont = $vscodeSettings['terminal.integrated.fontFamily']
    }

    if ($currentVscodeFont -match 'Nerd|CaskaydiaCove|Caskaydia') {
        Write-Skipped "VSCode terminal font already configured: $currentVscodeFont"
    } else {
        $vscodeSettings['terminal.integrated.fontFamily'] = "'$nerdFont'"
        $vscodeSettings | ConvertTo-Json -Depth 20 | Set-Content $vscodeSettingsPath -Encoding UTF8NoBOM
        Write-Info "Set VSCode terminal font to '$nerdFont'."
    }
} else {
    Write-Skipped 'VSCode settings.json not found.'
}

# ============================================================
# Done
# ============================================================

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host ''
Write-Host '  Next steps:' -ForegroundColor Cyan
Write-Host '  1. Open a new terminal to load the updated profile.'
Write-Host '  2. Run "starship explain" to verify the prompt modules.'
Write-Host '  3. Run "ghcs" to suggest commands or "ghce" to explain commands via Copilot.'
Write-Host ''
