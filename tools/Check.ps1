<#
.SYNOPSIS
  Runs every headless check: script loading, the editor import, then each tools/checks/check_*.gd.
.DESCRIPTION
  Each check is its own SceneTree script, so each runs in its own headless Godot. A check fails on a non-zero
  exit, a FAIL line or a SCRIPT ERROR. Prints one line per check and a summary; exits 1 when anything failed.
  Nothing opens a window or touches input.
.EXAMPLE
  .\tools\Check.ps1
  .\tools\Check.ps1 -Only save,travel      # checks whose name contains one of these
  .\tools\Check.ps1 -Bot                   # also run the scripted run to the ending (a few minutes)
#>
param(
    [string[]]$Only = @(),
    [switch]$Bot
)
$ErrorActionPreference = 'Stop'
$godot = Get-ChildItem -Path 'C:\Program Files\Godot' -Filter 'Godot_v4.7.*-stable_win64_console.exe' |
    Sort-Object { [version]($_.Name -replace '^Godot_v(\d+\.\d+(\.\d+)?)-.*', '$1') } -Descending | Select-Object -First 1
if (-not $godot) { throw 'Godot 4.7 console executable not found in C:\Program Files\Godot.' }
$project = Split-Path -Parent $PSScriptRoot
$failed = @()

function Invoke-Check([string]$Name, [string[]]$Arguments) {
    $started = Get-Date
    $output = & $godot.FullName @Arguments 2>&1 | Out-String
    $code = $LASTEXITCODE
    $seconds = ((Get-Date) - $started).TotalSeconds
    $bad = $code -ne 0 -or $output -match '(?m)^FAIL' -or $output -match 'SCRIPT ERROR'
    $label = if ($bad) { 'FAIL' } else { 'ok  ' }
    Write-Host ('{0} {1} ({2:N0}s)' -f $label, $Name, $seconds)
    if ($bad) {
        ($output -split "`n" | Where-Object { $_ -match '^FAIL|SCRIPT ERROR|^\s+at:' } | Select-Object -First 8) | ForEach-Object { Write-Host "     $_" }
        $script:failed += $Name
    }
}

if ($Only.Count -eq 0) {
    Invoke-Check 'parse_all' @('--headless', '--path', $project, '--script', 'res://tools/parse_all.gd')
    Invoke-Check 'editor import' @('--headless', '--editor', '--path', $project, '--quit')
}
foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot 'checks') -Filter 'check_*.gd' | Sort-Object Name) {
    $name = $file.BaseName
    if ($Only.Count -gt 0 -and -not ($Only | Where-Object { $name -like "*$_*" })) { continue }
    Invoke-Check $name @('--headless', '--path', $project, '--script', "res://tools/checks/$($file.Name)")
}
if ($Bot) {
    Invoke-Check 'bot_ending' @('--headless', '--path', $project, '--script', 'res://tools/bot_ending.gd')
}
if ($failed.Count -gt 0) {
    Write-Host ("{0} failed: {1}" -f $failed.Count, ($failed -join ', '))
    exit 1
}
Write-Host 'All checks passed.'
exit 0
