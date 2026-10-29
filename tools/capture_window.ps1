<#
.SYNOPSIS
  Looks at the running game: sends real mouse/keyboard input to its window and saves a screenshot.
.DESCRIPTION
  A direct-inspection helper, not a test or a tour. Launch the game yourself first
  (Run.ps1, or the Godot exe with --path . --windowed), then run this once per look.
  Coordinates are pixels inside the captured window image.
.EXAMPLE
  .\tools\capture_window.ps1 -Out docs\verification\street.png
  .\tools\capture_window.ps1 -Out docs\verification\town_map.png -Keys Escape:80 -Click '819,216'
#>
param(
    [Parameter(Mandatory)][string]$Out,
    [string]$Click = '',      # "x,y;x,y" left clicks, in order, before keys
    [string]$Keys = '',       # "Name:holdMs,Name:holdMs" using System.Windows.Forms.Keys names
    [int]$Wait = 600          # settle time in ms before the capture
)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @'
using System; using System.Runtime.InteropServices;
public class GameWindow {
  public struct Rect { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int ht, uint flags);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out Rect r);
  [DllImport("user32.dll")] public static extern void keybd_event(byte key, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint x, uint y, uint data, UIntPtr extra);
}
'@
$game = Get-Process | Where-Object { $_.ProcessName -like 'Godot*' -and $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -like '*Dead End*' } | Select-Object -First 1
if (-not $game) { throw 'Dead End Town is not running. Launch it first.' }
$handle = $game.MainWindowHandle
# Topmost for the capture only, otherwise another window can be photographed instead.
[GameWindow]::ShowWindow($handle, 9) | Out-Null
[GameWindow]::SetWindowPos($handle, [IntPtr](-1), 0, 0, 0, 0, 0x43) | Out-Null
[GameWindow]::SetForegroundWindow($handle) | Out-Null
Start-Sleep -Milliseconds 300
$rect = New-Object GameWindow+Rect
[GameWindow]::GetWindowRect($handle, [ref]$rect) | Out-Null
foreach ($point in ($Click -split ';' | Where-Object { $_ })) {
    $x, $y = $point -split ','
    [GameWindow]::SetCursorPos($rect.Left + [int]$x, $rect.Top + [int]$y) | Out-Null
    Start-Sleep -Milliseconds 200
    [GameWindow]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 80
    [GameWindow]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 400
}
foreach ($spec in ($Keys -split ',' | Where-Object { $_ })) {
    $name, $hold = $spec -split ':'
    $code = [byte][int][System.Windows.Forms.Keys]::$name
    # Godot reads physical keys, so send the hardware scan code as well as the virtual key.
    $scan = [byte][GameWindow]::MapVirtualKey($code, 0)
    [GameWindow]::keybd_event($code, $scan, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds ([int]$hold)
    [GameWindow]::keybd_event($code, $scan, 2, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 150
}
Start-Sleep -Milliseconds $Wait
[GameWindow]::GetWindowRect($handle, [ref]$rect) | Out-Null
$bitmap = New-Object System.Drawing.Bitmap ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top)
[System.Drawing.Graphics]::FromImage($bitmap).CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
$full = if ([System.IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Get-Location).Path $Out }
$bitmap.Save($full)
[GameWindow]::SetWindowPos($handle, [IntPtr](-2), 0, 0, 0, 0, 0x43) | Out-Null
"Saved $full ($($bitmap.Width)x$($bitmap.Height))"
