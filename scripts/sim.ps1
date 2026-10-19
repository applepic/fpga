param(
    [Parameter(Mandatory = $true)]
    [string]$Project,          # e.g. examples/00_gates
    [string]$Top = 'tb',       # testbench top module name
    [switch]$Open              # open the waveform in gtkwave when done
)

# Simulation: iverilog compile, vvp run, optionally view the waveform
#
# Usage:
#     . .\env.ps1
#     .\scripts\sim.ps1 -Project examples/00_gates
#     .\scripts\sim.ps1 -Project examples/00_gates -Open
#
# Conventions:
#   - Design files live in $Project/rtl/*.v
#   - Testbenches live in $Project/sim/tb_*.v and use $dumpfile / $dumpvars to write tb.vcd
#   - Artifacts go to $Project/build/tb.vvp and tb.vcd

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$proj = if ([System.IO.Path]::IsPathRooted($Project)) { $Project } else { Join-Path $repo $Project }
if (-not (Test-Path $proj)) { throw "Project directory not found: $proj" }

# @() is not optional: with a single file Get-ChildItem returns one FileInfo instead of an array,
# and concatenating with + then fails with "does not contain a method named 'op_Addition'"
$design = @(Get-ChildItem -Path (Join-Path $proj 'rtl') -Filter '*.v' -ErrorAction SilentlyContinue)
if ($design.Count -eq 0) {
    $design = @(Get-ChildItem -Path $proj -Filter '*.v' -File -ErrorAction SilentlyContinue)
}
$tb = @(Get-ChildItem -Path (Join-Path $proj 'sim') -Filter 'tb_*.v' -ErrorAction SilentlyContinue)
if ($tb.Count -eq 0) { throw "No tb_*.v found under $proj\sim\" }

$build = Join-Path $proj 'build'
New-Item -ItemType Directory -Path $build -Force | Out-Null
$vvp = Join-Path $build 'tb.vvp'

# Pass an array with @ splatting. Joining into one string makes iverilog treat it as a single
# filename and report "Invalid argument". (Hit on 2026-10-18)
$files = @(($design + $tb) | ForEach-Object { $_.FullName })

Write-Host "`n[1/2] iverilog compile  ($($files.Count) files, top=$Top)" -ForegroundColor Cyan
& iverilog -g2012 -o $vvp @files
if ($LASTEXITCODE -ne 0) { throw "iverilog compile failed, exit code $LASTEXITCODE" }

Write-Host "[2/2] vvp run" -ForegroundColor Cyan
Push-Location $build
try {
    & vvp -n $vvp
    if ($LASTEXITCODE -ne 0) { throw "Simulation failed, exit code $LASTEXITCODE (check whether \$finish ran and whether there is a stray \$stop)" }
}
finally { Pop-Location }

$vcd = Join-Path $build 'tb.vcd'
if (Test-Path $vcd) {
    Write-Host "Waveform: $vcd" -ForegroundColor Green
    if ($Open) { Start-Process gtkwave -ArgumentList $vcd }
}
else {
    Write-Host "No tb.vcd produced. The testbench is missing \$dumpfile / \$dumpvars." -ForegroundColor Yellow
}
