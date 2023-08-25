# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import pandas as pd

sensor_tag="all"
seeds = [3, 4]
sensors = "0 1 2 3 4"
preprocessings = ["none"]#, "CWT-H", "CWT-V"]
models = ["resnet"]#["LSTM", "CNN", "CNN_small", "LSTM+CNN", "CNN+LSTM", "MLP", "resnet"]
datasets = ["IN/nops", "OUT1/nops", "OUT1/random", "OUT2/nops"]
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

f = open("regression_dataset_size.sh", "w")
f.write("#!/bin/bash\n")

for seed in seeds:
    for preprocessing in preprocessings:
        for model in models:
            for dataset in datasets:
                for i in range(1000, 10000, 1000):

                    model_small=model.replace("_", "-").replace("+", "-").replace("/", "-").lower()
                    dataset_small=dataset.replace("_", "-").replace("+", "-").replace("/", "-").lower()
                    preprocessing_small=preprocessing.replace("_", "-").replace("+", "-").replace("/", "-").lower()

                    #job_name = "prs-"+dataset_small+"-"+model_small+"-p"+preprocessing_small+"-10000"+"-s"+str(seed)+"-sens-all"
                    job_name = "prs-"+dataset_small+"-"+model_small+"-"+str(i)+"-s"+str(seed)

                    f.write("# "+job_name+"\n")
                    f.write("runai submit "+job_name+" -i docker-registry.com/group/docker-tag "+mount_path+" -g 1 --command -- \"/usr/local/bin/launch.sh \'python3 launch_job_"+DATA_SOURCE+".py -i "+root_path+"/sakura/Exp-"+dataset+"/dataset/dataset_avg_100.csv -id Exp-"+dataset_small+"_"+model+"_p"+preprocessing+"_"+str(i)+"_s"+str(seed)+"-sensors-"+sensor_tag+" -seed "+str(seed)+" -ss "+str(i)+" -nse 5 -sid "+sensors+" -nsa 60 -m "+model+" -n 0 -pp "+preprocessing+" -e 100 -bs 64 -lr 0.0001 -kf "+str(K_FOLD)+" -o "+root_path+"/sakura/Exp-"+dataset+"/results/"+model+"_p"+preprocessing+"_"+str(i)+"_s"+str(seed)+"-sensors-"+sensor_tag+"_"+str(K_FOLD)+"fold/"+"\'\"\n")
                    f.write(" \n")

f.close()
