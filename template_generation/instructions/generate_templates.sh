#!/bin/bash
# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

CPU="picorv32" #"riscy" or "picorv32"
N_TEMPLATES=20000
RANDOM_TEMP="random" #"random" or "nops"

python3 generate_instruction.py -c ${CPU} -t ${RANDOM_TEMP} -n ${N_TEMPLATES}
python3 compile.py
if [ "${CPU}" = "picorv32" ]; then
  python3 generate_output_alveo.py
else
  python3 generate_output.py
fi

python3 round_robin.py -c ${CPU} -t ${N_TEMPLATES}
