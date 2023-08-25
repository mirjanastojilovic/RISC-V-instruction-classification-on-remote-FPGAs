# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-


firmware.hex: firmware.S firmware.c firmware.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -ffreestanding -nostdlib -o firmware.elf firmware.S firmware.c \
		 --std=gnu99 -Wl,-Bstatic,-T,firmware.lds,-Map,firmware.map,--strip-debug -lgcc
	$(TOOLCHAIN_PREFIX)objcopy -O binary firmware.elf firmware.bin
	python3 ../tools/makehex.py firmware.bin 4096 > firmware.hex
	python3 ../tools/makecoe.py firmware.hex

clean:
	rm -rf firmware.bin firmware.elf firmware.hex firmware.map firmware.coe 

