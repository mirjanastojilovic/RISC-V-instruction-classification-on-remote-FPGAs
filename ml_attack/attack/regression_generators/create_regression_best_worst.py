# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import os
import pandas as pd

sensor_tag="all"
seeds = [0]
preprocessings = ["none"]#, "CWT-H", "CWT-V"]
models = ["resnet"]# ["LSTM", "CNN", "CNN_small", "LSTM+CNN", "CNN+LSTM", "MLP", "resnet"]
datasets = ["IN/nops", "OUT1/nops", "OUT1/random", "OUT2/nops"]
i = 10000
DATA_SOURCE = "nfs"

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

f = open("regression_best_worst_case.sh", "w")
f.write("#!/bin/bash\n")

# Path to accuracies file obtained by post processing ML attack results of single sensors (process/process_results/collect_accuracies/collect_single_sensor_accuracies.ipynb)
accuracies = pd.read_csv("/media/SSD/paper_data/sakura/accuracies/accuracies_single_sensors_all.csv", index_col=None)

for seed in seeds:
    for preprocessing in preprocessings:
        for model in models:
            for dataset in datasets:

                    model_small=model.replace("_", "-").replace("+", "-").replace("/", "-").lower()
                    dataset_small=dataset.replace("_", "-").replace("+", "-").replace("/", "-").lower()
                    preprocessing_small=preprocessing.replace("_", "-").replace("+", "-").replace("/", "-").lower()
                    worst = list(accuracies.loc[(accuracies.kfold=='avg') & (accuracies.dataset=="Exp-"+dataset_small) & (accuracies.model=='resnet') & (accuracies.seed==0 & (accuracies.preprocessing    ==preprocessing))].sort_values(['accuracy'])['sensor'])
                    best = list(reversed(worst))

                    print("Exp-"+dataset_small+':')
                    print("WORST CASE:")
                    print(worst)
                    print("BEST CASE:")
                    print(best)

                    for case in ['best', 'worst']:
                        for s_no in range(1, 4):
                            sensor_ids = []
                            for ids in range(0, s_no+1):
                                if(case=='best'):
                                    sensor_ids.append(best[ids])
                                else:
                                    sensor_ids.append(worst[ids])
                            sensor_ids.sort()

                            sensor_names = ""
                            sensor_names_spaced = ""
                            for ids in sensor_ids:
                                sensor_names+=(str(ids)+"-")
                                sensor_names_spaced+=(str(ids)+" ")
                            #print(sensor_names)
                            job_name = "prs-"+dataset_small+"-"+model_small+"-sens"+sensor_names+case+"-kf10"
                            #print(job_name)

                            f.write("# "+job_name+"\n")
                            f.write("runai submit "+job_name+" -i docker-registry.com/group/docker-tag "+mount_path+" -g 1 --command -- \"/usr/local/bin/launch.sh \'python3 launch_job_"+DATA_SOURCE+".py -i "+root_path+"/sakura/Exp-"+dataset+"/dataset/dataset_avg_100.csv -id Exp-"+dataset_small+"_"+model+"_p"+preprocessing+"_"+str(i)+"_s"+str(seed)+"-sensor-"+sensor_names+case+" -seed "+str(seed)+" -ss "+str(i)+" -nse "+str(len(sensor_ids))+" -sid "+sensor_names_spaced+" -nsa 60 -m "+model+" -n 0 -pp "+preprocessing+" -e 100 -bs 64 -lr 0.0001 -kf 10 -o "+root_path+"/sakura/Exp-"+dataset+"/results/"+model+"_p"+preprocessing+"_"+str(i)+"_s"+str(seed)+"-sensor-"+sensor_names+case+"_10fold/"+"\'\"\n")
                            f.write(" \n")

f.close()
