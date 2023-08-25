# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import pandas as pd

os.system("xbutil examine -d 0000:01:00.1 --report thermal > tmp.txt")

temps = []

with open("tmp.txt", "r") as temperature_file:
    for line_no, line in enumerate(temperature_file):
        if(line_no>5 and line_no<11):
            line_temp = [int(s) for s in line.split() if s.isdigit()]
            temps.append(line_temp[0])

print(temps)




#temp = pd.read_csv(PATH+"/temperature.csv");


