#!/bin/bash
# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

for dataset in Exp-OUT1/nop_templates Exp-OUT1/random_templates Exp-OUT2/nop_templates
do
  echo FOR /media/SSD/paper_data/sakura/${dataset}/round_robin/10k/
  for avg in 1 10 20 30 40 50 60 70 80 90 
  do
    echo FOR AVERAGING ${avg}
    ./average 5 100 60 ${avg} /media/SSD/paper_data/sakura/${dataset}/round_robin/10k/
  done
done
