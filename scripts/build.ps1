param(
    [Parameter(Mandatory = $true)]
    [string]$Project,          # e.g. examples/00_gates
    [string]$Top = 'top',      # top module name
    [string]$Cst = '',         # constraint file; defaults to $Project/board.cst, then the shared one
    [string]$Device = 'GW1NR-LV9QN88PC6/I5',
    [string]$Family = 'GW1N-9C',
    [int]$Freq = 27            # MHz, target frequency
)

# Full build: Verilog -> synthesis -> place and route -> bitstream
#
# Usage:
#     . .\env.ps1
#     .\scripts\build.ps1 -Project examples/00_gates
#
# Artifacts land in $Project/build/: synth.json / pnr.json / top.fs / timing.rpt

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$proj = if ([System.IO.Path]::IsPathRooted($Project)) { $Project } else { Join-Path $repo $Project }
if (-not (Test-Path $proj)) { throw "Project directory not found: $proj" }

# Constraint priority: -Cst argument > $Project/board.cst > the shared constraints/tangnano9k.cst
# The shared file describes the whole board; nextpnr ignores ports the design does not use,
# so it can be reused directly.
if ([string]::IsNullOrWhiteSpace($Cst)) {
    $own = Join-Path $proj 'board.cst'
    $Cst = if (Test-Path $own) { $own } else { Join-Path $repo 'constraints\tangnano9k.cst' }
}
if (-not (Test-Path $Cst)) { throw "Constraint file not found: $Cst" }

$rtl = @(Get-ChildItem -Path (Join-Path $proj 'rtl') -Filter '*.v' -ErrorAction SilentlyContinue)
if ($rtl.Count -eq 0) {
    $rtl = @(Get-ChildItem -Path $proj -Filter '*.v' -File -ErrorAction SilentlyContinue)
}
if ($rtl.Count -eq 0) { throw "No .v files found under $proj" }

$build = Join-Path $proj 'build'
New-Item -ItemType Directory -Path $build -Force | Out-Null
$synthJson = Join-Path $build 'synth.json'
$pnrJson = Join-Path $build 'pnr.json'
$fs = Join-Path $build 'top.fs'
$rpt = Join-Path $build 'timing.rpt'

# yosys takes its file list inside the -p script string, so quote each path individually.
# That keeps paths containing spaces from being split into two filenames.
$files = ($rtl | ForEach-Object { '"' + ($_.FullName -replace '\\', '/') + '"' }) -join ' '

Write-Host "`n[1/4] yosys synthesis  ($($rtl.Count) source files, top=$Top)" -ForegroundColor Cyan
$yosysScript = "read_verilog $files; synth_gowin -top $Top -json `"$synthJson`""
& yosys -q -p $yosysScript
if ($LASTEXITCODE -ne 0) { throw "yosys failed, exit code $LASTEXITCODE" }

Write-Host "[2/4] nextpnr place and route  (device=$Device, freq=$Freq MHz)" -ForegroundColor Cyan
# nextpnr dumps hundreds of Info lines to stderr, which scrolls the real error off the screen.
# Only ERROR / Warning / the final Fmax line are shown here; the full log goes to build/nextpnr.log.
# Match only "Max frequency for clock": every Slack histogram line is followed by a source path,
# so including them floods the output.
$pnrLog = Join-Path $build 'nextpnr.log'
& nextpnr-himbaechel --device $Device --json $synthJson --write $pnrJson `
    --vopt cst=$Cst --vopt family=$Family --freq $Freq --report $rpt 2>&1 |
    Tee-Object -FilePath $pnrLog |
    Where-Object { $_ -match 'ERROR|^Warning|Max frequency for clock' } |
    ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n--- tail of nextpnr log ---" -ForegroundColor Red
    Get-Content $pnrLog -Tail 20 | Write-Host
    throw "nextpnr failed, exit code $LASTEXITCODE. Full log: $pnrLog"
}

Write-Host "[3/4] gowin_pack bitstream" -ForegroundColor Cyan
& gowin_pack -d $Device -o $fs $pnrJson 2>&1 | Where-Object { $_ -notmatch 'UserWarning|warnings.warn' }
if ($LASTEXITCODE -ne 0) { throw "gowin_pack failed, exit code $LASTEXITCODE" }

Write-Host "[4/4] utilisation and timing" -ForegroundColor Cyan
# --report writes JSON, not a text report (verified 2026-10-18)
$report = Get-Content $rpt -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
if ($report) {
    $interesting = 'LUT4', 'DFF', 'BSRAM', 'IOB', 'MULT18X18', 'rPLL', 'BUFG'
    foreach ($k in $interesting) {
        $u = $report.utilization.$k
        if ($u -and $u.used -gt 0) {
            $pct = 100.0 * $u.used / $u.available
            Write-Host ("  {0,-10} {1,6} / {2,-6} {3,5:N1}%" -f $k, $u.used, $u.available, $pct)
        }
    }
    $fmax = $report.fmax
    if ($fmax -and $fmax.PSObject.Properties.Count -gt 0) {
        foreach ($clk in $fmax.PSObject.Properties) {
            # Each clock maps to { achieved, constraint }, not a bare number (verified 2026-10-18)
            $achieved = $clk.Value.achieved
            if ($null -eq $achieved) { continue }
            $target = if ($null -ne $clk.Value.constraint) { $clk.Value.constraint } else { $Freq }
            $ok = $achieved -ge $target
            $color = if ($ok) { 'Green' } else { 'Red' }
            Write-Host ("  Fmax {0} = {1:N2} MHz (target {2} MHz)" -f $clk.Name, $achieved, $target) -ForegroundColor $color
            if (-not $ok) { Write-Host "  Timing not met. Lower -Freq or change the design." -ForegroundColor Red }
        }
    }
    else {
        Write-Host "  No internal timing paths (combinational or empty design), so no Fmax to report" -ForegroundColor DarkGray
    }
}

Write-Host "Done: $fs" -ForegroundColor Green
Write-Host "Program SRAM (lost on power cycle): .\scripts\flash.ps1 -Project $Project" -ForegroundColor DarkGray
Write-Host "Program Flash (persists):           .\scripts\flash.ps1 -Project $Project -Flash" -ForegroundColor DarkGray
