# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import pandas as pd
import re


metadata = pd.read_csv("/media/SSD/paper_data/alveo/random/20k/templates/metadata.csv", index_col=None);

opcodes = pd.read_csv("/media/SSD/paper_data/alveo/random/20k/traces/opcodes.csv", dtype=str)

for column in opcodes.iloc[:, 3:].columns:
    #print(column)
    opcodes[column] = opcodes[column].str.replace(r'[^\s]+?(?=\|)\|', '')

start_position = []

for i in metadata.index:
    matching_opcodes = opcodes.iloc[i, :].isin([metadata.loc[i,'hex']])
    # INSTEAD OF .index[0], GET INDEX LAST AND THEN+1 - 24
    if(matching_opcodes[matching_opcodes].shape[0] == 0):
        print("ERROR FOR i = "+str(i)+"; Instruction: "+metadata.iloc[i, 0]+"; template: ",metadata.iloc[i, 2])
        continue
    inst_position = int(re.findall(r'\d+', matching_opcodes[matching_opcodes].index[0])[0]) - 5
    start_position.append(inst_position)

metadata['start'] = start_position
metadata['end'] = metadata['start']+16

print("ALL GOOD!!")

metadata.to_csv("/media/SSD/paper_data/alveo/random/20k/templates/metadata_start_end.csv", index=False)
