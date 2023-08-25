# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
from glob import glob
from utils import *
import pandas as pd

metadata = pd.read_csv("metadata.csv", index_col=None);

def get_line(file_path, line_no):
    fp = open(file_path, "r")
    for i, line in enumerate(fp):
        #print(str(i),": ", line)
        if i == line_no:
            fp.close()
            return line.strip()

cwd = os.getcwd()

hex_list = []

for i in metadata.index:
    #if(metadata.loc[i, 'info']=='-'):
    #    file_name_no_ext = "asm/"+metadata.loc[i, 'instruction']+"/"+metadata.loc[i, 'instruction']+"_template_"+str(metadata.loc[i, 'template_id'])
    #else:
    #    file_name_no_ext = "asm/"+metadata.loc[i, 'instruction']+"/"+metadata.loc[i, 'info']+"/"+metadata.loc[i, 'instruction']+"_template_"+str(metadata.loc[i, 'template_id'])
    file_name_no_ext = "asm/"+metadata.loc[i, 'instruction']+"/"+metadata.loc[i, 'instruction']+"_template_"+str(metadata.loc[i, 'template_id'])
    dest_file_name = file_name_no_ext.replace("asm", "hex") 
    generate_folder(cwd, os.path.dirname(dest_file_name))
    #print("File no "+str(i)+"; name: "+file_name)
    #print("File no "+str(i)+"; dest_name: "+dest_file_name)
    #print("File no "+str(i))
    #print("Compiling file "+file_name_no_ext+".s")
    os.system("/opt/riscv32i/bin/riscv32-unknown-elf-gcc -Os -ffreestanding -nostdlib -o "+dest_file_name+".elf "+file_name_no_ext+".s --std=gnu99 -Wl,-Bstatic,-T,firmware.lds,-Map,"+dest_file_name+".map,--strip-debug -lgcc")
    os.system("/opt/riscv32i/bin/riscv32-unknown-elf-objcopy -O binary "+dest_file_name+".elf "+dest_file_name+".bin")
    os.system("python3 makehex.py "+dest_file_name+".bin 4096 > "+dest_file_name+".hex")
    os.system("rm "+dest_file_name+".bin "+dest_file_name+".elf "+dest_file_name+".map")
    hex_list.append(get_line(dest_file_name+".hex", metadata.loc[i, 'asm_line']))

metadata['hex'] = hex_list

metadata.to_csv("metadata.csv", index=False);
