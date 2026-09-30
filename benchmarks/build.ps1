param([string]$ToolchainPrefix = $env:RISCV_PREFIX)

$ErrorActionPreference = 'Stop'
if (-not $ToolchainPrefix) { $ToolchainPrefix = 'riscv32-unknown-elf-' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$out = Join-Path $PSScriptRoot 'build'
New-Item -ItemType Directory -Force $out | Out-Null
Push-Location $PSScriptRoot
try {
    foreach ($name in @('matrix','fft')) {
        $source = if ($name -eq 'matrix') { 'matrix4x4/main.c' } else { 'fft8/main.c' }
        $elf = "build/$name.elf"
        & "${ToolchainPrefix}gcc" -march=rv32im -mabi=ilp32 -Os -ffreestanding -fno-builtin -fno-common -mno-relax -msmall-data-limit=0 -nostdlib -nostartfiles common/crt0.S $source -T common/linker.ld '-Wl,--gc-sections' "-Wl,-Map,build/$name.elf.map" -o $elf
        if ($LASTEXITCODE -ne 0) { throw "Build failed: $name" }
        & "${ToolchainPrefix}objcopy" -O binary -j .text $elf "build/${name}_text.bin"
        if ($LASTEXITCODE -ne 0) { throw "Text extraction failed: $name" }
        & "${ToolchainPrefix}objcopy" -O binary -j .rodata -j .data -j .sdata $elf "build/${name}_data.bin"
        if ($LASTEXITCODE -ne 0) { throw "Data extraction failed: $name" }
        python (Join-Path $repo 'tools/bin_to_mem.py') "build/${name}_text.bin" "build/${name}_imem.mem"
        if ($LASTEXITCODE -ne 0) { throw "Instruction image failed: $name" }
        python (Join-Path $repo 'tools/bin_to_mem.py') "build/${name}_data.bin" "build/${name}_dmem.mem"
        if ($LASTEXITCODE -ne 0) { throw "Data image failed: $name" }
    }
} finally {
    Pop-Location
}
