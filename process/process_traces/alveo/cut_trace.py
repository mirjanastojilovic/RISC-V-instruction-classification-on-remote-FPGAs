# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import pandas as pd
import numpy as np
import sys
import os

if(len(sys.argv)!=3):
    print("Incorrect argument. Usage:\npython3 cut_trace.py <path_to_uncut_dataset> <path_to_metadata>")
    exit()

in_path = sys.argv[1];
out_path = os.path.dirname(in_path)+"/"+os.path.splitext(os.path.basename(in_path))[0]+"_cut.csv"

dataset = pd.read_csv(in_path)
metadata = pd.read_csv(sys.argv[2])

dataset = dataset[dataset.groupby(['inst']).cumcount()<10]
metadata = metadata[metadata.groupby(['instruction']).cumcount()<10]

N_SENSORS = 29
N_CUT_SAMPLES = 16
N_SAMPLES = 256

columns = ['inst','info','template_id']
for i in range(0, N_SENSORS):
    for j in range(0,N_CUT_SAMPLES):
        columns.append("s"+str(i)+"_"+str(j))

dataset2 = pd.DataFrame()

for row in dataset.index:

    INST_LEFT = metadata['start'].iloc[row]

    samples = [0, 1, 2]

    for i in range(0, N_SENSORS):
        for j in range(0,N_CUT_SAMPLES):
            samples.append(N_SAMPLES*i+3+INST_LEFT+j)

    subset = dataset.iloc[row, samples]
    subset = pd.DataFrame(subset).T
    subset.columns = columns
    dataset2 = pd.concat([dataset2, subset], axis=0)
    
dataset2.to_csv(out_path, index=False)
