param(
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [switch]$Flash,                        # 不写则烧 SRAM（掉电即失，适合调试）
    [string]$Board = 'tangnano9k'
)

# 把 $Project/build/top.fs 烧进板子。
#
# 用法：
#     . .\env.ps1
#     .\scripts\flash.ps1 -Project examples/blinky          # SRAM，快，掉电丢
#     .\scripts\flash.ps1 -Project examples/blinky -Flash   # Flash，慢，掉电保留

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$proj = if ([System.IO.Path]::IsPathRooted($Project)) { $Project } else { Join-Path $repo $Project }
$fs = Join-Path $proj 'build\top.fs'
if (-not (Test-Path $fs)) { throw "找不到 $fs，先跑 scripts\build.ps1" }

Write-Host "先扫 USB，确认板子被认到：" -ForegroundColor Cyan
& openFPGALoader --scan-usb

$mode = if ($Flash) { '--write-flash' } else { '--write-sram' }
Write-Host "`n烧录 $fs  ($mode, board=$Board)" -ForegroundColor Cyan
& openFPGALoader -b $Board $mode $fs
if ($LASTEXITCODE -ne 0) {
    throw "openFPGALoader 失败，退出码 $LASTEXITCODE。先看 --scan-usb 有没有列出设备：没列出就是 USB 线/驱动/没插好的问题，不是 RTL 的问题"
}

Write-Host "烧录完成" -ForegroundColor Green
