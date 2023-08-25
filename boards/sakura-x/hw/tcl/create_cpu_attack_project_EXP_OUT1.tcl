# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# Check if project name is defined
if {![info exists project_name]} {
  puts "Project name not defined.\nDefine project name with:\n\t set project_name your_project_name"
  return
}

# Create a directory with the project
exec mkdir $project_name

# Make that directory the current working directory
cd $project_name
set work_dir [pwd]
puts "The new working directory is [pwd]"

# Set sources path
set src_path ../../../CPU_attack_project

# Create vivado project with the desired name
create_project -name $project_name

# Change the FPGA used to the one on Amazon F1
set_property part xc7k160tfbg676-1 [current_project]
# Change the default language to VHDL
set_property target_language Verilog [current_project]

# Import source files
import_files -norecurse "$src_path/sources_v3/multiple_sensors/CPU_Comp.vhd" \
                        "$src_path/sources_v3/multiple_sensors/FSM.vhd" \
                        "$src_path/sources_v3/sensor_fifo.vhd" \
                        "$src_path/sources_v3/lbus_if.v" \
                        "$src_path/sources_v3/multiple_sensors/chip_sasebo_giii_aes.v" \
                        "$src_path/sources_v3/ry_alu.vhd" \
                        "$src_path/sources_v3/ry_alu_control_unit.vhd" \
                        "$src_path/sources_v3/ry_alu_mux.vhd" \
                        "$src_path/sources_v3/ry_comparator.vhd"\
                        "$src_path/sources_v3/ry_constants.vhd" \
                        "$src_path/sources_v3/ry_control_unit.vhd" \
                        "$src_path/sources_v3/ry_core.vhd" \
                        "$src_path/sources_v3/ry_counter.vhd" \
                        "$src_path/sources_v3/ry_csr.vhd" \
                        "$src_path/sources_v3/ry_csr_alu.vhd" \
                        "$src_path/sources_v3/ry_csr_unit.vhd" \
                        "$src_path/sources_v3/ry_decode.vhd" \
                        "$src_path/sources_v3/ry_execute.vhd" \
                        "$src_path/sources_v3/ry_fetch.vhd" \
                        "$src_path/sources_v3/ry_icache.vhd" \
                        "$src_path/sources_v3/ry_imm_decoder.vhd" \
                        "$src_path/sources_v3/ry_memory.vhd" \
                        "$src_path/sources_v3/ry_potato.vhd" \
                        "$src_path/sources_v3/ry_register_file.vhd" \
                        "$src_path/sources_v3/ry_types.vhd" \
                        "$src_path/sources_v3/ry_utilities.vhd" \
                        "$src_path/sources_v3/ry_wb_adapter.vhd" \
                        "$src_path/sources_v3/ry_wb_arbiter.vhd" \
                        "$src_path/sources_v3/ry_fifo.vhd" \
                        "$src_path/sources_v3/ry_soc_gpio.vhd" \
                        "$src_path/sources_v3/ry_soc_intercon.vhd" \
                        "$src_path/sources_v3/ry_soc_memory.vhd" \
                        "$src_path/sources_v3/ry_soc_timer.vhd" \
                        "$src_path/sources_v3/ry_soc_uart.vhd" \
                        "$src_path/sources_v3/aee_rom_wrapper.vhd" \
                        "$src_path/sources_v3/toplevel.vhd" \
                        "$src_path/sources_v3/gpio.h" \
                        "$src_path/sources_v3/icerror.h" \
                        "$src_path/sources_v3/timer.h" \
                        "$src_path/sources_v3/uart.h" \
                        "$src_path/sources_v3/encoding.h" \
                        "$src_path/sources_v3/riscy-test.h" \
                        "$src_path/sources_v3/test_macros.h" \
                        "$src_path/sources_v3/platform.h" \
                        "$src_path/sources_v3/riscy.h" \
                        "$src_path/sources_v3/riscv_test.h" \
                        "$src_path/sources_v3/counter_small.vhd" \
                        "$src_path/sources_v3/design_package.vhd" \
                        "$src_path/sources_v3/sensor.vhd" \
                        "$src_path/sources_v3/multiple_sensors/sensor_inst_multiple.vhd" \
                        "$src_path/sources_v3/sensor_top.vhd" \
                        "$src_path/sources_v3/fifo_wrapper.vhd" \
                        "$src_path/sources_v3/read_fifo_fsm.vhd" \
                        "$src_path/sources_v3/ry_writeback.vhd" \
                        "$src_path/sources_v3/coe_file.coe" \
                        


update_compile_order -fileset sources_1
update_compile_order -fileset sources_1

# Import constraint files
add_files -fileset constrs_1 -norecurse "$src_path/constraints/pin_sasebo_giii_k7_Exp-OUT1.xdc"
import_files -fileset constrs_1 "$src_path/constraints/pin_sasebo_giii_k7_Exp-OUT1.xdc"

# Create the data FIFO IP 
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_0
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} CONFIG.Input_Data_Width {128} CONFIG.Input_Depth {16} CONFIG.Output_Data_Width {128} CONFIG.Output_Depth {16} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Valid_Flag {true} CONFIG.Write_Acknowledge_Flag {true} CONFIG.Data_Count_Width {4} CONFIG.Write_Data_Count_Width {4} CONFIG.Read_Data_Count_Width {4} CONFIG.Full_Threshold_Assert_Value {13} CONFIG.Full_Threshold_Negate_Value {12} CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_generator_0]
generate_target {instantiation_template} [get_files $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci]
generate_target all [get_files  $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci]
catch { config_ip_cache -export [get_ips -all fifo_generator_0] }
export_ip_user_files -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci]
launch_runs -jobs 4 fifo_generator_0_synth_1
export_simulation -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci] -directory $work_dir/$project_name.ip_user_files/sim_scripts -ip_user_files_dir $work_dir/$project_name.ip_user_files -ipstatic_source_dir $work_dir/$project_name.ip_user_files/ipstatic -lib_map_path [list {modelsim=$work_dir/$project_name.cache/compile_simlib/modelsim} {questa=$work_dir/$project_name.cache/compile_simlib/questa} {ies=$work_dir/$project_name.cache/compile_simlib/ies} {xcelium=$work_dir/$project_name.cache/compile_simlib/xcelium} {vcs=$work_dir/$project_name.cache/compile_simlib/vcs} {riviera=$work_dir/$project_name.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet

# Create the sensor FIFO IP
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_1
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} CONFIG.Input_Data_Width {128} CONFIG.Input_Depth {256} CONFIG.Output_Data_Width {128} CONFIG.Output_Depth {256} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Valid_Flag {true} CONFIG.Write_Acknowledge_Flag {true} CONFIG.Data_Count_Width {8} CONFIG.Write_Data_Count_Width {8} CONFIG.Read_Data_Count_Width {8} CONFIG.Full_Threshold_Assert_Value {253} CONFIG.Full_Threshold_Negate_Value {252} CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_generator_1]
generate_target {instantiation_template} [get_files $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci]
generate_target all [get_files  $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci]
catch { config_ip_cache -export [get_ips -all fifo_generator_1] }
export_ip_user_files -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci]
launch_runs -jobs 4 fifo_generator_1_synth_1
export_simulation -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci] -directory $work_dir/$project_name.ip_user_files/sim_scripts -ip_user_files_dir $work_dir/$project_name.ip_user_files -ipstatic_source_dir $work_dir/$project_name.ip_user_files/ipstatic -lib_map_path [list {modelsim=$work_dir/$project_name.cache/compile_simlib/modelsim} {questa=$work_dir/$project_name.cache/compile_simlib/questa} {ies=$work_dir/$project_name.cache/compile_simlib/ies} {xcelium=$work_dir/$project_name.cache/compile_simlib/xcelium} {vcs=$work_dir/$project_name.cache/compile_simlib/vcs} {riviera=$work_dir/$project_name.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wizard
set_property -dict [list CONFIG.PRIM_IN_FREQ {200.000} CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT3_USED {true} CONFIG.CLKOUT4_USED {true} CONFIG.CLK_OUT2_PORT {system_clk} CONFIG.CLK_OUT3_PORT {sensor_clk} CONFIG.CLK_OUT4_PORT {timer_clk} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {80.000} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {80.000} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {320.000} CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {40.000} CONFIG.RESET_TYPE {ACTIVE_LOW} CONFIG.CLKIN1_JITTER_PS {50.0} CONFIG.MMCM_DIVCLK_DIVIDE {5} CONFIG.MMCM_CLKFBOUT_MULT_F {24.000} CONFIG.MMCM_CLKIN1_PERIOD {5.000} CONFIG.MMCM_CLKIN2_PERIOD {10.0} CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.000} CONFIG.MMCM_CLKOUT1_DIVIDE {12} CONFIG.MMCM_CLKOUT2_DIVIDE {3} CONFIG.MMCM_CLKOUT3_DIVIDE {24} CONFIG.NUM_OUT_CLKS {4} CONFIG.RESET_PORT {resetn} CONFIG.CLKOUT1_JITTER {185.331} CONFIG.CLKOUT1_PHASE_ERROR {196.976} CONFIG.CLKOUT2_JITTER {185.331} CONFIG.CLKOUT2_PHASE_ERROR {196.976} CONFIG.CLKOUT3_JITTER {144.252} CONFIG.CLKOUT3_PHASE_ERROR {196.976} CONFIG.CLKOUT4_JITTER {213.786} CONFIG.CLKOUT4_PHASE_ERROR {196.976}] [get_ips clk_wizard]
generate_target {instantiation_template} [get_files $work_dir/$project_name.srcs/sources_1/ip/clk_wizard/clk_wizard.xci]
generate_target all [get_files  $work_dir/$project_name.srcs/sources_1/ip/clk_wizard/clk_wizard.xci]
catch { config_ip_cache -export [get_ips -all clk_wizard] }
export_ip_user_files -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/clk_wizard/clk_wizard.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $work_dir/$project_name.srcs/sources_1/ip/clk_wizard/clk_wizard.xci]
launch_runs -jobs 6 clk_wizard_synth_1
export_simulation -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/clk_wizard/clk_wizard.xci] -directory $work_dir/$project_name.ip_user_files/sim_scripts -ip_user_files_dir $work_dir/$project_name.ip_user_files -ipstatic_source_dir $work_dir/$project_name.ip_user_files/ipstatic -lib_map_path [list {modelsim=$work_dir/$project_name.cache/compile_simlib/modelsim} {questa=$work_dir/$project_name.cache/compile_simlib/questa} {ies=$work_dir/$project_name.cache/compile_simlib/ies} {xcelium=$work_dir/$project_name.cache/compile_simlib/xcelium} {vcs=$work_dir/$project_name.cache/compile_simlib/vcs} {riviera=$work_dir/$project_name.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name aee_rom_2
set_property -dict [list CONFIG.Component_Name {aee_rom_2} CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {32} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Load_Init_File {true} CONFIG.Coe_File "$work_dir/$project_name.srcs/sources_1/imports/sources_v3/coe_file.coe" CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_ips aee_rom_2]

generate_target {instantiation_template} [get_files $work_dir/$project_name.srcs/sources_1/ip/aee_rom_2/aee_rom_2.xci]
update_compile_order -fileset sources_1
generate_target all [get_files  $work_dir/$project_name.srcs/sources_1/ip/aee_rom_2/aee_rom_2.xci]
catch { config_ip_cache -export [get_ips -all aee_rom_2] }
export_ip_user_files -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/aee_rom_2/aee_rom_2.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $work_dir/$project_name.srcs/sources_1/ip/aee_rom_2/aee_rom_2.xci]
launch_runs -jobs 8 aee_rom_2_synth_1
export_simulation -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/aee_rom_2/aee_rom_2.xci] -directory $work_dir/$project_name.ip_user_files/sim_scripts -ip_user_files_dir $work_dir/$project_name.ip_user_files -ipstatic_source_dir $work_dir/$project_name.ip_user_files/ipstatic -lib_map_path [list {modelsim=$work_dir/$project_name.cache/compile_simlib/modelsim} {questa=$work_dir/$project_name.cache/compile_simlib/questa} {ies=$work_dir/$project_name.cache/compile_simlib/ies} {xcelium=$work_dir/$project_name.cache/compile_simlib/xcelium} {vcs=$work_dir/$project_name.cache/compile_simlib/vcs} {riviera=$work_dir/$project_name.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet



create_ip -name proc_sys_reset -vendor xilinx.com -library ip -version 5.0 -module_name proc_sys_reset_0
set_property -dict [list CONFIG.C_EXT_RST_WIDTH {1} CONFIG.C_AUX_RST_WIDTH {1} CONFIG.C_EXT_RESET_HIGH {0} CONFIG.C_AUX_RESET_HIGH {0}] [get_ips proc_sys_reset_0]
generate_target {instantiation_template} [get_files $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_0/proc_sys_reset_0.xci]
update_compile_order -fileset sources_1
generate_target all [get_files  $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_0/proc_sys_reset_0.xci]
catch { config_ip_cache -export [get_ips -all proc_sys_reset_0] }
export_ip_user_files -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_0/proc_sys_reset_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_0/proc_sys_reset_0.xci]
launch_runs -jobs 8 proc_sys_reset_0_synth_1
export_simulation -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_0/proc_sys_reset_0.xci] -directory $work_dir/$project_name.ip_user_files/sim_scripts -ip_user_files_dir $work_dir/$project_name.ip_user_files -ipstatic_source_dir $work_dir/$project_name.ip_user_files/ipstatic -lib_map_path [list {modelsim=$work_dir/$project_name.cache/compile_simlib/modelsim} {questa=$work_dir/$project_name.cache/compile_simlib/questa} {ies=$work_dir/$project_name.cache/compile_simlib/ies} {xcelium=$work_dir/$project_name.cache/compile_simlib/xcelium} {vcs=$work_dir/$project_name.cache/compile_simlib/vcs} {riviera=$work_dir/$project_name.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet





create_ip -name proc_sys_reset -vendor xilinx.com -library ip -version 5.0 -module_name proc_sys_reset_1
set_property -dict [list CONFIG.C_EXT_RST_WIDTH {1} CONFIG.C_AUX_RST_WIDTH {1} CONFIG.C_EXT_RESET_HIGH {0} CONFIG.C_AUX_RESET_HIGH {0}] [get_ips proc_sys_reset_1]
generate_target {instantiation_template} [get_files $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_1/proc_sys_reset_1.xci]
generate_target all [get_files  $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_1/proc_sys_reset_1.xci]
catch { config_ip_cache -export [get_ips -all proc_sys_reset_1] }
export_ip_user_files -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_1/proc_sys_reset_1.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_1/proc_sys_reset_1.xci]
export_simulation -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/proc_sys_reset_1/proc_sys_reset_1.xci] -directory $work_dir/$project_name.ip_user_files/sim_scripts -ip_user_files_dir $work_dir/$project_name.ip_user_files -ipstatic_source_dir $work_dir/$project_name.ip_user_files/ipstatic -lib_map_path [list {modelsim=$work_dir/$project_name.cache/compile_simlib/modelsim} {questa=$work_dir/$project_name.cache/compile_simlib/questa} {ies=$work_dir/$project_name.cache/compile_simlib/ies} {xcelium=$work_dir/$project_name.cache/compile_simlib/xcelium} {vcs=$work_dir/$project_name.cache/compile_simlib/vcs} {riviera=$work_dir/$project_name.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
update_compile_order -fileset sources_1





set_property -dict [list CONFIG.Input_Depth {2048} CONFIG.Output_Depth {2048} CONFIG.Data_Count_Width {11} CONFIG.Write_Data_Count_Width {11} CONFIG.Read_Data_Count_Width {11} CONFIG.Full_Threshold_Assert_Value {2045} CONFIG.Full_Threshold_Negate_Value {2044}] [get_ips fifo_generator_1]
generate_target all [get_files  $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci]
catch { config_ip_cache -export [get_ips -all fifo_generator_1] }
export_ip_user_files -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci] -no_script -sync -force -quiet
reset_run fifo_generator_1_synth_1
launch_runs -jobs 8 fifo_generator_1_synth_1
export_simulation -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci] -directory $work_dir/$project_name.ip_user_files/sim_scripts -ip_user_files_dir $work_dir/$project_name.ip_user_files -ipstatic_source_dir $work_dir/$project_name.ip_user_files/ipstatic -lib_map_path [list {modelsim=$work_dir/$project_name.cache/compile_simlib/modelsim} {questa=$work_dir/$project_name.cache/compile_simlib/questa} {ies=$work_dir/$project_name.cache/compile_simlib/ies} {xcelium=$work_dir/$project_name.cache/compile_simlib/xcelium} {vcs=$work_dir/$project_name.cache/compile_simlib/vcs} {riviera=$work_dir/$project_name.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet





set_property -dict [list CONFIG.Enable_A {Use_ENA_Pin}] [get_ips aee_rom_2]
generate_target all [get_files  $work_dir/$project_name.srcs/sources_1/ip/aee_rom_2/aee_rom_2.xci]
catch { config_ip_cache -export [get_ips -all aee_rom_2] }
export_ip_user_files -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/aee_rom_2/aee_rom_2.xci] -no_script -sync -force -quiet
reset_run aee_rom_2_synth_1
launch_runs -jobs 8 aee_rom_2_synth_1
export_simulation -of_objects [get_files $work_dir/$project_name.srcs/sources_1/ip/aee_rom_2/aee_rom_2.xci] -directory $work_dir/$project_name.ip_user_files/sim_scripts -ip_user_files_dir $work_dir/$project_name.ip_user_files -ipstatic_source_dir $work_dir/$project_name.ip_user_files/ipstatic -lib_map_path [list {modelsim=$work_dir/$project_name.cache/compile_simlib/modelsim} {questa=$work_dir/$project_name.cache/compile_simlib/questa} {ies=$work_dir/$project_name.cache/compile_simlib/ies} {xcelium=$work_dir/$project_name.cache/compile_simlib/xcelium} {vcs=$work_dir/$project_name.cache/compile_simlib/vcs} {riviera=$work_dir/$project_name.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet


