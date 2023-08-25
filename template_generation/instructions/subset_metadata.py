# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import pandas as pd

metadata = pd.read_csv("out_alveo/metadata.csv")
metadata.loc[(metadata.instruction == 'bne') & (metadata.template_id >= 10000), 'instruction'] = 'bne_nt'
metadata.loc[(metadata.instruction == 'bne') & (metadata.template_id < 10000), 'instruction'] = 'bne_t'

instruction_subset = ['add','xor','sll','slt','bne_t', 'bne_nt','sw','lw','jal']

metadata_subset = metadata[metadata['instruction'].isin(instruction_subset)]
metadata_subset = metadata_subset.reset_index(drop=True)

metadata_subset.loc[(metadata_subset.instruction == 'bne_nt'), 'instruction'] = 'bne'
metadata_subset.loc[(metadata_subset.instruction == 'bne_t'), 'instruction'] = 'bne'

metadata_subset.to_csv("out_alveo/metadata_subset.csv", index=False)
