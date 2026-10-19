param(
    [Parameter(Mandatory = $true)]
    [string]$Project,          # 例：examples/blinky
    [string]$Top = 'tb',       # testbench 顶层模块名
    [switch]$Open              # 跑完用 gtkwave 打开波形
)

# 仿真：iverilog 编译 + vvp 运行 + 可选看波形
#
# 用法：
#     . .\env.ps1
#     .\scripts\sim.ps1 -Project examples/blinky
#     .\scripts\sim.ps1 -Project examples/blinky -Open
#
# 约定：
#   - 被测设计放 $Project/rtl/*.v
#   - testbench 放 $Project/sim/tb_*.v，里面用 $dumpfile / $dumpvars 写 tb.vcd
#   - 产物落 $Project/build/tb.vvp 与 tb.vcd

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$proj = if ([System.IO.Path]::IsPathRooted($Project)) { $Project } else { Join-Path $repo $Project }
if (-not (Test-Path $proj)) { throw "找不到项目目录 $proj" }

# @() 不能省：只有一个文件时 Get-ChildItem 返回单个 FileInfo 而不是数组，
# 后面用 + 拼接会报 "does not contain a method named 'op_Addition'"
$design = @(Get-ChildItem -Path (Join-Path $proj 'rtl') -Filter '*.v' -ErrorAction SilentlyContinue)
if ($design.Count -eq 0) {
    $design = @(Get-ChildItem -Path $proj -Filter '*.v' -File -ErrorAction SilentlyContinue)
}
$tb = @(Get-ChildItem -Path (Join-Path $proj 'sim') -Filter 'tb_*.v' -ErrorAction SilentlyContinue)
if ($tb.Count -eq 0) { throw "$proj\sim\ 下没有 tb_*.v" }

$build = Join-Path $proj 'build'
New-Item -ItemType Directory -Path $build -Force | Out-Null
$vvp = Join-Path $build 'tb.vvp'

# 用数组 + @ 展开传给 iverilog。拼成一个字符串再传会被当成"一个文件名"，
# iverilog 会报 Invalid argument。（2026-10-18 踩过）
$files = @(($design + $tb) | ForEach-Object { $_.FullName })

Write-Host "`n[1/2] iverilog 编译  ($($files.Count) 个文件, top=$Top)" -ForegroundColor Cyan
& iverilog -g2012 -o $vvp @files
if ($LASTEXITCODE -ne 0) { throw "iverilog 编译失败，退出码 $LASTEXITCODE" }

Write-Host "[2/2] vvp 运行" -ForegroundColor Cyan
Push-Location $build
try {
    & vvp -n $vvp
    if ($LASTEXITCODE -ne 0) { throw "仿真运行失败，退出码 $LASTEXITCODE（检查 \$finish 有没有执行、有没有 \$stop）" }
}
finally { Pop-Location }

$vcd = Join-Path $build 'tb.vcd'
if (Test-Path $vcd) {
    Write-Host "波形：$vcd" -ForegroundColor Green
    if ($Open) { Start-Process gtkwave -ArgumentList $vcd }
}
else {
    Write-Host "没生成 tb.vcd —— testbench 里缺 \$dumpfile / \$dumpvars" -ForegroundColor Yellow
}
