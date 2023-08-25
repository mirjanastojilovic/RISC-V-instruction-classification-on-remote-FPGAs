# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import re
from glob import glob

result = [y for x in os.walk("hex") for y in glob(os.path.join(x[0], '*.hex'))]

def generate_folder(path, folder_name):
    isExists = os.path.exists(path + "/" + folder_name)
    if not isExists:
        os.makedirs(path + "/" + folder_name)

    newpath = path + "/" + folder_name
    return newpath

cwd = os.getcwd()
pattern = re.compile('.{2}')

for i, file_name in enumerate(result):

    file_name_no_ext, ext = os.path.splitext(file_name) 
    dest_file_name = file_name_no_ext.replace("hex", "out_temp") 
    generate_folder(cwd, os.path.dirname(dest_file_name))

    input_file = open(file_name, 'r')
    output_file = open(dest_file_name+".txt", 'w') 
    lines = input_file.readlines()

    data = 1;
    for line_no, line in enumerate(lines):
        if(line=="0\n" and line_no < 85):
            output_file.write("00000000\n")
        elif(line=="0\n" and line_no >= 85 and line_no < 200):
            #line_no = line_no - 1
            #break
            output_file.write("FFFF"+"%0.4X\n" % data)
            data = data+1
        elif(line=="0\n" and line_no >= 200):
            break
        else:
            output_file.write(line)

    #output_file.write("00100073\n");

    input_file.close()
    output_file.close()
