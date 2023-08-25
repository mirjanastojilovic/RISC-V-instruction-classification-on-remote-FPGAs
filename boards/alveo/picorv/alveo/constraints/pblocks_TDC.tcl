# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# VICTIM PBLOCK
create_pblock VICTIM
resize_pblock VICTIM -add {SLICE_X0Y660:SLICE_X82Y899 DSP48E2_X0Y264:DSP48E2_X9Y359 RAMB18_X0Y264:RAMB18_X5Y359 RAMB36_X0Y132:RAMB36_X5Y179 URAM288_X0Y176:URAM288_X1Y239 }

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
resize_pblock ATTACKER -add {SLICE_X85Y660:SLICE_X168Y899 DSP48E2_X10Y264:DSP48E2_X18Y359 RAMB18_X6Y264:RAMB18_X11Y359 RAMB36_X6Y132:RAMB36_X11Y179 URAM288_X2Y176:URAM288_X3Y239 }
add_cells_to_pblock ATTACKER [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/trace_fifo]] -clear_locs
add_cells_to_pblock ATTACKER [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/FifoDumper]] -clear_locs
add_cells_to_pblock ATTACKER [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[*].IDC_reg[*][*]]] -clear_locs
add_cells_to_pblock ATTACKER [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[*].IDF_reg[*][*]]] -clear_locs

# CTRL PBLOCK
create_pblock CTRL
resize_pblock CTRL -add {SLICE_X0Y600:SLICE_X168Y659 DSP48E2_X0Y240:DSP48E2_X18Y263 RAMB18_X0Y240:RAMB18_X11Y263 RAMB36_X0Y120:RAMB36_X11Y131 URAM288_X0Y160:URAM288_X3Y175 }
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiFIFOFlusher]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiLiteFSM]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiLoader]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/dump_sync]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/trap_sync]] -clear_locs
# Sensor 0
create_pblock sensor_0
resize_pblock sensor_0 -add {SLICE_X86Y660:SLICE_X86Y680}
add_cells_to_pblock sensor_0 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[1].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[1].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[1].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_0]

# Sensor 1
create_pblock sensor_1
resize_pblock sensor_1 -add {SLICE_X87Y660:SLICE_X87Y680}
add_cells_to_pblock sensor_1 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[2].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[2].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[2].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_1]

# Sensor 2
create_pblock sensor_2
resize_pblock sensor_2 -add {SLICE_X88Y660:SLICE_X88Y680}
add_cells_to_pblock sensor_2 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[3].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[3].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[3].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_2]

# Sensor 3
create_pblock sensor_3
resize_pblock sensor_3 -add {SLICE_X89Y660:SLICE_X89Y680}
add_cells_to_pblock sensor_3 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[4].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X89Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[4].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[4].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_3]

# Sensor 4
create_pblock sensor_4
resize_pblock sensor_4 -add {SLICE_X90Y660:SLICE_X90Y680}
add_cells_to_pblock sensor_4 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[5].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X90Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[5].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[5].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_4]

# Sensor 5
create_pblock sensor_5
resize_pblock sensor_5 -add {SLICE_X86Y703:SLICE_X86Y723}
add_cells_to_pblock sensor_5 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[6].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[6].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[6].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_5]

# Sensor 6
create_pblock sensor_6
resize_pblock sensor_6 -add {SLICE_X87Y703:SLICE_X87Y723}
add_cells_to_pblock sensor_6 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[7].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[7].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[7].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_6]

# Sensor 7
create_pblock sensor_7
resize_pblock sensor_7 -add {SLICE_X88Y703:SLICE_X88Y723}
add_cells_to_pblock sensor_7 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[8].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[8].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[8].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_7]

# Sensor 8
create_pblock sensor_8
resize_pblock sensor_8 -add {SLICE_X89Y703:SLICE_X89Y723}
add_cells_to_pblock sensor_8 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[9].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X89Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[9].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[9].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_8]

# Sensor 9
create_pblock sensor_9
resize_pblock sensor_9 -add {SLICE_X90Y703:SLICE_X90Y723}
add_cells_to_pblock sensor_9 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[10].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X90Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[10].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[10].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_9]

# Sensor 10
create_pblock sensor_10
resize_pblock sensor_10 -add {SLICE_X86Y746:SLICE_X86Y766}
add_cells_to_pblock sensor_10 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[11].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[11].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[11].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_10]

# Sensor 11
create_pblock sensor_11
resize_pblock sensor_11 -add {SLICE_X87Y746:SLICE_X87Y766}
add_cells_to_pblock sensor_11 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[12].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[12].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[12].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_11]

# Sensor 12
create_pblock sensor_12
resize_pblock sensor_12 -add {SLICE_X88Y746:SLICE_X88Y766}
add_cells_to_pblock sensor_12 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[13].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[13].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[13].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_12]

# Sensor 13
create_pblock sensor_13
resize_pblock sensor_13 -add {SLICE_X89Y746:SLICE_X89Y766}
add_cells_to_pblock sensor_13 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[14].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X89Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[14].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[14].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_13]

# Sensor 14
create_pblock sensor_14
resize_pblock sensor_14 -add {SLICE_X90Y746:SLICE_X90Y766}
add_cells_to_pblock sensor_14 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[15].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X90Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[15].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[15].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_14]

# Sensor 15
create_pblock sensor_15
resize_pblock sensor_15 -add {SLICE_X86Y789:SLICE_X86Y809}
add_cells_to_pblock sensor_15 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[16].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[16].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[16].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_15]

# Sensor 16
create_pblock sensor_16
resize_pblock sensor_16 -add {SLICE_X87Y789:SLICE_X87Y809}
add_cells_to_pblock sensor_16 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[17].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[17].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[17].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_16]

# Sensor 17
create_pblock sensor_17
resize_pblock sensor_17 -add {SLICE_X88Y789:SLICE_X88Y809}
add_cells_to_pblock sensor_17 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[18].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[18].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[18].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_17]

# Sensor 18
create_pblock sensor_18
resize_pblock sensor_18 -add {SLICE_X89Y789:SLICE_X89Y809}
add_cells_to_pblock sensor_18 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[19].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X89Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[19].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[19].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_18]

# Sensor 19
create_pblock sensor_19
resize_pblock sensor_19 -add {SLICE_X90Y789:SLICE_X90Y809}
add_cells_to_pblock sensor_19 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[20].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X90Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[20].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[20].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_19]

# Sensor 20
create_pblock sensor_20
resize_pblock sensor_20 -add {SLICE_X86Y832:SLICE_X86Y852}
add_cells_to_pblock sensor_20 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[21].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[21].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[21].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_20]

# Sensor 21
create_pblock sensor_21
resize_pblock sensor_21 -add {SLICE_X87Y832:SLICE_X87Y852}
add_cells_to_pblock sensor_21 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[22].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[22].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[22].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_21]

# Sensor 22
create_pblock sensor_22
resize_pblock sensor_22 -add {SLICE_X88Y832:SLICE_X88Y852}
add_cells_to_pblock sensor_22 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[23].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[23].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[23].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_22]

# Sensor 23
create_pblock sensor_23
resize_pblock sensor_23 -add {SLICE_X89Y832:SLICE_X89Y852}
add_cells_to_pblock sensor_23 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[24].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X89Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[24].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[24].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_23]

# Sensor 24
create_pblock sensor_24
resize_pblock sensor_24 -add {SLICE_X91Y832:SLICE_X91Y852}
add_cells_to_pblock sensor_24 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[25].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X91Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[25].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[25].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_24]

# Sensor 25
create_pblock sensor_25
resize_pblock sensor_25 -add {SLICE_X86Y875:SLICE_X86Y895}
add_cells_to_pblock sensor_25 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[26].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[26].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[26].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_25]

# Sensor 26
create_pblock sensor_26
resize_pblock sensor_26 -add {SLICE_X87Y875:SLICE_X87Y895}
add_cells_to_pblock sensor_26 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[27].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[27].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[27].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_26]

# Sensor 27
create_pblock sensor_27
resize_pblock sensor_27 -add {SLICE_X88Y875:SLICE_X88Y895}
add_cells_to_pblock sensor_27 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[28].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[28].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[28].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_27]

# Sensor 28
create_pblock sensor_28
resize_pblock sensor_28 -add {SLICE_X89Y875:SLICE_X89Y895}
add_cells_to_pblock sensor_28 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[29].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X89Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[29].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/sensors/sensor_gen[29].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_28]
