# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

export XCL_EMULATION_MODE=hw_emu
v++ --link -t hw_emu -g --platform xilinx_u200_gen3x16_xdma_2_202110_1 --save-temps \
  --vivado.synth.jobs 24 --vivado.impl.jobs 24 \
  --kernel_frequency 0:200 -o bin/picorv_sca.xclbin kernel.xo
  #--vivado.prop run.impl_1.STEPS.PLACE_DESIGN.TCL.PRE=pblocks.tcl \
