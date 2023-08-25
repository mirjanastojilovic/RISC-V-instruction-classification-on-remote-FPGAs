# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import pandas as pd

metadata = pd.read_csv("templates/metadata_in_order.csv")

metadata_df_list = []

instruction_types = metadata.instruction.unique()

for instruction in instruction_types:
    metadata_df_list.append(metadata.loc[metadata['instruction'] == instruction].reset_index(drop=True))
    
metadata_round_robin = pd.concat(metadata_df_list).sort_index().reset_index(drop=True)#.set_index('index')

metadata_round_robin.to_csv("templates/metadata.csv", index=False)
