# Put oss-cad-suite on PATH for the current PowerShell session.
#
# Usage (the leading dot is required, do not omit it):
#     . .\env.ps1
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
