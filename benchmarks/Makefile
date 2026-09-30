CROSS ?= riscv32-unknown-elf-
CC    := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
CFLAGS := -march=rv32im -mabi=ilp32 -Os -ffreestanding -fno-builtin -fno-common -mno-relax -msmall-data-limit=0 -nostdlib -nostartfiles
LDFLAGS = -T common/linker.ld -Wl,--gc-sections -Wl,-Map,$@.map

.PHONY: all matrix fft clean
all: matrix fft

matrix: build/matrix.elf build/matrix_imem.mem build/matrix_dmem.mem
fft: build/fft.elf build/fft_imem.mem build/fft_dmem.mem

build:
	mkdir -p build

build/matrix.elf: common/crt0.S matrix4x4/main.c common/linker.ld | build
	$(CC) $(CFLAGS) common/crt0.S matrix4x4/main.c $(LDFLAGS) -o $@

build/fft.elf: common/crt0.S fft8/main.c common/linker.ld | build
	$(CC) $(CFLAGS) common/crt0.S fft8/main.c $(LDFLAGS) -o $@

build/%_text.bin: build/%.elf
	$(OBJCOPY) -O binary -j .text $< $@

build/%_data.bin: build/%.elf
	$(OBJCOPY) -O binary -j .rodata -j .data -j .sdata $< $@

build/%_imem.mem: build/%_text.bin
	python3 ../tools/bin_to_mem.py $< $@

build/%_dmem.mem: build/%_data.bin
	python3 ../tools/bin_to_mem.py $< $@

clean:
	rm -rf build
