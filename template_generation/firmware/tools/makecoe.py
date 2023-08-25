#!/usr/bin/env python3
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

import pandas as pd
from sys import argv
import os

hexfile = argv[1]

hex_file = pd.read_csv(hexfile, header=None)
hex_file_header = hex_file.copy()
hex_file_header = hex_file_header.drop(hex_file_header.index[2:])
hex_file_header.iloc[0, 0] = "memory_initialization_radix=2;"
hex_file_header.iloc[1, 0] = "memory_initialization_vector="

scale = 16
num_of_bits = 32

hex_file[0] = hex_file[0].apply(lambda v: bin(int(v, scale))[2:].zfill(num_of_bits))
hex_file = pd.concat([hex_file_header, hex_file]).reset_index(drop = True)

hex_file.to_csv(os.path.splitext(hexfile)[0]+'.coe', index=False, header=False)
