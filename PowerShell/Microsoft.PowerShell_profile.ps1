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
Set-PSReadLineOption @PSReadLineOptions

# Ctrl+RightArrow accepts the next word from inline prediction
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord

# --- GitHub Copilot CLI ---
# ghcs: Copilot Suggest — suggests shell commands from natural language
# ghce: Copilot Explain — explains a command in plain English
# Requires: gh cli + gh-copilot extension (gh extension install github/gh-copilot)
if (Get-Command gh -ErrorAction SilentlyContinue) {
  function ghcs {
    param(
      [Parameter()]
      [string]$Hostname,

      [ValidateSet('gh', 'git', 'shell')]
      [Alias('t')]
      [string]$Target = 'shell',

      [Parameter(Position = 0, ValueFromRemainingArguments)]
      [string]$Prompt
    )
    begin {
      $executeCommandFile = New-TemporaryFile
      $envGhDebug = $Env:GH_DEBUG
      $envGhHost = $Env:GH_HOST
    }
    process {
      if ($PSBoundParameters['Debug']) { $Env:GH_DEBUG = 'api' }
      $Env:GH_HOST = $Hostname
      gh copilot suggest -t $Target -s "$executeCommandFile" $Prompt
    }
    end {
      if ($executeCommandFile.Length -gt 0) {
        $executeCommand = (Get-Content -Path $executeCommandFile -Raw).Trim()
        [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($executeCommand)
        $now = Get-Date
        $executeCommandHistoryItem = [PSCustomObject]@{
          CommandLine        = $executeCommand
          ExecutionStatus    = [Management.Automation.Runspaces.PipelineState]::NotStarted
          StartExecutionTime = $now
          EndExecutionTime   = $now.AddSeconds(1)
        }
        Add-History -InputObject $executeCommandHistoryItem
        Write-Host "`n"
        Invoke-Expression $executeCommand
      }
    }
    clean {
      Remove-Item -Path $executeCommandFile
      $Env:GH_DEBUG = $envGhDebug
    }
  }

  function ghce {
    param(
      [Parameter()]
      [string]$Hostname,

      [Parameter(Position = 0, ValueFromRemainingArguments)]
      [string[]]$Prompt
    )
    begin {
      $envGhDebug = $Env:GH_DEBUG
      $envGhHost = $Env:GH_HOST
    }
    process {
      if ($PSBoundParameters['Debug']) { $Env:GH_DEBUG = 'api' }
      $Env:GH_HOST = $Hostname
      gh copilot explain $Prompt
    }
    clean {
      $Env:GH_DEBUG = $envGhDebug
      $Env:GH_HOST = $envGhHost
    }
  }
}

# --- Starship ---
# Skip heavy prompt customization inside the PowerShell Extension Terminal (PSES)
# to prevent timeouts that crash the language service.
# Regular VSCode integrated terminals (ConsoleHost) still get Starship.
if ($Host.Name -ne 'Visual Studio Code Host') {
  Invoke-Expression (&starship init powershell)
}
