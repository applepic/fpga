param(
    [Parameter(Mandatory = $true)]
    [string]$Project,          # 例：examples/blinky
    [string]$Top = 'top',      # 顶层模块名
    [string]$Cst = '',         # 约束文件；留空则用 $Project/board.cst
    [string]$Device = 'GW1NR-LV9QN88PC6/I5',
    [string]$Family = 'GW1N-9C',
    [int]$Freq = 27            # MHz，目标频率
)

# 一次完整构建：Verilog -> 综合 -> 布局布线 -> 比特流
#
# 用法：
#     . .\env.ps1
#     .\scripts\build.ps1 -Project examples/blinky
#
# 产物落在 $Project/build/：synth.json / pnr.json / top.fs / timing.rpt

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$proj = if ([System.IO.Path]::IsPathRooted($Project)) { $Project } else { Join-Path $repo $Project }
if (-not (Test-Path $proj)) { throw "找不到项目目录 $proj" }

# 约束文件优先级：-Cst 参数 > $Project/board.cst > 仓库共享的 constraints/tangnano9k.cst
# 共享那份写的是整块板子的引脚，nextpnr 会忽略设计里没用到的端口，所以可以直接复用。
if ([string]::IsNullOrWhiteSpace($Cst)) {
    $own = Join-Path $proj 'board.cst'
    $Cst = if (Test-Path $own) { $own } else { Join-Path $repo 'constraints\tangnano9k.cst' }
}
if (-not (Test-Path $Cst)) { throw "找不到约束文件 $Cst" }

$rtl = @(Get-ChildItem -Path (Join-Path $proj 'rtl') -Filter '*.v' -ErrorAction SilentlyContinue)
if ($rtl.Count -eq 0) {
    $rtl = @(Get-ChildItem -Path $proj -Filter '*.v' -File -ErrorAction SilentlyContinue)
}
if ($rtl.Count -eq 0) { throw "$proj 下没有 .v 文件" }

$build = Join-Path $proj 'build'
New-Item -ItemType Directory -Path $build -Force | Out-Null
$synthJson = Join-Path $build 'synth.json'
$pnrJson = Join-Path $build 'pnr.json'
$fs = Join-Path $build 'top.fs'
$rpt = Join-Path $build 'timing.rpt'

# yosys 的文件列表要拼进 -p 的脚本字符串里，所以逐个加引号，
# 路径带空格时也不会被拆成两个文件
$files = ($rtl | ForEach-Object { '"' + ($_.FullName -replace '\\', '/') + '"' }) -join ' '

Write-Host "`n[1/4] yosys 综合  ($($rtl.Count) 个源文件, top=$Top)" -ForegroundColor Cyan
$yosysScript = "read_verilog $files; synth_gowin -top $Top -json `"$synthJson`""
& yosys -q -p $yosysScript
if ($LASTEXITCODE -ne 0) { throw "yosys 失败，退出码 $LASTEXITCODE" }

Write-Host "[2/4] nextpnr 布局布线  (device=$Device, freq=$Freq MHz)" -ForegroundColor Cyan
# nextpnr 往 stderr 刷几百行 Info，全屏滚过去会盖住真正的错误。
# 这里只留 ERROR / Warning / 最终 Fmax 行，完整日志写进 build/nextpnr.log。
# 注意只匹配 "Max frequency for clock" 这一种：Slack histogram 的每行后面
# 都跟着一串源码路径，一起放出来会刷屏。
$pnrLog = Join-Path $build 'nextpnr.log'
& nextpnr-himbaechel --device $Device --json $synthJson --write $pnrJson `
    --vopt cst=$Cst --vopt family=$Family --freq $Freq --report $rpt 2>&1 |
    Tee-Object -FilePath $pnrLog |
    Where-Object { $_ -match 'ERROR|^Warning|Max frequency for clock' } |
    ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n--- nextpnr 日志末尾 ---" -ForegroundColor Red
    Get-Content $pnrLog -Tail 20 | Write-Host
    throw "nextpnr 失败，退出码 $LASTEXITCODE。完整日志：$pnrLog"
}

Write-Host "[3/4] gowin_pack 生成比特流" -ForegroundColor Cyan
& gowin_pack -d $Device -o $fs $pnrJson 2>&1 | Where-Object { $_ -notmatch 'UserWarning|warnings.warn' }
if ($LASTEXITCODE -ne 0) { throw "gowin_pack 失败，退出码 $LASTEXITCODE" }

Write-Host "[4/4] 资源占用与时序" -ForegroundColor Cyan
# --report 写出的是 JSON，不是文本报告（2026-10-18 核实）
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
            # 每个时钟的值是 { achieved, constraint }，不是裸数字（2026-10-18 核实）
            $achieved = $clk.Value.achieved
            if ($null -eq $achieved) { continue }
            $target = if ($null -ne $clk.Value.constraint) { $clk.Value.constraint } else { $Freq }
            $ok = $achieved -ge $target
            $color = if ($ok) { 'Green' } else { 'Red' }
            Write-Host ("  Fmax {0} = {1:N2} MHz (目标 {2} MHz)" -f $clk.Name, $achieved, $target) -ForegroundColor $color
            if (-not $ok) { Write-Host "  时序不满足，先降 Freq 或改设计" -ForegroundColor Red }
        }
    }
    else {
        Write-Host "  没有内部时序路径（纯组合逻辑或空设计），无 Fmax 可报" -ForegroundColor DarkGray
    }
}

Write-Host "完成：$fs" -ForegroundColor Green
Write-Host "烧录（SRAM，断电即失）：.\scripts\flash.ps1 -Project $Project" -ForegroundColor DarkGray
Write-Host "烧录（Flash，掉电保留）：.\scripts\flash.ps1 -Project $Project -Flash" -ForegroundColor DarkGray
