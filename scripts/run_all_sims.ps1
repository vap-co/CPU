param([string]$VivadoBin = $env:VIVADO_BIN)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $VivadoBin) {
    $tool = Get-Command xvlog.bat -ErrorAction SilentlyContinue
    if ($tool) { $VivadoBin = Split-Path $tool.Source }
}
if (-not $VivadoBin -or -not (Test-Path (Join-Path $VivadoBin 'xvlog.bat'))) {
    throw 'Set VIVADO_BIN to the Vivado bin directory, or add it to PATH.'
}

$work = Join-Path $repo 'build/sim'
New-Item -ItemType Directory -Force $work | Out-Null
Copy-Item (Join-Path $repo 'sim/program.mem') (Join-Path $work 'program.mem') -Force
Copy-Item (Join-Path $repo 'sim/data.mem') (Join-Path $work 'data.mem') -Force
$sources = @(Get-ChildItem (Join-Path $repo 'rtl') -Recurse -Filter '*.v' | ForEach-Object FullName)
$sources += @(Get-ChildItem (Join-Path $repo 'sim') -Filter '*.v' | ForEach-Object FullName)
$tests = @('adder_tb','multiplier_tb','divider_tb','cpu_instruction_tb','cpu_9config_tb','cpu_9config_bram_tb')

Push-Location $work
try {
    & (Join-Path $VivadoBin 'xvlog.bat') @sources
    if ($LASTEXITCODE -ne 0) { throw 'RTL compilation failed.' }
    foreach ($test in $tests) {
        $snapshot = "${test}_snap"
        & (Join-Path $VivadoBin 'xelab.bat') -debug typical -top $test -snapshot $snapshot
        if ($LASTEXITCODE -ne 0) { throw "Elaboration failed: $test" }
        $output = & (Join-Path $VivadoBin 'xsim.bat') $snapshot -R 2>&1
        $output | Out-Host
        if ($LASTEXITCODE -ne 0 -or ($output -join "`n") -notmatch "${test.ToUpper()} PASS" -or ($output -join "`n") -match 'FAIL|TIMEOUT') {
            throw "Simulation failed: $test"
        }
    }
    Write-Host 'All six functional tests passed.'
} finally {
    Pop-Location
}
