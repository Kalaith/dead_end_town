<#
.SYNOPSIS
  Saves verification screenshots without touching the user's mouse, keyboard or focus.
.DESCRIPTION
  Runs a capture tour (default tools/capture.gd) in a real renderer with the window
  placed far off-screen. Input reaches the game as engine events, never OS input.
  --headless cannot be used: it has no renderer, so there is no image to save.
.EXAMPLE
  .\tools\Capture.ps1
  .\tools\Capture.ps1 -Tour res://tools/capture_other.gd
#>
param(
    [string]$Tour = 'res://tools/capture.gd'
)
$ErrorActionPreference = 'Stop'
$godot = Get-ChildItem -Path 'C:\Program Files\Godot' -Filter 'Godot_v4.7.*-stable_win64_console.exe' |
    Sort-Object { [version]($_.Name -replace '^Godot_v(\d+\.\d+(\.\d+)?)-.*', '$1') } -Descending | Select-Object -First 1
if (-not $godot) { throw 'Godot 4.7 console executable not found in C:\Program Files\Godot.' }
$project = Split-Path -Parent $PSScriptRoot
& $godot.FullName --path $project --position 10000,10000 --resolution 1920x1080 --script $Tour -- --no-save --size=1920x1080
exit $LASTEXITCODE
