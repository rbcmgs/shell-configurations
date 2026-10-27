# --- Terminal-Icons ---
# Adds file/folder icons to Get-ChildItem output (requires Nerd Font)
if (Get-Module -ListAvailable -Name Terminal-Icons) {
  Import-Module -Name Terminal-Icons
}

# --- PSReadLine ---
# Predictive IntelliSense, syntax coloring, and history-based autocomplete
$PSReadLineOptions = @{
  PredictionSource    = 'HistoryAndPlugin'
  PredictionViewStyle = 'ListView'
  EditMode            = 'Windows'
  Colors = @{
    Command            = '#a8e6a3'
    Parameter          = '#b2dfdb'
    Operator           = '#66bb6a'
    Variable           = '#c5e1a5'
    String             = '#fff59d'
    Number             = '#b2dfdb'
    Type               = '#a8e6a3'
    Comment            = '#4a7c59'
    Keyword            = '#66bb6a'
    Error              = '#ef9a9a'
    InlinePrediction   = '#4a7c59'
    ListPrediction     = '#a8e6a3'
    ListPredictionSelected = '#66bb6a'
  }
}
try { Set-PSReadLineOption @PSReadLineOptions } catch { Write-Verbose "PSReadLine prediction unavailable: $_" }
Set-PSReadLineOption -HistoryNoDuplicates -HistorySearchCursorMovesToEnd -MaximumHistoryCount 10000
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Ctrl+RightArrow accepts the next word from inline prediction
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord

# --- GitHub Copilot CLI completion (PowerShell) ---
# Copilot does not currently ship a native PowerShell completion script,
# so we provide a lightweight argument completer for the most-used commands.
if (Get-Command copilot -ErrorAction SilentlyContinue) {
  $copilotTopLevelCommands = @(
    'app', 'login', 'help', 'init', 'config', 'update', 'version',
    'workflow', 'sessions', 'memories', 'plugin', 'mcp', 'skill',
    'instruction', 'lsp', 'sandbox', 'completion'
  )

  $copilotGlobalOptions = @(
    '-h', '--help',
    '-v', '--version',
    '-i', '--interactive',
    '-p', '--prompt',
    '-s', '--silent',
    '-r', '--resume',
    '-n', '--name',
    '--continue',
    '--model',
    '--allow-all-tools', '--allow-all-paths', '--allow-all-urls', '--allow-all', '--yolo'
  )

  Register-ArgumentCompleter -Native -CommandName copilot -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $tokens = @($commandAst.CommandElements | Select-Object -Skip 1 | ForEach-Object { $_.Extent.Text })
    $firstToken = if ($tokens.Count -ge 1) { $tokens[0] } else { '' }

    $candidates = @()

    if ($firstToken -eq 'completion') {
      $candidates = @('bash', 'zsh', 'fish')
    } elseif ($wordToComplete -like '-*') {
      $candidates = $copilotGlobalOptions
    } else {
      $candidates = $copilotTopLevelCommands
    }

    $candidates |
      Where-Object { $_ -like "$wordToComplete*" } |
      Sort-Object -Unique |
      ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
      }
  }
}

# --- Starship ---
# Initialised last so it wraps earlier prompt customisations.
# Skipped in the PowerShell Extension terminal (PSES) to avoid language-service timeouts;
# Windows Terminal and regular VS Code terminals (ConsoleHost) get Starship, and
# VS Code shell integration composes with it automatically.
# Also skipped inside Claude Code's shell (CLAUDECODE is set) to keep agent output clean.
if ($Host.Name -ne 'Visual Studio Code Host' -and -not $env:CLAUDECODE -and (Get-Command starship -ErrorAction SilentlyContinue)) {
  if (-not $env:STARSHIP_CONFIG) {
    $env:STARSHIP_CONFIG = Join-Path $HOME '.config\starship.toml'
  }

  # Keep the terminal tab title in sync with the current directory
  function Invoke-Starship-PreCommand {
    $Host.UI.RawUI.WindowTitle = "$(Split-Path -Leaf (Get-Location))"
  }

  # Cache the generated init script (keyed on the starship binary) to avoid
  # spawning starship twice on every shell start.
  $starshipExe = (Get-Command starship).Source
  $starshipStamp = (Get-Item $starshipExe).LastWriteTimeUtc.Ticks
  $starshipCache = Join-Path ([IO.Path]::GetTempPath()) "starship-init-$starshipStamp.ps1"
  if (-not (Test-Path $starshipCache)) {
    Get-ChildItem ([IO.Path]::GetTempPath()) -Filter 'starship-init-*.ps1' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    & $starshipExe init powershell --print-full-init | Out-File $starshipCache -Encoding utf8
  }
  . $starshipCache

  # Collapse previous prompts to a single character to keep scrollback clean
  function Invoke-Starship-TransientFunction { &starship module character }
  Enable-TransientPrompt
}

# --- Machine-specific overrides (not tracked in git) ---
$localOverrides = Join-Path (Split-Path $PROFILE) 'profile.local.ps1'
if (Test-Path $localOverrides) { . $localOverrides }
