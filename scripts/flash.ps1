param(
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [switch]$Flash,                        # omit to program SRAM (lost on power cycle, good for debugging)
    [string]$Board = 'tangnano9k'
)

# Program $Project/build/top.fs onto the board.
#
# Usage:
#     . .\env.ps1
#     .\scripts\flash.ps1 -Project examples/00_gates          # SRAM: fast, lost on power cycle
#     .\scripts\flash.ps1 -Project examples/00_gates -Flash   # Flash: slower, persists

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$proj = if ([System.IO.Path]::IsPathRooted($Project)) { $Project } else { Join-Path $repo $Project }
$fs = Join-Path $proj 'build\top.fs'
if (-not (Test-Path $fs)) { throw "Not found: $fs. Run scripts\build.ps1 first." }

Write-Host "Scanning USB to confirm the board is detected:" -ForegroundColor Cyan
& openFPGALoader --scan-usb

$mode = if ($Flash) { '--write-flash' } else { '--write-sram' }
Write-Host "`nProgramming $fs  ($mode, board=$Board)" -ForegroundColor Cyan
& openFPGALoader -b $Board $mode $fs
if ($LASTEXITCODE -ne 0) {
    throw "openFPGALoader failed, exit code $LASTEXITCODE. Check whether --scan-usb listed a device first. If it listed nothing, the problem is the USB cable, the driver, or a loose connection, not the RTL."
}

Write-Host "Programming complete" -ForegroundColor Green
