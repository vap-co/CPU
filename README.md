# RV32IM CPU: Adder-Multiplier Comparison

A configurable Verilog RV32IM processor for comparing RCA, CSLA and Kogge-Stone adders with Array, Wallace and Vedic multipliers. The CPU supports asynchronous memory and synchronous BRAM memory. The paper's hardware results use BRAM mode with separate 8 KiB instruction and data memories.

## Requirements

- Vivado 2025.2, including XSim
- Target FPGA: `xc7z030ffg676-1`
- Windows PowerShell for the supplied runners
- Python 3 for power summaries and binary conversion
- RV32IM bare-metal GCC only if rebuilding the C benchmarks

Run commands from the repository root. Set your Vivado installation path:

```powershell
$env:VIVADO_BIN = 'C:\path\to\Vivado\2025.2\bin'
$env:PATH = "$env:VIVADO_BIN;$env:PATH"
vivado -version
```

## Repository Layout

| Directory | Contents |
| --- | --- |
| `rtl/` | CPU, arithmetic units and memory modules |
| `sim/` | Functional testbenches and instruction self-test |
| `benchmarks/` | Matrix4x4 and FFT8 sources, startup/linker files and prebuilt images |
| `constraints/` | CPU and standalone timing constraints |
| `scripts/` | Simulation, implementation, Fmax and power flows |
| `tools/` | Program generation and binary-to-memory conversion |
| `results/` | Reference reports and summaries |

Generated projects, simulator files and checkpoints are written under `build/` or `vivado_project/` and can be recreated.

## CPU Configuration

The synthesis top is `rtl/core/cpu_top.v`. Parameters select the hardware at elaboration:

| Parameter | `0` | `1` | `2` |
| --- | --- | --- | --- |
| `ADDER_TYPE` | RCA | CSLA | KSA |
| `MULT_TYPE` | Array | Wallace | Vedic |
| `MEMORY_MODE` | Asynchronous | BRAM | - |

Defaults are RCA + Array + BRAM (`0,0,1`). The nine-configuration scripts set the arithmetic parameters explicitly and keep `MEMORY_MODE=1`, memory sizes and the divider fixed.

### Memory Images

| Run | Images used |
| --- | --- |
| Functional tests | `sim/program.mem` and `sim/data.mem` |
| CPU comparison at 30 ns | Root `program.mem` and `data.mem` |
| Matrix benchmark | `benchmarks/prebuilt/matrix/` |
| FFT benchmark and Fmax sweep | `benchmarks/prebuilt/fft/` |
| Power activity simulation | FFT images, staged automatically by the SAIF runner |

The root program is the instruction self-test. **Use the FFT program for the paper's Fmax sweep.** Memory images are read during synthesis, so changing them requires resynthesis.

## Functional Tests

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_all_sims.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_benchmark.ps1 -Benchmark matrix
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_benchmark.ps1 -Benchmark fft
```

Expect `All six functional tests passed.` The suite covers the arithmetic units, instruction execution and all nine configurations in both memory modes.

| Benchmark | Expected a0/x10 | Halt time at 30 ns |
| --- | ---: | ---: |
| Matrix4x4 | 184 | 2.262885 ms |
| FFT8 | 248 | 2.403975 ms |

Benchmark logs are written to `build/benchmark/<benchmark>/xsim.log`. Reference outputs are in `results/benchmarks/`. The runners also accept `-VivadoBin 'C:\path\to\Vivado\bin'`.

To rebuild the C programs, use `benchmarks/build.ps1` or the Makefile with an RV32IM bare-metal toolchain. The resulting images are `benchmarks/build/*_imem.mem` and `*_dmem.mem`. The benchmark runner still reads `benchmarks/prebuilt/`; explicitly replace the selected prebuilt pair to test a rebuild, keeping a backup of the originals. Compiler versions can change the generated program and cycle count.

## Open in Vivado

In the Vivado Tcl Console:

```tcl
cd C:/path/to/RV32IM_3x3_AdderMultiplier_DualMemory
source scripts/create_project.tcl
```

This creates `vivado_project/RV32IM_3x3_CPU.xpr`, with synthesis top `cpu_top` and simulation top `cpu_9config_bram_tb`. Use **Run Behavioral Simulation** to test all nine BRAM configurations.

For a single implementation, edit the defaults in `cpu_top.v`. For example, KSA + Wallace + BRAM:

```verilog
parameter ADDER_TYPE = 2,
parameter MULT_TYPE = 1,
parameter MEMORY_MODE = 1,
```

Reset `synth_1` and `impl_1`, then rerun synthesis and implementation. Clear any project-level generic overrides when using the RTL defaults.

## Reproduce the Paper Results

### Standalone Units

```powershell
vivado -mode batch -source scripts/run_standalone.tcl
```

Compare `build/standalone/*_utilization.rpt` and `*_timing.rpt` with `results/standalone/` and Tables 6-7. The clock period is 10 ns. Negative WNS for the standalone Array multiplier is expected.

### CPU Area and Timing at 30 ns

```powershell
vivado -mode batch -source scripts/run_9_configs.tcl
```

Use the supplied root memory images. Reports and routed checkpoints are written to `build/reproduced_9config_mem1/`. Compare the routed LUT/FF counts, WNS and `Data Path Delay` with `results/implementation/` and Tables 8-9. Each configuration uses 44 LUTRAMs, 256 FFs, four RAMB36 blocks and zero DSP blocks.

Keep the nine `*_routed.dcp` files for power analysis. The delay-derived frequency in Table 10 is `1000 / data_path_delay_ns`; Table 10 uses the separate Fmax sweep.

### Fmax with FFT8

The sweep reads `program.mem` and `data.mem` from its working directory. Run it in a separate copy containing the FFT images:

```powershell
$repo = (Get-Location).Path
$fmaxWork = Join-Path $repo ('build/fft_fmax_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Path $fmaxWork -ErrorAction Stop | Out-Null
foreach ($folder in @('rtl', 'constraints', 'scripts')) {
    Copy-Item -LiteralPath (Join-Path $repo $folder) -Destination $fmaxWork -Recurse
}
Copy-Item -LiteralPath (Join-Path $repo 'benchmarks/prebuilt/fft/program.mem') -Destination $fmaxWork
Copy-Item -LiteralPath (Join-Path $repo 'benchmarks/prebuilt/fft/data.mem') -Destination $fmaxWork
Push-Location $fmaxWork
try {
    vivado -mode batch -source scripts/fmax_sweep.tcl
    if ($LASTEXITCODE -ne 0) { throw 'FFT8 Fmax sweep failed.' }
} finally {
    Pop-Location
}
Write-Host "Fmax reports: $fmaxWork/build/fmax"
```

Compare the generated `fmax_summary.csv`, `passing_timing.rpt` and `failing_timing.rpt` with `results/fmax_summary.csv` and Table 11. Fmax is `1000 / passing_period_ns`. The full sweep can take several hours.

For CSLA-Wallace, the reference boundary is 14.3 ns with WNS +0.087 ns and 14.2 ns with WNS -0.363 ns, giving 69.93 MHz. These two points were reproduced with FFT8; their reports are in `results/fmax_fft8_endpoint_recheck/`. The other eight rows have not been rerun in that endpoint check.

### FFT8-SAIF Power

From the original repository root, after generating the CPU checkpoints:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_saif_9config.ps1
if ($LASTEXITCODE -ne 0) { throw 'SAIF simulation or power analysis failed.' }
python .\scripts\parse_power.py
if ($LASTEXITCODE -ne 0) { throw 'Power summary failed.' }
```

The runner stages FFT8 for each configuration, checks checksum 248 and annotates its routed checkpoint. Outputs are in `build/power/<configuration>/`; compare `build/power/power_summary.csv` with `results/power_fft8_archived/power_summary.csv` and Table 12. The reference SAIF duration is 2.40409 ms. Array activity simulation can take several hours.

Append `-Configuration RCA_WALLACE` to run one configuration. `-SimulationOnly` records activity; `-PowerOnly` reuses existing activity. Use `parse_power.py --allow-incomplete` to inspect a partial run.

### Energy and PPA

For Table 13, use power from the FFT8 experiment and delay/LUT count from the common 30 ns CPU comparison:

```text
Total energy/cycle (nJ)   = total_power_W * 30
Dynamic energy/cycle (nJ) = dynamic_power_W * 30
Normalized PPA           = (total_power_W / 0.171)
                         * (data_path_delay_ns / 27.372)
                         * (total_LUTs / 3581)
```

RCA-Array is the 1.000 reference; RCA-Vedic and CSLA-Vedic round to 0.461 and 0.466. Use the common-run data-path delay, not the swept Fmax period.

## Notes

- Power values are Vivado estimates, with 14-29% routed-net SAIF matching. They are not board measurements.
- The Fmax script checks setup slack. Check hold and pulse-width timing before using the swept clock on hardware.
- This core has no privileged/CSR subsystem. ECALL and EBREAK halt execution; FENCE is a no-op. Formal ISA compliance has not been established.
- The divider test checks numerical results but currently lacks an explicit failure when `done` times out.
- The XDC excludes reset/debug paths and has no board pin assignments. Add board-specific constraints before programming an FPGA.
