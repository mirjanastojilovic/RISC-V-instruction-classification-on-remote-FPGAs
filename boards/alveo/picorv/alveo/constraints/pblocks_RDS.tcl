# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# TOP_SLR PBLOCK
create_pblock TOP_SLR
resize_pblock TOP_SLR -add {SLICE_X0Y600:SLICE_X82Y899 DSP48E2_X0Y240:DSP48E2_X18Y359 RAMB18_X0Y240:RAMB18_X11Y359 RAMB36_X0Y120:RAMB36_X11Y179 URAM288_X0Y160:URAM288_X3Y239 }
add_cells_to_pblock TOP_SLR [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/trace_bram]] -clear_locs
add_cells_to_pblock TOP_SLR [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/BramDumper]] -clear_locs

# VICTIM PBLOCK
create_pblock VICTIM
resize_pblock VICTIM -add {SLICE_X0Y660:SLICE_X82Y899 }

# SEPARATION PBLOCK
create_pblock SEPARATION
resize_pblock SEPARATION -add {SLICE_X83Y660:SLICE_X84Y899 }
set_property EXCLUDE_PLACEMENT 1 [get_pblocks SEPARATION]

# CPU PBLOCK
create_pblock CPU
resize_pblock CPU -add {SLICE_X60Y780:SLICE_X82Y839 DSP48E2_X9Y312:DSP48E2_X9Y335 RAMB18_X5Y312:RAMB18_X5Y335 RAMB36_X5Y156:RAMB36_X5Y167 URAM288_X1Y208:URAM288_X1Y223 }
add_cells_to_pblock CPU [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/CPU]] -clear_locs
set_property EXCLUDE_PLACEMENT 1 [get_pblocks CPU]

# ATTACKER PBLOCK
create_pblock ATTACKER
resize_pblock ATTACKER -add {SLICE_X85Y660:SLICE_X168Y899 }
add_cells_to_pblock ATTACKER [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[*].IDC_reg[*][*]]] -clear_locs
add_cells_to_pblock ATTACKER [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[*].IDF_reg[*][*]]] -clear_locs

# CTRL PBLOCK
create_pblock CTRL
resize_pblock CTRL -add {SLICE_X0Y600:SLICE_X168Y659 DSP48E2_X0Y240:DSP48E2_X18Y263 RAMB18_X0Y240:RAMB18_X11Y263 RAMB36_X0Y120:RAMB36_X11Y131 URAM288_X0Y160:URAM288_X3Y175 }
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiBRAMFlusher]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiLiteFSM]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiLoader]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/dump_sync]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/trap_sync]] -clear_locs

# Sensor 0
create_pblock sensor_0
resize_pblock sensor_0 -add {SLICE_X86Y720:SLICE_X86Y755}
add_cells_to_pblock sensor_0 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[1].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y720 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[1].sensor/tdc0/fine_init]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[1].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_0]

create_pblock pblock_REGISTERS_0
add_cells_to_pblock [get_pblocks pblock_REGISTERS_0] [get_cells level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[1].sensor/tdc0/measurement_regs[*].obs_regs]
resize_pblock [get_pblocks pblock_REGISTERS_0] -add {SLICE_X88Y720:SLICE_X91Y727}   
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_REGISTERS_0]

# Sensor 1
create_pblock sensor_1
resize_pblock sensor_1 -add {SLICE_X86Y780:SLICE_X86Y815}
add_cells_to_pblock sensor_1 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[2].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y780 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[2].sensor/tdc0/fine_init]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[2].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_1]

create_pblock pblock_REGISTERS_1
add_cells_to_pblock [get_pblocks pblock_REGISTERS_1] [get_cells level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[2].sensor/tdc0/measurement_regs[*].obs_regs]
resize_pblock [get_pblocks pblock_REGISTERS_1] -add {SLICE_X88Y780:SLICE_X91Y787}   
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_REGISTERS_1]

# Sensor 2
create_pblock sensor_2
resize_pblock sensor_2 -add {SLICE_X86Y840:SLICE_X86Y875}
add_cells_to_pblock sensor_2 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[3].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y840 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[3].sensor/tdc0/fine_init]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[3].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_2]

create_pblock pblock_REGISTERS_2
add_cells_to_pblock [get_pblocks pblock_REGISTERS_2] [get_cells level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[3].sensor/tdc0/measurement_regs[*].obs_regs]
resize_pblock [get_pblocks pblock_REGISTERS_2] -add {SLICE_X88Y840:SLICE_X91Y847}   
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_REGISTERS_2]
