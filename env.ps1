# 把 oss-cad-suite 挂进当前 PowerShell 会话。
#
# 用法（必须 dot-source，前面那个点不能省）：
#     . .\env.ps1
#
# 为什么需要这个文件：oss-cad-suite 的 exe 依赖同目录 lib\ 下的 DLL。
# 只把 bin\ 加进 PATH 时，yosys / nextpnr / openFPGALoader 会直接崩，
# 退出码 -1073741515（0xC0000135，STATUS_DLL_NOT_FOUND），没有任何错误信息。
# iverilog 恰好不依赖那些 DLL，所以它会正常跑，把人误导成"工具链没问题"。

$ErrorActionPreference = 'Stop'

$root = 'C:\Local_Data\oss-cad-suite'
if (-not (Test-Path $root)) {
    throw "找不到工具链目录 $root"
}

# 顺序照搬官方 environment.ps1：bin 在前，lib 在后
$env:PATH = "$root\bin;$root\lib;" + $env:PATH

$env:OPENFPGALOADER_SOJ_DIR = "$root\share\openFPGALoader"
$env:SSL_CERT_FILE = "$root\etc\cacert.pem"

# 自检：这四个必须都能报出版本号
$missing = @()
foreach ($t in 'iverilog', 'yosys', 'nextpnr-himbaechel', 'openFPGALoader') {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { $missing += $t }
}
if ($missing.Count -gt 0) {
    throw "工具链不完整，缺：$($missing -join ', ')"
}

Write-Host "oss-cad-suite 就绪（$root）" -ForegroundColor Green
