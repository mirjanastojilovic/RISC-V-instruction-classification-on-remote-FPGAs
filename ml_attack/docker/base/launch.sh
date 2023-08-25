#!/bin/bash

sudo service ssh start

git clone https://https://github.com/mirjanastojilovic/RISC-V-instruction-classification-on-remote-FPGAs ~/og-instruction-identification
cd ~/og-instruction-identification/code/ml_attack/attack/

bash -c "$1"
