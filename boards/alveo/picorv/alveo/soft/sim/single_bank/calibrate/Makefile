# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.


.PHONY: check-env

default: host

check-env:
ifndef XILINX_XRT
	$(error XILINX_XRT is undefined)
endif

host: host.cpp calib.cpp check-env
	$(CXX) host.cpp calib.cpp -L$(XILINX_XRT)/lib -I$(XILINX_XRT)/include -lxrt_coreutil -o host

clean:
	rm -rf .run .Xil *.log xilinx* emconfig.json host *.csv
