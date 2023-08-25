# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# TOP_SLR PBLOCK
create_pblock TOP_SLR
resize_pblock TOP_SLR -add {SLICE_X0Y600:SLICE_X83Y899 DSP48E2_X0Y240:DSP48E2_X18Y359 RAMB18_X0Y240:RAMB18_X11Y359 RAMB36_X0Y120:RAMB36_X11Y179 URAM288_X0Y160:URAM288_X3Y239 }
add_cells_to_pblock TOP_SLR [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[*]*/trace_bram]] -clear_locs
add_cells_to_pblock TOP_SLR [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[*]*/BramDumper]] -clear_locs

# VICTIM PBLOCK
create_pblock VICTIM
resize_pblock VICTIM -add {SLICE_X0Y720:SLICE_X83Y899 }

# CPU PBLOCK
create_pblock CPU
resize_pblock CPU -add {SLICE_X60Y780:SLICE_X82Y839 DSP48E2_X9Y312:DSP48E2_X9Y335 RAMB18_X5Y312:RAMB18_X5Y335 RAMB36_X5Y156:RAMB36_X5Y167 URAM288_X1Y208:URAM288_X1Y223 }
add_cells_to_pblock CPU [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/CPU]] -clear_locs
set_property EXCLUDE_PLACEMENT 1 [get_pblocks CPU]

# ATTACKER PBLOCK
create_pblock ATTACKER
resize_pblock ATTACKER -add {SLICE_X84Y660:SLICE_X168Y899 }

# CTRL PBLOCK
create_pblock CTRL
resize_pblock CTRL -add {SLICE_X0Y600:SLICE_X168Y659 SLICE_X0Y660:SLICE_X82Y719 DSP48E2_X0Y240:DSP48E2_X18Y263 RAMB18_X0Y240:RAMB18_X11Y263 RAMB36_X0Y120:RAMB36_X11Y131 URAM288_X0Y160:URAM288_X3Y175 }
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiBRAMFlusher]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiLiteFSM]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/AxiLoader]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/dump_sync]] -clear_locs
add_cells_to_pblock CTRL [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/trap_sync]] -clear_locs
# Sensor 0: BANK 0 SENSOR 1
create_pblock sensor_0
resize_pblock sensor_0 -add {SLICE_X84Y660:SLICE_X84Y680}
add_cells_to_pblock sensor_0 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[1].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X84Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[1].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[1].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_0]

# Sensor 1: BANK 0 SENSOR 2
create_pblock sensor_1
resize_pblock sensor_1 -add {SLICE_X85Y660:SLICE_X85Y680}
add_cells_to_pblock sensor_1 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[2].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X85Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[2].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[2].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_1]

# Sensor 2: BANK 0 SENSOR 3
create_pblock sensor_2
resize_pblock sensor_2 -add {SLICE_X86Y660:SLICE_X86Y680}
add_cells_to_pblock sensor_2 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[3].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[3].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[3].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_2]

# Sensor 3: BANK 0 SENSOR 4
create_pblock sensor_3
resize_pblock sensor_3 -add {SLICE_X87Y660:SLICE_X87Y680}
add_cells_to_pblock sensor_3 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[4].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[4].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[4].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_3]

# Sensor 4: BANK 0 SENSOR 5
create_pblock sensor_4
resize_pblock sensor_4 -add {SLICE_X88Y660:SLICE_X88Y680}
add_cells_to_pblock sensor_4 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[5].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[5].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[5].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_4]

# Sensor 5: BANK 0 SENSOR 6
create_pblock sensor_5
resize_pblock sensor_5 -add {SLICE_X84Y703:SLICE_X84Y723}
add_cells_to_pblock sensor_5 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[6].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X84Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[6].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[6].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_5]

# Sensor 6: BANK 0 SENSOR 7
create_pblock sensor_6
resize_pblock sensor_6 -add {SLICE_X85Y703:SLICE_X85Y723}
add_cells_to_pblock sensor_6 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[7].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X85Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[7].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[7].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_6]

# Sensor 7: BANK 0 SENSOR 8
create_pblock sensor_7
resize_pblock sensor_7 -add {SLICE_X86Y703:SLICE_X86Y723}
add_cells_to_pblock sensor_7 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[8].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[8].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[8].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_7]

# Sensor 8: BANK 0 SENSOR 9
create_pblock sensor_8
resize_pblock sensor_8 -add {SLICE_X87Y703:SLICE_X87Y723}
add_cells_to_pblock sensor_8 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[9].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[9].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[9].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_8]

# Sensor 9: BANK 0 SENSOR 10
create_pblock sensor_9
resize_pblock sensor_9 -add {SLICE_X88Y703:SLICE_X88Y723}
add_cells_to_pblock sensor_9 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[10].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[10].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[10].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_9]

# Sensor 10: BANK 0 SENSOR 11
create_pblock sensor_10
resize_pblock sensor_10 -add {SLICE_X84Y746:SLICE_X84Y766}
add_cells_to_pblock sensor_10 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[11].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X84Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[11].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[11].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_10]

# Sensor 11: BANK 0 SENSOR 12
create_pblock sensor_11
resize_pblock sensor_11 -add {SLICE_X85Y746:SLICE_X85Y766}
add_cells_to_pblock sensor_11 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[12].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X85Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[12].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[12].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_11]

# Sensor 12: BANK 0 SENSOR 13
create_pblock sensor_12
resize_pblock sensor_12 -add {SLICE_X86Y746:SLICE_X86Y766}
add_cells_to_pblock sensor_12 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[13].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[13].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[13].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_12]

# Sensor 13: BANK 0 SENSOR 14
create_pblock sensor_13
resize_pblock sensor_13 -add {SLICE_X87Y746:SLICE_X87Y766}
add_cells_to_pblock sensor_13 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[14].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[14].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[14].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_13]

# Sensor 14: BANK 0 SENSOR 15
create_pblock sensor_14
resize_pblock sensor_14 -add {SLICE_X88Y746:SLICE_X88Y766}
add_cells_to_pblock sensor_14 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[15].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[15].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[15].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_14]

# Sensor 15: BANK 0 SENSOR 16
create_pblock sensor_15
resize_pblock sensor_15 -add {SLICE_X84Y789:SLICE_X84Y809}
add_cells_to_pblock sensor_15 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[16].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X84Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[16].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[16].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_15]

# Sensor 16: BANK 0 SENSOR 17
create_pblock sensor_16
resize_pblock sensor_16 -add {SLICE_X85Y789:SLICE_X85Y809}
add_cells_to_pblock sensor_16 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[17].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X85Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[17].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[17].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_16]

# Sensor 17: BANK 0 SENSOR 18
create_pblock sensor_17
resize_pblock sensor_17 -add {SLICE_X86Y789:SLICE_X86Y809}
add_cells_to_pblock sensor_17 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[18].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[18].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[18].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_17]

# Sensor 18: BANK 0 SENSOR 19
create_pblock sensor_18
resize_pblock sensor_18 -add {SLICE_X87Y789:SLICE_X87Y809}
add_cells_to_pblock sensor_18 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[19].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[19].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[19].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_18]

# Sensor 19: BANK 0 SENSOR 20
create_pblock sensor_19
resize_pblock sensor_19 -add {SLICE_X88Y789:SLICE_X88Y809}
add_cells_to_pblock sensor_19 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[20].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[20].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[20].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_19]

# Sensor 20: BANK 0 SENSOR 21
create_pblock sensor_20
resize_pblock sensor_20 -add {SLICE_X84Y832:SLICE_X84Y852}
add_cells_to_pblock sensor_20 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[21].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X84Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[21].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[21].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_20]

# Sensor 21: BANK 0 SENSOR 22
create_pblock sensor_21
resize_pblock sensor_21 -add {SLICE_X85Y832:SLICE_X85Y852}
add_cells_to_pblock sensor_21 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[22].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X85Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[22].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[22].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_21]

# Sensor 22: BANK 0 SENSOR 23
create_pblock sensor_22
resize_pblock sensor_22 -add {SLICE_X86Y832:SLICE_X86Y852}
add_cells_to_pblock sensor_22 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[23].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[23].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[23].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_22]

# Sensor 23: BANK 0 SENSOR 24
create_pblock sensor_23
resize_pblock sensor_23 -add {SLICE_X87Y832:SLICE_X87Y852}
add_cells_to_pblock sensor_23 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[24].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[24].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[24].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_23]

# Sensor 24: BANK 0 SENSOR 25
create_pblock sensor_24
resize_pblock sensor_24 -add {SLICE_X88Y832:SLICE_X88Y852}
add_cells_to_pblock sensor_24 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[25].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[25].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[25].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_24]

# Sensor 25: BANK 0 SENSOR 26
create_pblock sensor_25
resize_pblock sensor_25 -add {SLICE_X84Y875:SLICE_X84Y895}
add_cells_to_pblock sensor_25 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[26].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X84Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[26].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[26].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_25]

# Sensor 26: BANK 0 SENSOR 27
create_pblock sensor_26
resize_pblock sensor_26 -add {SLICE_X85Y875:SLICE_X85Y895}
add_cells_to_pblock sensor_26 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[27].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X85Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[27].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[27].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_26]

# Sensor 27: BANK 0 SENSOR 28
create_pblock sensor_27
resize_pblock sensor_27 -add {SLICE_X86Y875:SLICE_X86Y895}
add_cells_to_pblock sensor_27 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[28].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X86Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[28].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[28].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_27]

# Sensor 28: BANK 0 SENSOR 29
create_pblock sensor_28
resize_pblock sensor_28 -add {SLICE_X87Y875:SLICE_X87Y895}
add_cells_to_pblock sensor_28 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[29].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X87Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[29].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[29].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_28]

# Sensor 29: BANK 0 SENSOR 30
create_pblock sensor_29
resize_pblock sensor_29 -add {SLICE_X88Y875:SLICE_X88Y895}
add_cells_to_pblock sensor_29 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[30].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X88Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[30].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[0]*/sensors/sensor_gen[30].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_29]

# Sensor 30: BANK 1 SENSOR 1
create_pblock sensor_30
resize_pblock sensor_30 -add {SLICE_X99Y660:SLICE_X99Y680}
add_cells_to_pblock sensor_30 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[1].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X99Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[1].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[1].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_30]

# Sensor 31: BANK 1 SENSOR 2
create_pblock sensor_31
resize_pblock sensor_31 -add {SLICE_X100Y660:SLICE_X100Y680}
add_cells_to_pblock sensor_31 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[2].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X100Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[2].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[2].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_31]

# Sensor 32: BANK 1 SENSOR 3
create_pblock sensor_32
resize_pblock sensor_32 -add {SLICE_X101Y660:SLICE_X101Y680}
add_cells_to_pblock sensor_32 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[3].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X101Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[3].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[3].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_32]

# Sensor 33: BANK 1 SENSOR 4
create_pblock sensor_33
resize_pblock sensor_33 -add {SLICE_X102Y660:SLICE_X102Y680}
add_cells_to_pblock sensor_33 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[4].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X102Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[4].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[4].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_33]

# Sensor 34: BANK 1 SENSOR 5
create_pblock sensor_34
resize_pblock sensor_34 -add {SLICE_X103Y660:SLICE_X103Y680}
add_cells_to_pblock sensor_34 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[5].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X103Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[5].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[5].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_34]

# Sensor 35: BANK 1 SENSOR 6
create_pblock sensor_35
resize_pblock sensor_35 -add {SLICE_X99Y703:SLICE_X99Y723}
add_cells_to_pblock sensor_35 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[6].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X99Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[6].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[6].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_35]

# Sensor 36: BANK 1 SENSOR 7
create_pblock sensor_36
resize_pblock sensor_36 -add {SLICE_X100Y703:SLICE_X100Y723}
add_cells_to_pblock sensor_36 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[7].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X100Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[7].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[7].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_36]

# Sensor 37: BANK 1 SENSOR 8
create_pblock sensor_37
resize_pblock sensor_37 -add {SLICE_X101Y703:SLICE_X101Y723}
add_cells_to_pblock sensor_37 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[8].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X101Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[8].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[8].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_37]

# Sensor 38: BANK 1 SENSOR 9
create_pblock sensor_38
resize_pblock sensor_38 -add {SLICE_X102Y703:SLICE_X102Y723}
add_cells_to_pblock sensor_38 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[9].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X102Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[9].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[9].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_38]

# Sensor 39: BANK 1 SENSOR 10
create_pblock sensor_39
resize_pblock sensor_39 -add {SLICE_X103Y703:SLICE_X103Y723}
add_cells_to_pblock sensor_39 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[10].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X103Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[10].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[10].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_39]

# Sensor 40: BANK 1 SENSOR 11
create_pblock sensor_40
resize_pblock sensor_40 -add {SLICE_X99Y746:SLICE_X99Y766}
add_cells_to_pblock sensor_40 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[11].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X99Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[11].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[11].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_40]

# Sensor 41: BANK 1 SENSOR 12
create_pblock sensor_41
resize_pblock sensor_41 -add {SLICE_X100Y746:SLICE_X100Y766}
add_cells_to_pblock sensor_41 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[12].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X100Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[12].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[12].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_41]

# Sensor 42: BANK 1 SENSOR 13
create_pblock sensor_42
resize_pblock sensor_42 -add {SLICE_X101Y746:SLICE_X101Y766}
add_cells_to_pblock sensor_42 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[13].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X101Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[13].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[13].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_42]

# Sensor 43: BANK 1 SENSOR 14
create_pblock sensor_43
resize_pblock sensor_43 -add {SLICE_X102Y746:SLICE_X102Y766}
add_cells_to_pblock sensor_43 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[14].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X102Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[14].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[14].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_43]

# Sensor 44: BANK 1 SENSOR 15
create_pblock sensor_44
resize_pblock sensor_44 -add {SLICE_X103Y746:SLICE_X103Y766}
add_cells_to_pblock sensor_44 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[15].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X103Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[15].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[15].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_44]

# Sensor 45: BANK 1 SENSOR 16
create_pblock sensor_45
resize_pblock sensor_45 -add {SLICE_X99Y789:SLICE_X99Y809}
add_cells_to_pblock sensor_45 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[16].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X99Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[16].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[16].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_45]

# Sensor 46: BANK 1 SENSOR 17
create_pblock sensor_46
resize_pblock sensor_46 -add {SLICE_X100Y789:SLICE_X100Y809}
add_cells_to_pblock sensor_46 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[17].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X100Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[17].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[17].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_46]

# Sensor 47: BANK 1 SENSOR 18
create_pblock sensor_47
resize_pblock sensor_47 -add {SLICE_X101Y789:SLICE_X101Y809}
add_cells_to_pblock sensor_47 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[18].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X101Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[18].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[18].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_47]

# Sensor 48: BANK 1 SENSOR 19
create_pblock sensor_48
resize_pblock sensor_48 -add {SLICE_X102Y789:SLICE_X102Y809}
add_cells_to_pblock sensor_48 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[19].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X102Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[19].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[19].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_48]

# Sensor 49: BANK 1 SENSOR 20
create_pblock sensor_49
resize_pblock sensor_49 -add {SLICE_X103Y789:SLICE_X103Y809}
add_cells_to_pblock sensor_49 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[20].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X103Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[20].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[20].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_49]

# Sensor 50: BANK 1 SENSOR 21
create_pblock sensor_50
resize_pblock sensor_50 -add {SLICE_X99Y832:SLICE_X99Y852}
add_cells_to_pblock sensor_50 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[21].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X99Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[21].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[21].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_50]

# Sensor 51: BANK 1 SENSOR 22
create_pblock sensor_51
resize_pblock sensor_51 -add {SLICE_X100Y832:SLICE_X100Y852}
add_cells_to_pblock sensor_51 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[22].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X100Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[22].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[22].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_51]

# Sensor 52: BANK 1 SENSOR 23
create_pblock sensor_52
resize_pblock sensor_52 -add {SLICE_X101Y832:SLICE_X101Y852}
add_cells_to_pblock sensor_52 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[23].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X101Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[23].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[23].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_52]

# Sensor 53: BANK 1 SENSOR 24
create_pblock sensor_53
resize_pblock sensor_53 -add {SLICE_X102Y832:SLICE_X102Y852}
add_cells_to_pblock sensor_53 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[24].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X102Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[24].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[24].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_53]

# Sensor 54: BANK 1 SENSOR 25
create_pblock sensor_54
resize_pblock sensor_54 -add {SLICE_X103Y832:SLICE_X103Y852}
add_cells_to_pblock sensor_54 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[25].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X103Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[25].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[25].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_54]

# Sensor 55: BANK 1 SENSOR 26
create_pblock sensor_55
resize_pblock sensor_55 -add {SLICE_X99Y875:SLICE_X99Y895}
add_cells_to_pblock sensor_55 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[26].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X99Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[26].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[26].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_55]

# Sensor 56: BANK 1 SENSOR 27
create_pblock sensor_56
resize_pblock sensor_56 -add {SLICE_X100Y875:SLICE_X100Y895}
add_cells_to_pblock sensor_56 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[27].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X100Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[27].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[27].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_56]

# Sensor 57: BANK 1 SENSOR 28
create_pblock sensor_57
resize_pblock sensor_57 -add {SLICE_X101Y875:SLICE_X101Y895}
add_cells_to_pblock sensor_57 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[28].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X101Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[28].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[28].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_57]

# Sensor 58: BANK 1 SENSOR 29
create_pblock sensor_58
resize_pblock sensor_58 -add {SLICE_X102Y875:SLICE_X102Y895}
add_cells_to_pblock sensor_58 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[29].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X102Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[29].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[29].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_58]

# Sensor 59: BANK 1 SENSOR 30
create_pblock sensor_59
resize_pblock sensor_59 -add {SLICE_X103Y875:SLICE_X103Y895}
add_cells_to_pblock sensor_59 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[30].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X103Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[30].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[1]*/sensors/sensor_gen[30].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_59]

# Sensor 60: BANK 2 SENSOR 1
create_pblock sensor_60
resize_pblock sensor_60 -add {SLICE_X114Y660:SLICE_X114Y680}
add_cells_to_pblock sensor_60 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[1].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X114Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[1].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[1].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_60]

# Sensor 61: BANK 2 SENSOR 2
create_pblock sensor_61
resize_pblock sensor_61 -add {SLICE_X115Y660:SLICE_X115Y680}
add_cells_to_pblock sensor_61 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[2].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X115Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[2].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[2].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_61]

# Sensor 62: BANK 2 SENSOR 3
create_pblock sensor_62
resize_pblock sensor_62 -add {SLICE_X116Y660:SLICE_X116Y680}
add_cells_to_pblock sensor_62 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[3].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X116Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[3].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[3].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_62]

# Sensor 63: BANK 2 SENSOR 4
create_pblock sensor_63
resize_pblock sensor_63 -add {SLICE_X117Y660:SLICE_X117Y680}
add_cells_to_pblock sensor_63 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[4].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X117Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[4].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[4].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_63]

# Sensor 64: BANK 2 SENSOR 5
create_pblock sensor_64
resize_pblock sensor_64 -add {SLICE_X118Y660:SLICE_X118Y680}
add_cells_to_pblock sensor_64 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[5].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X118Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[5].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[5].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_64]

# Sensor 65: BANK 2 SENSOR 6
create_pblock sensor_65
resize_pblock sensor_65 -add {SLICE_X114Y703:SLICE_X114Y723}
add_cells_to_pblock sensor_65 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[6].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X114Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[6].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[6].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_65]

# Sensor 66: BANK 2 SENSOR 7
create_pblock sensor_66
resize_pblock sensor_66 -add {SLICE_X115Y703:SLICE_X115Y723}
add_cells_to_pblock sensor_66 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[7].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X115Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[7].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[7].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_66]

# Sensor 67: BANK 2 SENSOR 8
create_pblock sensor_67
resize_pblock sensor_67 -add {SLICE_X116Y703:SLICE_X116Y723}
add_cells_to_pblock sensor_67 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[8].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X116Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[8].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[8].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_67]

# Sensor 68: BANK 2 SENSOR 9
create_pblock sensor_68
resize_pblock sensor_68 -add {SLICE_X117Y703:SLICE_X117Y723}
add_cells_to_pblock sensor_68 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[9].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X117Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[9].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[9].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_68]

# Sensor 69: BANK 2 SENSOR 10
create_pblock sensor_69
resize_pblock sensor_69 -add {SLICE_X118Y703:SLICE_X118Y723}
add_cells_to_pblock sensor_69 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[10].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X118Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[10].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[10].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_69]

# Sensor 70: BANK 2 SENSOR 11
create_pblock sensor_70
resize_pblock sensor_70 -add {SLICE_X114Y746:SLICE_X114Y766}
add_cells_to_pblock sensor_70 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[11].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X114Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[11].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[11].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_70]

# Sensor 71: BANK 2 SENSOR 12
create_pblock sensor_71
resize_pblock sensor_71 -add {SLICE_X115Y746:SLICE_X115Y766}
add_cells_to_pblock sensor_71 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[12].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X115Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[12].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[12].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_71]

# Sensor 72: BANK 2 SENSOR 13
create_pblock sensor_72
resize_pblock sensor_72 -add {SLICE_X116Y746:SLICE_X116Y766}
add_cells_to_pblock sensor_72 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[13].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X116Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[13].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[13].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_72]

# Sensor 73: BANK 2 SENSOR 14
create_pblock sensor_73
resize_pblock sensor_73 -add {SLICE_X117Y746:SLICE_X117Y766}
add_cells_to_pblock sensor_73 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[14].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X117Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[14].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[14].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_73]

# Sensor 74: BANK 2 SENSOR 15
create_pblock sensor_74
resize_pblock sensor_74 -add {SLICE_X118Y746:SLICE_X118Y766}
add_cells_to_pblock sensor_74 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[15].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X118Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[15].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[15].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_74]

# Sensor 75: BANK 2 SENSOR 16
create_pblock sensor_75
resize_pblock sensor_75 -add {SLICE_X114Y789:SLICE_X114Y809}
add_cells_to_pblock sensor_75 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[16].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X114Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[16].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[16].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_75]

# Sensor 76: BANK 2 SENSOR 17
create_pblock sensor_76
resize_pblock sensor_76 -add {SLICE_X115Y789:SLICE_X115Y809}
add_cells_to_pblock sensor_76 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[17].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X115Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[17].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[17].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_76]

# Sensor 77: BANK 2 SENSOR 18
create_pblock sensor_77
resize_pblock sensor_77 -add {SLICE_X116Y789:SLICE_X116Y809}
add_cells_to_pblock sensor_77 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[18].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X116Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[18].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[18].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_77]

# Sensor 78: BANK 2 SENSOR 19
create_pblock sensor_78
resize_pblock sensor_78 -add {SLICE_X117Y789:SLICE_X117Y809}
add_cells_to_pblock sensor_78 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[19].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X117Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[19].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[19].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_78]

# Sensor 79: BANK 2 SENSOR 20
create_pblock sensor_79
resize_pblock sensor_79 -add {SLICE_X118Y789:SLICE_X118Y809}
add_cells_to_pblock sensor_79 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[20].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X118Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[20].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[20].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_79]

# Sensor 80: BANK 2 SENSOR 21
create_pblock sensor_80
resize_pblock sensor_80 -add {SLICE_X114Y832:SLICE_X114Y852}
add_cells_to_pblock sensor_80 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[21].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X114Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[21].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[21].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_80]

# Sensor 81: BANK 2 SENSOR 22
create_pblock sensor_81
resize_pblock sensor_81 -add {SLICE_X115Y832:SLICE_X115Y852}
add_cells_to_pblock sensor_81 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[22].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X115Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[22].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[22].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_81]

# Sensor 82: BANK 2 SENSOR 23
create_pblock sensor_82
resize_pblock sensor_82 -add {SLICE_X116Y832:SLICE_X116Y852}
add_cells_to_pblock sensor_82 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[23].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X116Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[23].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[23].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_82]

# Sensor 83: BANK 2 SENSOR 24
create_pblock sensor_83
resize_pblock sensor_83 -add {SLICE_X117Y832:SLICE_X117Y852}
add_cells_to_pblock sensor_83 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[24].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X117Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[24].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[24].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_83]

# Sensor 84: BANK 2 SENSOR 25
create_pblock sensor_84
resize_pblock sensor_84 -add {SLICE_X118Y832:SLICE_X118Y852}
add_cells_to_pblock sensor_84 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[25].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X118Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[25].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[25].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_84]

# Sensor 85: BANK 2 SENSOR 26
create_pblock sensor_85
resize_pblock sensor_85 -add {SLICE_X114Y875:SLICE_X114Y895}
add_cells_to_pblock sensor_85 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[26].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X114Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[26].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[26].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_85]

# Sensor 86: BANK 2 SENSOR 27
create_pblock sensor_86
resize_pblock sensor_86 -add {SLICE_X115Y875:SLICE_X115Y895}
add_cells_to_pblock sensor_86 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[27].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X115Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[27].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[27].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_86]

# Sensor 87: BANK 2 SENSOR 28
create_pblock sensor_87
resize_pblock sensor_87 -add {SLICE_X116Y875:SLICE_X116Y895}
add_cells_to_pblock sensor_87 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[28].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X116Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[28].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[28].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_87]

# Sensor 88: BANK 2 SENSOR 29
create_pblock sensor_88
resize_pblock sensor_88 -add {SLICE_X117Y875:SLICE_X117Y895}
add_cells_to_pblock sensor_88 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[29].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X117Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[29].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[29].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_88]

# Sensor 89: BANK 2 SENSOR 30
create_pblock sensor_89
resize_pblock sensor_89 -add {SLICE_X118Y875:SLICE_X118Y895}
add_cells_to_pblock sensor_89 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[30].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X118Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[30].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[2]*/sensors/sensor_gen[30].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_89]

# Sensor 90: BANK 3 SENSOR 1
create_pblock sensor_90
resize_pblock sensor_90 -add {SLICE_X129Y660:SLICE_X129Y680}
add_cells_to_pblock sensor_90 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[1].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X129Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[1].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[1].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_90]

# Sensor 91: BANK 3 SENSOR 2
create_pblock sensor_91
resize_pblock sensor_91 -add {SLICE_X130Y660:SLICE_X130Y680}
add_cells_to_pblock sensor_91 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[2].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X130Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[2].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[2].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_91]

# Sensor 92: BANK 3 SENSOR 3
create_pblock sensor_92
resize_pblock sensor_92 -add {SLICE_X131Y660:SLICE_X131Y680}
add_cells_to_pblock sensor_92 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[3].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X131Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[3].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[3].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_92]

# Sensor 93: BANK 3 SENSOR 4
create_pblock sensor_93
resize_pblock sensor_93 -add {SLICE_X132Y660:SLICE_X132Y680}
add_cells_to_pblock sensor_93 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[4].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X132Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[4].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[4].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_93]

# Sensor 94: BANK 3 SENSOR 5
create_pblock sensor_94
resize_pblock sensor_94 -add {SLICE_X133Y660:SLICE_X133Y680}
add_cells_to_pblock sensor_94 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[5].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X133Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[5].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[5].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_94]

# Sensor 95: BANK 3 SENSOR 6
create_pblock sensor_95
resize_pblock sensor_95 -add {SLICE_X129Y703:SLICE_X129Y723}
add_cells_to_pblock sensor_95 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[6].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X129Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[6].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[6].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_95]

# Sensor 96: BANK 3 SENSOR 7
create_pblock sensor_96
resize_pblock sensor_96 -add {SLICE_X130Y703:SLICE_X130Y723}
add_cells_to_pblock sensor_96 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[7].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X130Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[7].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[7].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_96]

# Sensor 97: BANK 3 SENSOR 8
create_pblock sensor_97
resize_pblock sensor_97 -add {SLICE_X131Y703:SLICE_X131Y723}
add_cells_to_pblock sensor_97 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[8].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X131Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[8].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[8].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_97]

# Sensor 98: BANK 3 SENSOR 9
create_pblock sensor_98
resize_pblock sensor_98 -add {SLICE_X132Y703:SLICE_X132Y723}
add_cells_to_pblock sensor_98 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[9].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X132Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[9].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[9].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_98]

# Sensor 99: BANK 3 SENSOR 10
create_pblock sensor_99
resize_pblock sensor_99 -add {SLICE_X133Y703:SLICE_X133Y723}
add_cells_to_pblock sensor_99 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[10].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X133Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[10].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[10].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_99]

# Sensor 100: BANK 3 SENSOR 11
create_pblock sensor_100
resize_pblock sensor_100 -add {SLICE_X129Y746:SLICE_X129Y766}
add_cells_to_pblock sensor_100 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[11].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X129Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[11].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[11].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_100]

# Sensor 101: BANK 3 SENSOR 12
create_pblock sensor_101
resize_pblock sensor_101 -add {SLICE_X130Y746:SLICE_X130Y766}
add_cells_to_pblock sensor_101 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[12].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X130Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[12].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[12].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_101]

# Sensor 102: BANK 3 SENSOR 13
create_pblock sensor_102
resize_pblock sensor_102 -add {SLICE_X131Y746:SLICE_X131Y766}
add_cells_to_pblock sensor_102 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[13].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X131Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[13].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[13].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_102]

# Sensor 103: BANK 3 SENSOR 14
create_pblock sensor_103
resize_pblock sensor_103 -add {SLICE_X132Y746:SLICE_X132Y766}
add_cells_to_pblock sensor_103 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[14].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X132Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[14].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[14].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_103]

# Sensor 104: BANK 3 SENSOR 15
create_pblock sensor_104
resize_pblock sensor_104 -add {SLICE_X133Y746:SLICE_X133Y766}
add_cells_to_pblock sensor_104 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[15].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X133Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[15].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[15].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_104]

# Sensor 105: BANK 3 SENSOR 16
create_pblock sensor_105
resize_pblock sensor_105 -add {SLICE_X129Y789:SLICE_X129Y809}
add_cells_to_pblock sensor_105 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[16].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X129Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[16].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[16].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_105]

# Sensor 106: BANK 3 SENSOR 17
create_pblock sensor_106
resize_pblock sensor_106 -add {SLICE_X130Y789:SLICE_X130Y809}
add_cells_to_pblock sensor_106 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[17].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X130Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[17].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[17].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_106]

# Sensor 107: BANK 3 SENSOR 18
create_pblock sensor_107
resize_pblock sensor_107 -add {SLICE_X131Y789:SLICE_X131Y809}
add_cells_to_pblock sensor_107 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[18].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X131Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[18].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[18].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_107]

# Sensor 108: BANK 3 SENSOR 19
create_pblock sensor_108
resize_pblock sensor_108 -add {SLICE_X132Y789:SLICE_X132Y809}
add_cells_to_pblock sensor_108 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[19].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X132Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[19].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[19].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_108]

# Sensor 109: BANK 3 SENSOR 20
create_pblock sensor_109
resize_pblock sensor_109 -add {SLICE_X133Y789:SLICE_X133Y809}
add_cells_to_pblock sensor_109 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[20].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X133Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[20].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[20].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_109]

# Sensor 110: BANK 3 SENSOR 21
create_pblock sensor_110
resize_pblock sensor_110 -add {SLICE_X129Y832:SLICE_X129Y852}
add_cells_to_pblock sensor_110 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[21].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X129Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[21].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[21].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_110]

# Sensor 111: BANK 3 SENSOR 22
create_pblock sensor_111
resize_pblock sensor_111 -add {SLICE_X130Y832:SLICE_X130Y852}
add_cells_to_pblock sensor_111 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[22].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X130Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[22].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[22].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_111]

# Sensor 112: BANK 3 SENSOR 23
create_pblock sensor_112
resize_pblock sensor_112 -add {SLICE_X131Y832:SLICE_X131Y852}
add_cells_to_pblock sensor_112 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[23].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X131Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[23].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[23].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_112]

# Sensor 113: BANK 3 SENSOR 24
create_pblock sensor_113
resize_pblock sensor_113 -add {SLICE_X132Y832:SLICE_X132Y852}
add_cells_to_pblock sensor_113 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[24].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X132Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[24].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[24].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_113]

# Sensor 114: BANK 3 SENSOR 25
create_pblock sensor_114
resize_pblock sensor_114 -add {SLICE_X133Y832:SLICE_X133Y852}
add_cells_to_pblock sensor_114 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[25].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X133Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[25].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[25].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_114]

# Sensor 115: BANK 3 SENSOR 26
create_pblock sensor_115
resize_pblock sensor_115 -add {SLICE_X129Y875:SLICE_X129Y895}
add_cells_to_pblock sensor_115 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[26].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X129Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[26].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[26].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_115]

# Sensor 116: BANK 3 SENSOR 27
create_pblock sensor_116
resize_pblock sensor_116 -add {SLICE_X130Y875:SLICE_X130Y895}
add_cells_to_pblock sensor_116 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[27].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X130Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[27].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[27].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_116]

# Sensor 117: BANK 3 SENSOR 28
create_pblock sensor_117
resize_pblock sensor_117 -add {SLICE_X131Y875:SLICE_X131Y895}
add_cells_to_pblock sensor_117 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[28].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X131Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[28].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[28].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_117]

# Sensor 118: BANK 3 SENSOR 29
create_pblock sensor_118
resize_pblock sensor_118 -add {SLICE_X132Y875:SLICE_X132Y895}
add_cells_to_pblock sensor_118 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[29].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X132Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[29].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[29].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_118]

# Sensor 119: BANK 3 SENSOR 30
create_pblock sensor_119
resize_pblock sensor_119 -add {SLICE_X133Y875:SLICE_X133Y895}
add_cells_to_pblock sensor_119 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[30].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X133Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[30].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[3]*/sensors/sensor_gen[30].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_119]

# Sensor 120: BANK 4 SENSOR 1
create_pblock sensor_120
resize_pblock sensor_120 -add {SLICE_X144Y660:SLICE_X144Y680}
add_cells_to_pblock sensor_120 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[1].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X144Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[1].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[1].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_120]

# Sensor 121: BANK 4 SENSOR 2
create_pblock sensor_121
resize_pblock sensor_121 -add {SLICE_X145Y660:SLICE_X145Y680}
add_cells_to_pblock sensor_121 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[2].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X145Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[2].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[2].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_121]

# Sensor 122: BANK 4 SENSOR 3
create_pblock sensor_122
resize_pblock sensor_122 -add {SLICE_X146Y660:SLICE_X146Y680}
add_cells_to_pblock sensor_122 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[3].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X146Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[3].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[3].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_122]

# Sensor 123: BANK 4 SENSOR 4
create_pblock sensor_123
resize_pblock sensor_123 -add {SLICE_X147Y660:SLICE_X147Y680}
add_cells_to_pblock sensor_123 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[4].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X147Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[4].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[4].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_123]

# Sensor 124: BANK 4 SENSOR 5
create_pblock sensor_124
resize_pblock sensor_124 -add {SLICE_X148Y660:SLICE_X148Y680}
add_cells_to_pblock sensor_124 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[5].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X148Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[5].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[5].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_124]

# Sensor 125: BANK 4 SENSOR 6
create_pblock sensor_125
resize_pblock sensor_125 -add {SLICE_X144Y703:SLICE_X144Y723}
add_cells_to_pblock sensor_125 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[6].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X144Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[6].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[6].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_125]

# Sensor 126: BANK 4 SENSOR 7
create_pblock sensor_126
resize_pblock sensor_126 -add {SLICE_X145Y703:SLICE_X145Y723}
add_cells_to_pblock sensor_126 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[7].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X145Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[7].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[7].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_126]

# Sensor 127: BANK 4 SENSOR 8
create_pblock sensor_127
resize_pblock sensor_127 -add {SLICE_X146Y703:SLICE_X146Y723}
add_cells_to_pblock sensor_127 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[8].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X146Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[8].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[8].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_127]

# Sensor 128: BANK 4 SENSOR 9
create_pblock sensor_128
resize_pblock sensor_128 -add {SLICE_X147Y703:SLICE_X147Y723}
add_cells_to_pblock sensor_128 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[9].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X147Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[9].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[9].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_128]

# Sensor 129: BANK 4 SENSOR 10
create_pblock sensor_129
resize_pblock sensor_129 -add {SLICE_X148Y703:SLICE_X148Y723}
add_cells_to_pblock sensor_129 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[10].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X148Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[10].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[10].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_129]

# Sensor 130: BANK 4 SENSOR 11
create_pblock sensor_130
resize_pblock sensor_130 -add {SLICE_X144Y746:SLICE_X144Y766}
add_cells_to_pblock sensor_130 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[11].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X144Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[11].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[11].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_130]

# Sensor 131: BANK 4 SENSOR 12
create_pblock sensor_131
resize_pblock sensor_131 -add {SLICE_X145Y746:SLICE_X145Y766}
add_cells_to_pblock sensor_131 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[12].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X145Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[12].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[12].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_131]

# Sensor 132: BANK 4 SENSOR 13
create_pblock sensor_132
resize_pblock sensor_132 -add {SLICE_X146Y746:SLICE_X146Y766}
add_cells_to_pblock sensor_132 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[13].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X146Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[13].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[13].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_132]

# Sensor 133: BANK 4 SENSOR 14
create_pblock sensor_133
resize_pblock sensor_133 -add {SLICE_X147Y746:SLICE_X147Y766}
add_cells_to_pblock sensor_133 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[14].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X147Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[14].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[14].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_133]

# Sensor 134: BANK 4 SENSOR 15
create_pblock sensor_134
resize_pblock sensor_134 -add {SLICE_X148Y746:SLICE_X148Y766}
add_cells_to_pblock sensor_134 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[15].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X148Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[15].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[15].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_134]

# Sensor 135: BANK 4 SENSOR 16
create_pblock sensor_135
resize_pblock sensor_135 -add {SLICE_X144Y789:SLICE_X144Y809}
add_cells_to_pblock sensor_135 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[16].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X144Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[16].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[16].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_135]

# Sensor 136: BANK 4 SENSOR 17
create_pblock sensor_136
resize_pblock sensor_136 -add {SLICE_X145Y789:SLICE_X145Y809}
add_cells_to_pblock sensor_136 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[17].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X145Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[17].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[17].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_136]

# Sensor 137: BANK 4 SENSOR 18
create_pblock sensor_137
resize_pblock sensor_137 -add {SLICE_X146Y789:SLICE_X146Y809}
add_cells_to_pblock sensor_137 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[18].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X146Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[18].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[18].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_137]

# Sensor 138: BANK 4 SENSOR 19
create_pblock sensor_138
resize_pblock sensor_138 -add {SLICE_X147Y789:SLICE_X147Y809}
add_cells_to_pblock sensor_138 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[19].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X147Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[19].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[19].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_138]

# Sensor 139: BANK 4 SENSOR 20
create_pblock sensor_139
resize_pblock sensor_139 -add {SLICE_X148Y789:SLICE_X148Y809}
add_cells_to_pblock sensor_139 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[20].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X148Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[20].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[20].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_139]

# Sensor 140: BANK 4 SENSOR 21
create_pblock sensor_140
resize_pblock sensor_140 -add {SLICE_X144Y832:SLICE_X144Y852}
add_cells_to_pblock sensor_140 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[21].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X144Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[21].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[21].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_140]

# Sensor 141: BANK 4 SENSOR 22
create_pblock sensor_141
resize_pblock sensor_141 -add {SLICE_X145Y832:SLICE_X145Y852}
add_cells_to_pblock sensor_141 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[22].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X145Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[22].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[22].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_141]

# Sensor 142: BANK 4 SENSOR 23
create_pblock sensor_142
resize_pblock sensor_142 -add {SLICE_X146Y832:SLICE_X146Y852}
add_cells_to_pblock sensor_142 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[23].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X146Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[23].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[23].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_142]

# Sensor 143: BANK 4 SENSOR 24
create_pblock sensor_143
resize_pblock sensor_143 -add {SLICE_X147Y832:SLICE_X147Y852}
add_cells_to_pblock sensor_143 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[24].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X147Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[24].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[24].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_143]

# Sensor 144: BANK 4 SENSOR 25
create_pblock sensor_144
resize_pblock sensor_144 -add {SLICE_X148Y832:SLICE_X148Y852}
add_cells_to_pblock sensor_144 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[25].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X148Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[25].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[25].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_144]

# Sensor 145: BANK 4 SENSOR 26
create_pblock sensor_145
resize_pblock sensor_145 -add {SLICE_X144Y875:SLICE_X144Y895}
add_cells_to_pblock sensor_145 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[26].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X144Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[26].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[26].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_145]

# Sensor 146: BANK 4 SENSOR 27
create_pblock sensor_146
resize_pblock sensor_146 -add {SLICE_X145Y875:SLICE_X145Y895}
add_cells_to_pblock sensor_146 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[27].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X145Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[27].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[27].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_146]

# Sensor 147: BANK 4 SENSOR 28
create_pblock sensor_147
resize_pblock sensor_147 -add {SLICE_X146Y875:SLICE_X146Y895}
add_cells_to_pblock sensor_147 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[28].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X146Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[28].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[28].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_147]

# Sensor 148: BANK 4 SENSOR 29
create_pblock sensor_148
resize_pblock sensor_148 -add {SLICE_X147Y875:SLICE_X147Y895}
add_cells_to_pblock sensor_148 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[29].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X147Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[29].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[29].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_148]

# Sensor 149: BANK 4 SENSOR 30
create_pblock sensor_149
resize_pblock sensor_149 -add {SLICE_X148Y875:SLICE_X148Y895}
add_cells_to_pblock sensor_149 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[30].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X148Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[30].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[4]*/sensors/sensor_gen[30].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_149]

# Sensor 150: BANK 5 SENSOR 1
create_pblock sensor_150
resize_pblock sensor_150 -add {SLICE_X159Y660:SLICE_X159Y680}
add_cells_to_pblock sensor_150 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[1].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X159Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[1].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[1].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_150]

# Sensor 151: BANK 5 SENSOR 2
create_pblock sensor_151
resize_pblock sensor_151 -add {SLICE_X160Y660:SLICE_X160Y680}
add_cells_to_pblock sensor_151 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[2].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X160Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[2].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[2].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_151]

# Sensor 152: BANK 5 SENSOR 3
create_pblock sensor_152
resize_pblock sensor_152 -add {SLICE_X161Y660:SLICE_X161Y680}
add_cells_to_pblock sensor_152 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[3].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X161Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[3].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[3].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_152]

# Sensor 153: BANK 5 SENSOR 4
create_pblock sensor_153
resize_pblock sensor_153 -add {SLICE_X162Y660:SLICE_X162Y680}
add_cells_to_pblock sensor_153 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[4].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X162Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[4].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[4].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_153]

# Sensor 154: BANK 5 SENSOR 5
create_pblock sensor_154
resize_pblock sensor_154 -add {SLICE_X163Y660:SLICE_X163Y680}
add_cells_to_pblock sensor_154 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[5].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X163Y660 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[5].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[5].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_154]

# Sensor 155: BANK 5 SENSOR 6
create_pblock sensor_155
resize_pblock sensor_155 -add {SLICE_X159Y703:SLICE_X159Y723}
add_cells_to_pblock sensor_155 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[6].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X159Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[6].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[6].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_155]

# Sensor 156: BANK 5 SENSOR 7
create_pblock sensor_156
resize_pblock sensor_156 -add {SLICE_X160Y703:SLICE_X160Y723}
add_cells_to_pblock sensor_156 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[7].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X160Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[7].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[7].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_156]

# Sensor 157: BANK 5 SENSOR 8
create_pblock sensor_157
resize_pblock sensor_157 -add {SLICE_X161Y703:SLICE_X161Y723}
add_cells_to_pblock sensor_157 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[8].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X161Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[8].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[8].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_157]

# Sensor 158: BANK 5 SENSOR 9
create_pblock sensor_158
resize_pblock sensor_158 -add {SLICE_X162Y703:SLICE_X162Y723}
add_cells_to_pblock sensor_158 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[9].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X162Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[9].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[9].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_158]

# Sensor 159: BANK 5 SENSOR 10
create_pblock sensor_159
resize_pblock sensor_159 -add {SLICE_X163Y703:SLICE_X163Y723}
add_cells_to_pblock sensor_159 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[10].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X163Y703 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[10].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[10].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_159]

# Sensor 160: BANK 5 SENSOR 11
create_pblock sensor_160
resize_pblock sensor_160 -add {SLICE_X159Y746:SLICE_X159Y766}
add_cells_to_pblock sensor_160 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[11].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X159Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[11].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[11].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_160]

# Sensor 161: BANK 5 SENSOR 12
create_pblock sensor_161
resize_pblock sensor_161 -add {SLICE_X160Y746:SLICE_X160Y766}
add_cells_to_pblock sensor_161 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[12].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X160Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[12].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[12].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_161]

# Sensor 162: BANK 5 SENSOR 13
create_pblock sensor_162
resize_pblock sensor_162 -add {SLICE_X161Y746:SLICE_X161Y766}
add_cells_to_pblock sensor_162 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[13].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X161Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[13].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[13].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_162]

# Sensor 163: BANK 5 SENSOR 14
create_pblock sensor_163
resize_pblock sensor_163 -add {SLICE_X162Y746:SLICE_X162Y766}
add_cells_to_pblock sensor_163 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[14].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X162Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[14].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[14].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_163]

# Sensor 164: BANK 5 SENSOR 15
create_pblock sensor_164
resize_pblock sensor_164 -add {SLICE_X163Y746:SLICE_X163Y766}
add_cells_to_pblock sensor_164 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[15].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X163Y746 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[15].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[15].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_164]

# Sensor 165: BANK 5 SENSOR 16
create_pblock sensor_165
resize_pblock sensor_165 -add {SLICE_X159Y789:SLICE_X159Y809}
add_cells_to_pblock sensor_165 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[16].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X159Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[16].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[16].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_165]

# Sensor 166: BANK 5 SENSOR 17
create_pblock sensor_166
resize_pblock sensor_166 -add {SLICE_X160Y789:SLICE_X160Y809}
add_cells_to_pblock sensor_166 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[17].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X160Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[17].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[17].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_166]

# Sensor 167: BANK 5 SENSOR 18
create_pblock sensor_167
resize_pblock sensor_167 -add {SLICE_X161Y789:SLICE_X161Y809}
add_cells_to_pblock sensor_167 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[18].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X161Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[18].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[18].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_167]

# Sensor 168: BANK 5 SENSOR 19
create_pblock sensor_168
resize_pblock sensor_168 -add {SLICE_X162Y789:SLICE_X162Y809}
add_cells_to_pblock sensor_168 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[19].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X162Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[19].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[19].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_168]

# Sensor 169: BANK 5 SENSOR 20
create_pblock sensor_169
resize_pblock sensor_169 -add {SLICE_X163Y789:SLICE_X163Y809}
add_cells_to_pblock sensor_169 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[20].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X163Y789 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[20].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[20].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_169]

# Sensor 170: BANK 5 SENSOR 21
create_pblock sensor_170
resize_pblock sensor_170 -add {SLICE_X159Y832:SLICE_X159Y852}
add_cells_to_pblock sensor_170 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[21].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X159Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[21].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[21].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_170]

# Sensor 171: BANK 5 SENSOR 22
create_pblock sensor_171
resize_pblock sensor_171 -add {SLICE_X160Y832:SLICE_X160Y852}
add_cells_to_pblock sensor_171 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[22].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X160Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[22].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[22].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_171]

# Sensor 172: BANK 5 SENSOR 23
create_pblock sensor_172
resize_pblock sensor_172 -add {SLICE_X162Y832:SLICE_X162Y852}
add_cells_to_pblock sensor_172 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[23].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X162Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[23].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[23].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_172]

# Sensor 173: BANK 5 SENSOR 24
create_pblock sensor_173
resize_pblock sensor_173 -add {SLICE_X163Y832:SLICE_X163Y852}
add_cells_to_pblock sensor_173 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[24].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X163Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[24].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[24].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_173]

# Sensor 174: BANK 5 SENSOR 25
create_pblock sensor_174
resize_pblock sensor_174 -add {SLICE_X164Y832:SLICE_X164Y852}
add_cells_to_pblock sensor_174 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[25].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X164Y832 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[25].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[25].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_174]

# Sensor 175: BANK 5 SENSOR 26
create_pblock sensor_175
resize_pblock sensor_175 -add {SLICE_X159Y875:SLICE_X159Y895}
add_cells_to_pblock sensor_175 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[26].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X159Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[26].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[26].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_175]

# Sensor 176: BANK 5 SENSOR 27
create_pblock sensor_176
resize_pblock sensor_176 -add {SLICE_X160Y875:SLICE_X160Y895}
add_cells_to_pblock sensor_176 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[27].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X160Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[27].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[27].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_176]

# Sensor 177: BANK 5 SENSOR 28
create_pblock sensor_177
resize_pblock sensor_177 -add {SLICE_X162Y875:SLICE_X162Y895}
add_cells_to_pblock sensor_177 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[28].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X162Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[28].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[28].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_177]

# Sensor 178: BANK 5 SENSOR 29
create_pblock sensor_178
resize_pblock sensor_178 -add {SLICE_X163Y875:SLICE_X163Y895}
add_cells_to_pblock sensor_178 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[29].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X163Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[29].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[29].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_178]

# Sensor 179: BANK 5 SENSOR 30
create_pblock sensor_179
resize_pblock sensor_179 -add {SLICE_X164Y875:SLICE_X164Y895}
add_cells_to_pblock sensor_179 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[30].sensor/tdc0]] -clear_locs
set_property LOC SLICE_X164Y875 [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[30].sensor/tdc0/first_fine_carry]]
set_property DONT_TOUCH true [get_cells [list level0_i/ulp/PicoRV32_SCA_kernel_1/U0/bank_generate[5]*/sensors/sensor_gen[30].sensor/tdc0/*]]
set_property EXCLUDE_PLACEMENT 1 [get_pblocks sensor_179]

