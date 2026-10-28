# Put oss-cad-suite on PATH for the current PowerShell session.
#
# Usage (both forms work; the leading dot is recommended):
#     . .\env.ps1
#     .\env.ps1
#
# Why the dot is still recommended (measured 2026-10-28):
#   $env:PATH is an *environment* variable, so it survives a script's own scope and the
#   no-dot form does put the toolchain on PATH. What the dot additionally changes is
#   $ErrorActionPreference below: without the dot it stays inside the script's scope, so
#   `yosys -V` failing would print an error and carry on; with the dot it becomes 'Stop'
#   in your session, so a broken tool fails loudly. That is the whole difference.
#
#   The earlier version of this comment said the dot was required, or the toolchain would
#   not be on PATH. That was wrong and was corrected on 2026-10-28 after measuring it:
#   with a PATH containing no oss-cad-suite, `.\env.ps1` (no dot) still leaves `yosys -V`
#   working and exiting 0.
#
# Why this file exists: the oss-cad-suite executables depend on DLLs in the sibling lib\ directory.
# If only bin\ is on PATH, yosys / nextpnr / openFPGALoader crash immediately with exit code
# -1073741515 (0xC0000135, STATUS_DLL_NOT_FOUND) and print nothing at all.
# iverilog happens not to need those DLLs, so it runs fine and misleads you into thinking
# the toolchain is healthy.

$ErrorActionPreference = 'Stop'

$root = 'C:\Local_Data\oss-cad-suite'
if (-not (Test-Path $root)) {
    throw "Toolchain directory not found: $root"
}

# Same order as the official environment.ps1: bin first, lib after
$env:PATH = "$root\bin;$root\lib;" + $env:PATH

$env:OPENFPGALOADER_SOJ_DIR = "$root\share\openFPGALoader"
$env:SSL_CERT_FILE = "$root\etc\cacert.pem"

# Self-check: all four must be able to report a version
$missing = @()
foreach ($t in 'iverilog', 'yosys', 'nextpnr-himbaechel', 'openFPGALoader') {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { $missing += $t }
}
if ($missing.Count -gt 0) {
    throw "Toolchain incomplete, missing: $($missing -join ', ')"
}

Write-Host "oss-cad-suite ready ($root)" -ForegroundColor Green
