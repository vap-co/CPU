param(
    [string]$VivadoBin = $env:VIVADO_BIN,
    [string]$Configuration,
    [switch]$SimulationOnly,
    [switch]$PowerOnly
)

$ErrorActionPreference = 'Stop'
if ($SimulationOnly -and $PowerOnly) { throw 'Choose only one of -SimulationOnly or -PowerOnly.' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $VivadoBin) {
    $tool = Get-Command xvlog.bat -ErrorAction SilentlyContinue
    if ($tool) { $VivadoBin = Split-Path $tool.Source }
}
if (-not $VivadoBin -or -not (Test-Path (Join-Path $VivadoBin 'vivado.bat'))) {
    throw 'Set VIVADO_BIN to the Vivado bin directory, or add it to PATH.'
}
$sources = @(Get-ChildItem (Join-Path $repo 'rtl') -Recurse -Filter '*.v' | ForEach-Object FullName)
$sources += Join-Path $repo 'sim/cpu_power_tb.v'
$names = @('RCA','CSLA','KSA')
$mults = @('ARRAY','WALLACE','VEDIC')
$work = Join-Path $repo 'build/power'
$program = Join-Path $repo 'benchmarks/prebuilt/fft/program.mem'
$data = Join-Path $repo 'benchmarks/prebuilt/fft/data.mem'
New-Item -ItemType Directory -Force $work | Out-Null

for ($a = 0; $a -lt 3; $a++) {
    for ($m = 0; $m -lt 3; $m++) {
        $cfg = "$($names[$a])_$($mults[$m])"
        if ($Configuration -and $cfg -ne $Configuration) { continue }
        $checkpoint = Join-Path $repo "build/reproduced_9config_mem1/${cfg}_routed.dcp"
        if (-not (Test-Path $checkpoint)) { throw "Missing $checkpoint. Run scripts/run_9_configs.tcl first." }
        $dir = Join-Path $work $cfg
        New-Item -ItemType Directory -Force $dir | Out-Null
        Push-Location $dir
        try {
            if (-not $PowerOnly) {
                Copy-Item $program 'program.mem' -Force
                Copy-Item $data 'data.mem' -Force
                & (Join-Path $VivadoBin 'xvlog.bat') @sources
                if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $cfg" }
                & (Join-Path $VivadoBin 'xelab.bat') -debug typical -top cpu_power_tb -snapshot power_snap -generic_top "`"ADDER_TYPE=$a`"" -generic_top "`"MULT_TYPE=$m`"" -generic_top '"EXPECTED_CHECKSUM=248"'
                if ($LASTEXITCODE -ne 0) { throw "Elaboration failed: $cfg" }
            }
            $saif = (Join-Path $dir 'activity.saif').Replace('\','/')
            if (-not $PowerOnly) {
                @("run 35ns", "open_saif $saif", 'log_saif [get_objects -r /*/dut/*]', 'run all', 'close_saif', 'exit') | Set-Content -Path 'capture.tcl'
                $simOutput = & (Join-Path $VivadoBin 'xsim.bat') power_snap -tclbatch capture.tcl 2>&1
                $simOutput | Set-Content 'simulation.log'
                if ($LASTEXITCODE -ne 0 -or ($simOutput -join "`n") -notmatch 'BENCHMARK PASS' -or ($simOutput -join "`n") -match 'TIMEOUT|FATAL') {
                    throw "Simulation failed: $cfg"
                }
            }
            if (-not (Test-Path 'activity.saif')) { throw "SAIF missing: $cfg" }
            if (-not $SimulationOnly) {
                $saifText = [System.IO.File]::ReadAllText((Join-Path $dir 'activity.saif'))
                $saifText = $saifText -replace 'cpu_power_tb\\\(.*?\\\)', 'cpu_power_tb'
                [System.IO.File]::WriteAllText((Join-Path $dir 'activity.saif'), $saifText)
                $report = (Join-Path $dir 'power_report.rpt').Replace('\','/')
                $dcp = $checkpoint.Replace('\','/')
                @("open_checkpoint {$dcp}", "read_saif {$saif} -strip_path cpu_power_tb/dut", "report_power -file {$report}", 'close_design') | Set-Content -Path 'power.tcl'
                & (Join-Path $VivadoBin 'vivado.bat') -mode batch -source power.tcl -nojournal -nolog *> 'vivado_power.log'
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path 'power_report.rpt')) { throw "Power analysis failed: $cfg" }
            }
            Write-Host "$cfg complete"
        } finally {
            Pop-Location
        }
    }
}
