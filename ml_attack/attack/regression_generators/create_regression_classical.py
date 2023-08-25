# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import pandas as pd

sensor_tag="all"
seeds = [0]
sensors = "0 1 2 3 4"
datasets = ["IN/nops", "OUT1/nops", "OUT1/random", "OUT2/nops"]
i = 10000
DATA_SOURCE = "nfs"

model_small="classical"
model="classical"

if(DATA_SOURCE == "s3"):
    root_path = "instruction-identification-data/"
    mount_path = ""
elif(DATA_SOURCE == "pvc"):
    root_path = "/tmp/drive/data/"
    mount_path = "--pvc runai-group-scratch:/tmp/drive"
elif(DATA_SOURCE == "nfs"):
    root_path = "/tmp/drive/data/"
    mount_path = "--pvc runai-group-user-group:/tmp/drive"
else:
    print("Incorrect data source")
    exit()

f = open("regression.sh", "w")
f.write("#!/bin/bash\n")

for seed in seeds:
    for dataset in datasets:


                dataset_small=dataset.replace("_", "-").replace("+", "-").replace("/", "-").lower()

                job_name = "prs-"+dataset_small+"-"+model_small+"-s"+str(seed)

                f.write("# "+job_name+"\n")
                f.write("runai submit "+job_name+" -i docker-registry.com/group/docker-tag "+mount_path+" -g 1 --command -- \"/usr/local/bin/launch.sh \'python3 train_classical.py -i "+root_path+"/sakura/Exp-"+dataset+"/dataset/dataset_avg_100.csv -seed "+str(seed)+" -ss "+str(i)+" -nse 5 -sid "+sensors+" -nsa 60 -m "+model+" -n 0 -kf 10 -o "+root_path+"/sakura/Exp-"+dataset+"/results/"+model+"_"+str(i)+"_s"+str(seed)+"-sensors-"+sensor_tag+"_10fold/"+"\'\"\n")
                f.write(" \n")

f.close()
