# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import pandas as pd
import re

sensor_tag="all"
seeds = [1, 2, 3, 4]
sensors = "0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28"
preprocessings = ["none"]
models = ["LSTM", "CNN", "CNN_small", "LSTM+CNN", "CNN+LSTM", "MLP", "resnet"]#, "bilstm_resnet"]
datasets = ["snippets/10k"]#["nops/10k", "random/10k", "random/20k"]
i = 10000
DATA_SOURCE = "nfs"
K_FOLD = 1

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

f = open("regression_alveo.sh", "w")
f.write("#!/bin/bash\n")

for seed in seeds:
    for preprocessing in preprocessings:
        for model in models:
            for dataset in datasets:

                model_small=model.replace("_", "-").replace("+", "-").replace("/", "-").lower()
                dataset_small=dataset.replace("_", "-").replace("+", "-").replace("/", "-").lower()
                preprocessing_small=preprocessing.replace("_", "-").replace("+", "-").replace("/", "-").lower()

                #job_name = "prs-"+dataset_small+"-"+model_small+"-p"+preprocessing_small+"-10000"+"-s"+str(seed)+"-sens-all"
                job_name = "prs-"+dataset_small+"-"+model_small+"-p"+preprocessing_small+"-s"+str(seed)

                dataset_size = int(re.findall(r'\d+', dataset)[0])*1000

                if(dataset == "snippets/10k"):
                    n_samples = 60
                else:
                    n_samples = 16

                f.write("# "+job_name+"\n")
                f.write("runai submit "+job_name+" -i docker-registry.com/group/docker-tag "+mount_path+" -g 1 --command -- \"/usr/local/bin/launch.sh \'python3 launch_job_"+DATA_SOURCE+".py -i "+root_path+"/alveo/"+dataset+"/traces/dataset_averaged_cut.csv -b alveo -id Alveo-"+dataset_small+"_"+model+"_p"+preprocessing+"_s"+str(seed)+"-sensors-"+sensor_tag+" -seed "+str(seed)+" -ss "+str(dataset_size)+" -nse 29 -sid "+sensors+" -nsa "+str(n_samples)+" -m "+model+" -n 0 -pp "+preprocessing+" -e 100 -bs 64 -lr 0.0001 -kf "+str(K_FOLD)+" -o "+root_path+"/alveo/"+dataset+"/results/"+model+"_p"+preprocessing+"_s"+str(seed)+"-sensors-"+sensor_tag+"_"+str(K_FOLD)+"fold/"+"\'\"\n")
                f.write(" \n")

f.close()
