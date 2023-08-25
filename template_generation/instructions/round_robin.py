# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import pandas as pd
import argparse

parser = argparse.ArgumentParser(description='Interleaving templates.')
parser.add_argument("-c", "--CPU", help="CPU type. riscy or picorv32", required=True)
parser.add_argument("-t", "--n_templates", help="number of templates per instruction", required=True)
args = parser.parse_args()

PROCESSOR = args.CPU #"riscy"
N_TEMPLATES = int(args.n_templates)

if(PROCESSOR == "riscy"):
    out_dir = "out"
else:
    out_dir = "out_alveo"

metadata = pd.read_csv(out_dir+"/metadata_in_order.csv")

if(PROCESSOR == "riscy"):
    metadata['start'] = 500
    metadata['end'] = 1000 
    metadata['start'] += metadata['instruction'].str.contains("lw").astype(int)*100
    metadata['start'] += metadata['instruction'].str.contains("lb").astype(int)*100
    metadata['start'] += metadata['instruction'].str.contains("lh").astype(int)*100
    metadata['start'] += metadata['instruction'].str.contains("lbu").astype(int)*100
    metadata['start'] += metadata['instruction'].str.contains("lhu").astype(int)*100

for instruction in metadata.instruction.unique():
    if(instruction[0] == 'b'):
        metadata.loc[(metadata.instruction == instruction) & (metadata.template_id >= N_TEMPLATES), 'instruction'] = instruction+'_nt'
        metadata.loc[(metadata.instruction == instruction) & (metadata.template_id < N_TEMPLATES), 'instruction'] =  instruction+'_t'

metadata_df_list = []

instruction_types = metadata.instruction.unique()

for instruction in instruction_types:
    metadata_df_list.append(metadata.loc[metadata['instruction'] == instruction].reset_index(drop=True))
    
metadata_round_robin = pd.concat(metadata_df_list).sort_index().reset_index(drop=True)#.set_index('index')

for instruction in metadata.instruction.unique():
    if(instruction[0] == 'b'):
        metadata_round_robin.loc[(metadata_round_robin.instruction == instruction), 'instruction'] = instruction.split('_')[0]

metadata_round_robin.to_csv(out_dir+"/metadata.csv", index=False)
