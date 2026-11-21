[CmdletBinding()]
param(
    [string]$WorkshopFolder,
    [string]$GameFolder,
    [string]$PythonPath,
    [long]$ItemId = 0,
    [string]$ChangeNote,
    [switch]$Upload
)
$ErrorActionPreference = 'Stop'
$settingsPath = Join-Path $PSScriptRoot 'WorkshopUpload.local.json'
$settings = if (Test-Path -LiteralPath $settingsPath) { Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
if (-not $WorkshopFolder -and $settings) { $WorkshopFolder = $settings.WorkshopFolder }
if (-not $GameFolder -and $settings) { $GameFolder = $settings.GameFolder }
if (-not $PythonPath -and $settings) { $PythonPath = $settings.PythonPath }
if (-not $PythonPath) { $PythonPath = 'python' }
if (-not $WorkshopFolder) { throw 'Provide -WorkshopFolder for the item folder containing Contents and workshop.txt.' }
$uploadArguments = @((Join-Path $PSScriptRoot 'Upload-WorkshopContent.py'), '--workshop-folder', $WorkshopFolder)
if ($GameFolder) { $uploadArguments += @('--game-folder', $GameFolder) }
if ($ItemId -gt 0) { $uploadArguments += @('--item-id', [string]$ItemId) }
if ($ChangeNote) { $uploadArguments += @('--change-note', $ChangeNote) }
if ($Upload) { $uploadArguments += '--upload' }
& $PythonPath @uploadArguments
if ($LASTEXITCODE -ne 0) { throw 'Workshop content upload or validation failed.' }
