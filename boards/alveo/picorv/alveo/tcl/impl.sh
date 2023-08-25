# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

v++ --link -t hw --platform xilinx_u200_gen3x16_xdma_2_202110_1 --save-temps \
  --vivado.prop run.impl_1.STEPS.OPT_DESIGN.TCL.PRE=../constraints/timing.tcl \
  --vivado.prop run.impl_1.STEPS.PLACE_DESIGN.TCL.PRE=../constraints/pblocks.tcl \
  --vivado.synth.jobs 24 --vivado.impl.jobs 24 \
  --kernel_frequency 0:320 -o bin/picorv_sca.xclbin kernel.xo
#  --vivado.impl.strategies "Performance_ExplorePostRoutePhysOpt,Performance_ExtraTimingOpt" \
