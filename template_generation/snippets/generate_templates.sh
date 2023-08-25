#!/bin/bash
# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

MODE=""

if [ $# -eq 0 ]
then
  echo "usage: ./generate_templates.sh <compile>"
  exit
fi

for i in "$@"
do
case $i in
    -mode=*|--MODE=*)
    MODE="${i#*=}"
    shift
    ;;
    -h |--help)
    echo -e "-mode   | --_MODE   : template generation mode.\n\t- 0 : generate templates without compilation (hex files required)\n\t- 1 : generate templates with compilation\n\tExample: -mode=1"
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
if [ "$MODE" -eq "0" ]; then
  echo "COMPILE FILES"
  python3 compile.py
fi

echo "GENERATE HEX FILES"
python3 generate_output.py
echo "RANDOMIZE TEMPLATES"
python3 randomize.py 10000
echo "INTERLEAVE METADATA"
python3 round_robin.py
