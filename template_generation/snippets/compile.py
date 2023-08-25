# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
from glob import glob

result = [y for x in os.walk("asm") for y in glob(os.path.join(x[0], '*.s'))]

def generate_folder(path, folder_name):
    isExists = os.path.exists(path + "/" + folder_name)
    if not isExists:
        os.makedirs(path + "/" + folder_name)

    newpath = path + "/" + folder_name
    return newpath

cwd = os.getcwd()

for i, file_name in enumerate(result):
    file_name_no_ext, ext = os.path.splitext(file_name)
    dest_file_name = file_name_no_ext.replace("asm", "hex")
    generate_folder(cwd, os.path.dirname(dest_file_name))
    print("Compiling file "+file_name)
    os.system("/opt/riscv32i/bin/riscv32-unknown-elf-gcc -Os -ffreestanding -nostdlib -o "+dest_file_name+".elf "+file_name+" --std=gnu99 -Wl,-Bstatic,-T,firmware.lds,-Map,"+dest_file_name+".map,--strip-debug -lgcc")
    os.system("/opt/riscv32i/bin/riscv32-unknown-elf-objcopy -O binary "+dest_file_name+".elf "+dest_file_name+".bin")
    os.system("python3 makehex.py "+dest_file_name+".bin 4096 > "+dest_file_name+".hex")
    os.system("rm "+dest_file_name+".bin "+dest_file_name+".elf "+dest_file_name+".map")

