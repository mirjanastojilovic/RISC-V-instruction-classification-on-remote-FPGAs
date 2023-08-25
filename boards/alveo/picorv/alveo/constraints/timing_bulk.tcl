# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

#set_false_path -from [get_clocks cpu_clk_clock_generator] -to [get_pins {level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[*].sensor/tdc0/measurment_chain_regs[*].obs_regs/D}]
#set_false_path -from [get_clocks sens_clk_clock_generator] -to [get_pins {level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[*].sensor/tdc0/measurment_chain_regs[*].obs_regs/D}]
#
#set_false_path -from [get_clocks *cpu_clk*] -to [get_pins {level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[*].sensor/tdc0/measurment_chain_regs[*].obs_regs/D}]
#set_false_path -from [get_clocks *sens_clk*] -to [get_pins {level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[*].sensor/tdc0/measurment_chain_regs[*].obs_regs/D}]

set_false_path -from [get_clocks *] -to [get_pins {level0_i/ulp/PicoRV32_SCA_kernel_1/U0/*/sensors/sensor_gen[*].sensor/tdc0/measurment_chain_regs[*].obs_regs/D}]
set_false_path -from [get_clocks *] -to [get_pins {level0_i/ulp/PicoRV32_SCA_kernel_1/U0/*/sensors/sensor_gen[*].sensor/tdc0/measurment_chain_regs[*].obs_regs/D}]

#set_false_path -from [get_pins {level0_i/ulp/PicoRV32_SCA_kernel_1/U0/CPU/inst_fetched_reg[*]/C}] -to [get_pins {level0_i/ulp/PicoRV32_SCA_kernel_1/U0/trace_bram/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[*].ram.r/prim_init.ram/DEVICE_8SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/DINADIN[*]}]
