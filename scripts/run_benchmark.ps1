param(
    [ValidateSet('matrix','fft')][string]$Benchmark = 'matrix',
    [string]$VivadoBin = $env:VIVADO_BIN
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $VivadoBin) {
    $tool = Get-Command xvlog.bat -ErrorAction SilentlyContinue
    if ($tool) { $VivadoBin = Split-Path $tool.Source }
}
if (-not $VivadoBin -or -not (Test-Path (Join-Path $VivadoBin 'xvlog.bat'))) {
    throw 'Set VIVADO_BIN to the Vivado bin directory, or add it to PATH.'
}

$expected = if ($Benchmark -eq 'matrix') { 184 } else { 248 }
$work = Join-Path $repo "build/benchmark/$Benchmark"
New-Item -ItemType Directory -Force $work | Out-Null
Copy-Item (Join-Path $repo "benchmarks/prebuilt/$Benchmark/program.mem") (Join-Path $work 'program.mem') -Force
Copy-Item (Join-Path $repo "benchmarks/prebuilt/$Benchmark/data.mem") (Join-Path $work 'data.mem') -Force
$sources = @(Get-ChildItem (Join-Path $repo 'rtl') -Recurse -Filter '*.v' | ForEach-Object FullName)
$sources += Join-Path $repo 'sim/cpu_power_tb.v'

Push-Location $work
try {
    & (Join-Path $VivadoBin 'xvlog.bat') @sources
    if ($LASTEXITCODE -ne 0) { throw 'RTL compilation failed.' }
    & (Join-Path $VivadoBin 'xelab.bat') -debug typical -top cpu_power_tb -snapshot benchmark_snap
    if ($LASTEXITCODE -ne 0) { throw 'Benchmark elaboration failed.' }
    $output = & (Join-Path $VivadoBin 'xsim.bat') benchmark_snap -R 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0 -or ($output -join "`n") -notmatch 'BENCHMARK PASS' -or ($output -join "`n") -notmatch "Benchmark Checksum \(a0/x10\):\s+$expected" -or ($output -join "`n") -match 'TIMEOUT|FATAL') {
        throw "$Benchmark benchmark failed."
    }
    Write-Host "$Benchmark benchmark passed (a0=$expected)."
} finally {
    Pop-Location
}
