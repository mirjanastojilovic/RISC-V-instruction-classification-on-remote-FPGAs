#!/bin/bash
# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.


# Start experiment notification
python3 telegram_bot0.py

# Record traces for all instructions
./FTDexampleAES -t 100 -s 500 1000 -c 0 -i data/ -d data/

# Send notification that all is done
python3 telegram_bot1.py
