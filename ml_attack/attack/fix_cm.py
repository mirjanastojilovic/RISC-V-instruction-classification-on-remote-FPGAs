# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import pandas as pd

sensor_tag="all"
seeds = [0]
sensors = "0 1 2 3 4"
preprocessings = ["none", "CWT-H", "CWT-V"]
models = ["LSTM", "CNN", "CNN_small", "LSTM+CNN", "CNN+LSTM", "MLP", "resnet"]
datasets = ["IN/nops", "OUT1/nops", "OUT1/random", "OUT2/nops"]
i = 10000
DATA_SOURCE = "nfs"
board="sakura"
topks=[2, 3, 4, 5, 6]
instructions = ['add', 'addi', 'sub', 'lui', 'auipc', 'xor', 'xori', 'or', 'ori', 'and', 'andi', 'slt', 'slti', 'sltu', 'sltiu', 'sll', 'slli', 'srl', 'srli', 'sra', 'srai', 'lb', 'lh', 'lw', 'lbu', 'lhu', 'sb', 'sh', 'sw', 'beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu', 'jal', 'jalr']
instructions_sorted = instructions.copy()
instructions_sorted.sort()

root_path = "/media/SSD/paper_data/"

#incomplete_jobs = ['/tmp/drive/data/sakura/Exp-OUT1/nops/results/CNN+LSTM_pCWT-H_10000_s0-sensors-all_10fold']

for seed in seeds:
    for preprocessing in preprocessings:
        for model in models:
            for dataset in datasets:
                for k in range(0, 10):
                    cm_path = root_path+"sakura/Exp-"+dataset+"/results/"+model+"_p"+preprocessing+"_"+str(i)+"_s"+str(seed)+"-sensors-"+sensor_tag+"_10fold/out/cm/LSTM+CNN_kf"+str(k)+"confusion_metrix.csv"

                    confusion_matrix = pd.read_csv(cm_path, index_col=0)
                    confusion_matrix.index = instructions_sorted
                    confusion_matrix.columns = instructions_sorted
                    confusion_matrix = confusion_matrix.loc[instructions, instructions]
                    #confusion_matrix = confusion_matrix.round(decimals=2)*100
                    confusion_matrix.to_csv(cm_path)
