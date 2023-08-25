# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os

rootdir = "/media/SSD/paper_data/sakura/"
exclude = set(['templates'])

unzipped_files = []

for subdir, dirs, files in os.walk(rootdir):
    dirs[:] = [d for d in dirs if d not in exclude]
    if(len(dirs)==0 and len(files)==1):
        for file in files:
            if(file=="out.zip"):
                print(os.path.join(subdir, file))
                zipped = os.path.join(subdir, file)
                unzipped_files.append("unzip "+zipped+" -d "+subdir+"/\n")

f = open("unpack_regression.sh", "w")
f.write("#!/bin/bash\n")

for unzip in unzipped_files:
    f.write(unzip)

f.close()
