# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
from glob import glob
from utils import *

result = [y for x in os.walk("hex") for y in glob(os.path.join(x[0], '*.hex'))]

cwd = os.getcwd()
pattern = re.compile('.{2}')

for i, file_name in enumerate(result):

    file_name_no_ext, ext = os.path.splitext(file_name) 
    dest_file_name = file_name_no_ext.replace("hex", "out") 
    generate_folder(cwd, os.path.dirname(dest_file_name))

    input_file = open(file_name, 'r')
    output_file = open(dest_file_name+".txt", 'w') 
    lines = input_file.readlines()
    for line_no, line in enumerate(lines):
        if(line=="0\n"):
            line_no = line_no - 1
            break
        if(line=="00100073\n"):
            line = "0000007e\n"
        if(line_no % 3 != 2):
            output_file.write(' '.join(pattern.findall(line))+" ")
        else:
            if(line_no == 2):
                output_file.write(' '.join(pattern.findall(line))+' 00 00 00 00\n')
            else:
                output_file.write(' '.join(pattern.findall(line))+' 00 00 00 01\n')

    if(line_no % 3 != 2):
        while (line_no % 3 != 2):
            output_file.write("00 00 00 13 ")
            line_no = line_no + 1
        output_file.write(' '.join(pattern.findall(line))+'00 00 00 01\n')

    output_file.write("00 00 00 7e 00 00 00 7e 00 00 00 7e ff ff ff f2\n")

    input_file.close()
    output_file.close()

os.rename("metadata.csv", "out/metadata_in_order.csv")
