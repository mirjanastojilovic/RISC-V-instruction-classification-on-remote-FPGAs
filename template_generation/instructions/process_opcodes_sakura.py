# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import pandas as pd
import argparse

metadata = pd.read_csv("/media/SSD/paper_data/sakura/DATASET/template_type/templates/metadata.csv", index_col=None);


cwd = os.getcwd()

start_position = []

for i in metadata.index:
    file_name_no_ext = "/media/SSD/paper_data/sakura/DATASET/template_type/raw/"+metadata.loc[i, 'instruction']+"_template_"+str(metadata.loc[i, 'template_id'])+"/opcodes.csv"
    opcodes = pd.read_csv(file_name_no_ext, dtype=str, header=None)
    #print(file_name_no_ext)
    matching_opcodes = opcodes.iloc[0, :].isin([metadata.loc[i,'hex']])
    # INSTEAD OF .index[0], GET INDEX LAST AND THEN+1 - 24
    inst_position = matching_opcodes[matching_opcodes].index[-1] - 23
    start_position.append(inst_position)
    
metadata['start'] = start_position
metadata['start'] += 500
metadata['start'] += metadata['instruction'].str.contains("lw").astype(int)*100
metadata['start'] += metadata['instruction'].str.contains("lb").astype(int)*100
metadata['start'] += metadata['instruction'].str.contains("lh").astype(int)*100
metadata['start'] += metadata['instruction'].str.contains("lbu").astype(int)*100
metadata['start'] += metadata['instruction'].str.contains("lhu").astype(int)*100
metadata['end'] = metadata['start']+60

metadata.to_csv("/media/SSD/paper_data/sakura/DATASET/template_type/templates/metadata.csv", index=False)
