# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

if { $::argc != 7 } {
    puts "ERROR: Program \"$::argv0\" requires 6 arguments!\n"
    puts "Usage: $::argv0 <xoname> <krnl_name> <target> <device> <sim> <design> <sensor>\n"
    exit
}

set xoname    [lindex $::argv 0]
set krnl_name [lindex $::argv 1]
set target    [lindex $::argv 2]
set device    [lindex $::argv 3]
set sim       [lindex $::argv 4]
set design    [lindex $::argv 5]
set sensor    [lindex $::argv 6]

set suffix "${krnl_name}_${target}_${device}"

set original_argv $argv
set argv [list $sim $design $sensor]
source -notrace ./package_kernel.tcl
set argv $original_argv

if {[file exists "${xoname}"]} {
    file delete -force "${xoname}"
}

package_xo -xo_path ${xoname} -kernel_name ${krnl_name} -ip_directory ./packaged -kernel_xml ./../rtl/kernel.xml
