param(
    [string]$Lessons = 'lessons',   # folder holding the lesson .md files
    [string[]]$Files               # optional: check only these files instead of the whole folder
)

# Lint the answer-callout shape in lesson files.
#
# Usage:
#     .\scripts\lint-lessons.ps1
#     .\scripts\lint-lessons.ps1 -Files lessons\tutorial_01_wires.md
#
# Why this exists: on 2026-11-01 five answers were written with the body flush against
# `> **回答**`, while both reference lessons put a bare `>` after that label. The rule was
# written down but nothing checked it, so it was only caught when he compared the files
# himself. The checks below are the measured convention, not a preference:
#
#   原话 / 整理  take their text on the line directly below the label   (0 blank lines, always)
#   回答        takes a bare `>` line first, then the body              (blank line, always)
#
# Exit code 0 = clean, 1 = at least one violation.

$ErrorActionPreference = 'Stop'

if ($Files) {
    $targets = $Files | ForEach-Object { Get-Item $_ }
} else {
    $targets = Get-ChildItem -Path $Lessons -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' }
}

$violations = New-Object System.Collections.Generic.List[string]
$checked = 0

foreach ($f in $targets) {
    $lines = Get-Content -LiteralPath $f.FullName
    $checked++
    $label = $f.FullName

    # Track fenced blocks: an example of the shape inside ``` fences is documentation, not a
    # callout, so the line checks below must skip it.
    $inFence = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $next = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { '' }
        $nextIsBlankQuote = $next -match '^\s*>\s*$'

        if ($line -match '^\s*(>\s*)?```') {
            $inFence = -not $inFence
            continue
        }
        if ($inFence) { continue }

        # 回答 must be followed by a bare `>` line.
        if ($line -match '^\s*>\s*\*\*回答\*\*\s*$') {
            if (-not $nextIsBlankQuote) {
                $violations.Add("${label}:$($i + 1)  '> **回答**' is followed by the body; it needs a bare '>' line first")
            }
        }

        # 原话 and 整理 must NOT be followed by a bare `>` line.
        if ($line -match '^\s*>\s*\*\*(原话|整理)\*\*\s*$') {
            if ($nextIsBlankQuote) {
                $violations.Add("${label}:$($i + 1)  '> **$($Matches[1])**' has a blank '>' line after it; the text belongs on the next line")
            }
        }

        # A folded callout needs a blank line before it, or the previous paragraph is swallowed.
        if ($line -match '^> \[!') {
            $prev = if ($i -gt 0) { $lines[$i - 1] } else { '' }
            if ($prev -ne '') {
                $violations.Add("${label}:$($i + 1)  callout has no blank line above it")
            }
        }

        # A quoted table directly under a real table renders as broken text in Obsidian.
        if ($line -match '^\|' -and $next -match '^> \|') {
            $violations.Add("${label}:$($i + 2)  quoted table sits directly under a real table")
        }

        # A table row followed by a non-blank, non-table line ends the table mid-block.
        if ($line -match '^\|' -and $next -ne '' -and $next -notmatch '^\|') {
            $violations.Add("${label}:$($i + 2)  table row followed by a non-table line")
        }
    }

    # Fences must pair up, or everything after the stray one renders as code.
    $fences = @($lines | Where-Object { $_ -match '^\s*(>\s*)?```' }).Count
    if ($fences % 2 -ne 0) {
        $violations.Add("${label}  odd number of code fences ($fences); one is unclosed")
    }
}

Write-Host "Checked $checked lesson file(s)."
if ($violations.Count -eq 0) {
    Write-Host 'Callout shape OK.' -ForegroundColor Green
    exit 0
}

Write-Host "$($violations.Count) violation(s):" -ForegroundColor Red
$violations | ForEach-Object { Write-Host "  $_" }
exit 1
