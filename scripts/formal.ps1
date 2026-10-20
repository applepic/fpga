param(
    [Parameter(Mandatory = $true)]
    [string]$Project,          # e.g. examples/04_formal
    [string]$Task = '',        # .sby file name inside $Project/formal; defaults to the only one found
    [switch]$Open,             # open the counterexample waveform in gtkwave when the proof fails
    [switch]$Clean             # delete the work directory and exit
)

# Formal proof: SymbiYosys (sby) driving yosys + an SMT solver.
#
# Usage:
#     . .\env.ps1
#     .\scripts\formal.ps1 -Project examples/04_formal
#     .\scripts\formal.ps1 -Project examples/04_formal -Open
#
# Conventions:
#   - Properties live in $Project/formal/props_*.v and are never synthesised into hardware
#   - The .sby task lives in $Project/formal/*.sby
#   - The design under test lives in $Project/rtl/*.v, exactly like the simulation exercises
#   - Artifacts go to $Project/build/formal/ (git-ignored, same rule as the other build output)
#
# Difference from sim.ps1, and the reason this is a separate script:
# simulation drives inputs you choose and checks outputs you thought to check.
# A proof lets the solver choose the inputs, and checks the property in every reachable state.
# A simulation can only ever show a bug you already suspected; a proof either holds for all
# input sequences or hands you a counterexample trace.

$ErrorActionPreference = 'Stop'

# Pre-flight failures are the normal starting state of an exercise (rtl/ is empty on purpose),
# so they print one readable line instead of a PowerShell stack trace.
function Fail([string]$Message) {
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

$repo = Split-Path -Parent $PSScriptRoot
$proj = if ([System.IO.Path]::IsPathRooted($Project)) { $Project } else { Join-Path $repo $Project }
if (-not (Test-Path $proj)) { Fail "Project directory not found: $proj" }

$build = Join-Path $proj 'build\formal'

if ($Clean) {
    if (Test-Path $build) {
        $resolved = (Resolve-Path $build).Path
        $expected = [System.IO.Path]::GetFullPath($build)
        if ($resolved -ne $expected) { Fail "Refusing to delete $resolved" }
        Remove-Item -LiteralPath $resolved -Recurse -Force
        Write-Host "Removed $resolved" -ForegroundColor Green
    }
    else { Write-Host "Nothing to clean: $build" -ForegroundColor Yellow }
    return
}

$formalDir = Join-Path $proj 'formal'
if (-not (Test-Path $formalDir)) { Fail "No formal directory: $formalDir" }

# Resolve the task file: an explicit -Task, or the single *.sby in the directory
if ([string]::IsNullOrWhiteSpace($Task)) {
    $tasks = @(Get-ChildItem -Path $formalDir -Filter '*.sby' -File)
    if ($tasks.Count -eq 0) { Fail "No *.sby task found under $formalDir" }
    if ($tasks.Count -gt 1) {
        Fail "More than one .sby task under $formalDir; pass -Task <name>.sby. Found: $(($tasks | ForEach-Object Name) -join ', ')"
    }
    $Task = $tasks[0].Name
}
$taskPath = Join-Path $formalDir $Task
if (-not (Test-Path $taskPath)) { Fail "Task file not found: $taskPath" }

# sby copies the [files] entries into its own src/ directory and runs yosys there, so relative
# paths inside the task are relative to the task file's own directory. Passing absolute paths is
# the least surprising option, and it is the only one that survives the build directory being
# somewhere else entirely. (Checked 2026-10-20: relative paths resolve against the .sby directory,
# not the repo root, which is not obvious from the documentation.)
$props = @(Get-ChildItem -Path $formalDir -Filter 'props_*.v' -File)
if ($props.Count -eq 0) { Fail "No props_*.v found under $formalDir" }

$rtlDir = Join-Path $proj 'rtl'
$rtl = @()
if (Test-Path $rtlDir) { $rtl = @(Get-ChildItem -Path $rtlDir -Filter '*.v' -File) }
if ($rtl.Count -eq 0) { Fail "rtl\ is empty: the design under test does not exist yet. That is the starting point of the exercise." }

New-Item -ItemType Directory -Path $build -Force | Out-Null

# Read [options] and [engines] verbatim from the task file so the exercise keeps control over
# proof depth and engine choice, then regenerate [script] and [files] with resolved paths.
$taskLines = Get-Content -Path $taskPath
$head = @()
$inHead = $true
foreach ($line in $taskLines) {
    if ($line -match '^\s*\[(script|files)\]') { $inHead = $false }
    elseif ($inHead) { $head += $line }
}

$generated = @()
$generated += $head
$generated += '[script]'
foreach ($f in $props) { $generated += "read -formal $($f.Name)" }
foreach ($f in $rtl)   { $generated += "read -formal $($f.Name)" }
$generated += 'prep -top formal_top'
$generated += ''
$generated += '[files]'
foreach ($f in $props) { $generated += $f.FullName }
foreach ($f in $rtl)   { $generated += $f.FullName }

$genPath = Join-Path $build 'generated.sby'
Set-Content -Path $genPath -Value ($generated -join "`r`n") -Encoding ascii

Write-Host "`n[1/2] sby prove  (task=$Task, depth from task file)" -ForegroundColor Cyan
Write-Host "      props: $(($props | ForEach-Object Name) -join ', ')"
Write-Host "      rtl  : $(($rtl | ForEach-Object Name) -join ', ')"

Push-Location $build
try {
    & sby -f generated.sby
    $rc = $LASTEXITCODE
}
finally { Pop-Location }

# sby exit codes: 0 = proof passed, 1 = error, 2 = property failed (counterexample produced),
# 4 = unknown (the solver could not decide within the depth limit)
Write-Host "`n[2/2] result" -ForegroundColor Cyan
switch ($rc) {
    0 { Write-Host "PASS: the property holds in every reachable state." -ForegroundColor Green }
    2 {
        Write-Host "FAIL: a counterexample exists." -ForegroundColor Red
        $vcd = Join-Path $build 'engine_0\trace.vcd'
        if (Test-Path $vcd) {
            Write-Host "Counterexample waveform: $vcd" -ForegroundColor Yellow
            if ($Open) { Start-Process gtkwave -ArgumentList $vcd }
        }
    }
    4 { Write-Host "UNKNOWN: the solver gave up inside the depth limit. This is not a pass." -ForegroundColor Yellow
        Write-Host "Usually the depth in the .sby file is too small for the state space. Increase it and rerun." }
    default { Write-Host "ERROR (rc=$rc). Read the sby output above." -ForegroundColor Red }
}

if ($rc -ne 0) { exit $rc }
