# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

set slices [get_sites -range "SLICE_X0Y0 SLICE_X168Y899"]

set filename "slices.txt"
set fileId [open $filename "w"]

foreach {slice} $slices {
	puts $fileId $slice
}

close $fileId

set dsps [get_sites -range "DSP48E2_X0Y0 DSP48E2_X18Y359"]

set filename "dsps.txt"
set fileId [open $filename "w"]

foreach {dsp} $dsps {
	puts $fileId $dsp
}

close $fileId

set bram18s [get_sites -range "RAMB18_X0Y0 RAMB18_X11Y359"]

set filename "bram18s.txt"
set fileId [open $filename "w"]

foreach {bram18} $bram18s {
	puts $fileId $bram18
}

close $fileId

set bram36s [get_sites -range "RAMB36_X0Y0 RAMB36_X11Y179"]

set filename "bram36s.txt"
set fileId [open $filename "w"]

foreach {bram36} $bram36s {
	puts $fileId $bram36
}

close $fileId

set uram288s [get_sites -range "URAM288_X0Y0 URAM288_X3Y239"]

set filename "uram288s.txt"
set fileId [open $filename "w"]

foreach {uram288} $uram288s {
	puts $fileId $uram288
}

close $fileId
