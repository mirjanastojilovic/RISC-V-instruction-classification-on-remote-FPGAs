#!/bin/bash
# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.


python3 cut_trace_fast.py /media/SSD/paper_data/alveo/nops/10k/traces/dataset_averaged.csv /media/SSD/paper_data/alveo/nops/10k/templates/metadata_start_end.csv
python3 cut_trace_fast.py /media/SSD/paper_data/alveo/random/10k/traces/dataset_averaged.csv /media/SSD/paper_data/alveo/random/10k/templates/metadata_start_end.csv
python3 cut_trace_fast.py /media/SSD/paper_data/alveo/random/20k/traces/dataset_averaged.csv /media/SSD/paper_data/alveo/random/20k/templates/metadata_start_end.csv

