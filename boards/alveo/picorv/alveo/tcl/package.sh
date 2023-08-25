# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

MODE=""
DESIGN=""
SENSOR=""

if [ "$1" = "" ]
then
  echo "No arguments. Use --help for more info."
  exit 1
fi

for i in "$@"
do
case $i in
    -mode=*|--PACKAGE_MODE=*)
    MODE="${i#*=}"
    shift
    ;;
    -design=*|--PACKAGE_DESIGN=*)
    DESIGN="${i#*=}"
    shift
    ;;
    -sensor=*|--SENSOR_TYPE=*)
    SENSOR="${i#*=}"
    shift
    ;;
    -h |--help)
    echo -e "-mode   | --PACKAGE_MODE   : package mode specification.\n\t- 0 : package for simulation\n\t- 1 : package for implementation\n\tExample: -mode=1"
    echo -e "-design | --PACKAGE_DESIGN : design specification.\n\t- 0 : package design with single bank\n\t- 1: package design with multiple banks\n\tExample -design=0"
    echo -e "-sensor | --SENSOR_TYPE    : sensor type specification.\n\t- 0 : TDC\n\t- 1: RDS\n\t -2: TDC 6 sensors\n\tExample -sensor=0"
    echo -e "-h      | --help           : display help."
    exit 1
    shift
    ;;
    *)
    echo "Unknown option: $i. Try --help."
    shift # unknown option
    exit 1
    ;;
esac
done

if [ "$SENSOR" -eq "0" ]; then
  echo "USING TDC CONSTRAINTS"
  cp ../constraints/pblocks_TDC.tcl ../constraints/pblocks.tcl
  cp ../constraints/timing_TDC.tcl ../constraints/timing.tcl
elif [ "$SENSOR" -eq "1" ]; then
  echo "USING RDS CONSTRAINTS"
  cp ../constraints/pblocks_RDS.tcl ../constraints/pblocks.tcl
  cp ../constraints/timing_RDS.tcl ../constraints/timing.tcl
else
  echo "USING TDC 6 SENSORS CONSTRAINTS"
  cp ../constraints/pblocks_TDC6.tcl ../constraints/pblocks.tcl
  cp ../constraints/timing_TDC6.tcl ../constraints/timing.tcl
fi

vivado -mode batch -source gen_xo.tcl -notrace -tclargs kernel.xo PicoRV32_SCA_kernel hw xilinx_u200_gen3x16_xdma_1_202110_1 $MODE $DESIGN $SENSOR
