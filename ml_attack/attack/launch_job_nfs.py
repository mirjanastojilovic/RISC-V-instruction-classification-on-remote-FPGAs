# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import argparse
import subprocess
import os
import os.path

os.environ['WANDB_START_METHOD']="thread"

# Make sure write permissions are OK

outputs = []

command = 'sudo chmod -R 777 /home/user/'
process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
output, error = process.communicate()
outputs.append(output.decode('utf-8'))

# Open output file

os.makedirs('out')
f = open('out/out.txt', "w")
f_err = open('out/out_errors.txt', "w")

f.write("PROGRAM STARTED\n")
f.write("----------------------------------------------------------\n")
f.write("Outputs of permission changing commands:\n")
for i in range(len(outputs)):
    f.write(outputs[i]+"\n")
f.write("----------------------------------------------------------\n")
f.flush()

# Parse all arguments

parser = argparse.ArgumentParser(description='Model training program.')
parser.add_argument("-i", "--path_to_dataset", help="Path to dataset.csv.", required=True)
parser.add_argument("-b", "--board", help="Which board the dataset comes from: sakura or alveo.", default="sakura")
parser.add_argument("-id", "--run_id", help="Text id of the run.", required=True)
parser.add_argument("-seed", "--seed_id", help="The random seed.", required=True)
parser.add_argument("-ss", "--sample_size", help="How many samples per class to take from dataset", required=True)
parser.add_argument("-nse", "--n_sensors", help="How many sensors do the traces contain", required=True)
parser.add_argument("-sid", "--sensor_ids", help="Which sensors to use in the attack", required=True, type=int, nargs="*", default=[])
parser.add_argument("-nsa", "--n_samples", help="How many samples does each sensor trace contain", required=True)
parser.add_argument("-m", "--model", help="ML model: LSTM, CNN, CNN_small, LSTM+CNN, MLP, RFC", required=True)
parser.add_argument("-hr", "--hierarchical", help="hierarchical training: none, top, arith, logic, compare, shift, load, store, branch, jump", default="none")
parser.add_argument("-n", "--normalization", help="0: no normalization, 1: normalization", required=True)#default=”default path”
parser.add_argument("-pp", "--preprocessing", help="options: none, CWT-H, or CWT-V", required=True)#default=”default path”
parser.add_argument("-e", "--epochs", help="number of epochs", required=True)
parser.add_argument("-bs", "--batch_size", help="batch size", required=True)
parser.add_argument("-lr", "--learning_rate", type=float, help="starting learning rate", required=True)
parser.add_argument("-kf", "--kfold", help="<=1: no kfolding, >=2 kfold with 2 or higher", required=True)
parser.add_argument("-o", "--path_to_output", help="Path to output directory.", required=True)

args = parser.parse_args()

dataset_path=args.path_to_dataset
board=args.board
run_id=args.run_id
seed_id = int(args.seed_id)
sample_size=int(args.sample_size)
n_sensors=int(args.n_sensors)
sensor_ids = args.sensor_ids
n_samples=int(args.n_samples)
normalization=bool(int(args.normalization))
preprocessing=args.preprocessing
model=args.model
hierarchical=args.hierarchical
epochs=int(args.epochs)
batch_size=int(args.batch_size)
learning_rate=args.learning_rate
kfold=int(args.kfold)
out_path=args.path_to_output

f.write("----------------------------------------------------------\n")
f.write("PARSING RESULTS:\n")

if(model!='LSTM' and model!='CNN' and model!='CNN_small' and model!='MLP' and model!='RFC' and model!='LSTM+CNN' and model!='CNN+LSTM' and model!='resnet' and model!='transformers' and model!='resnet_v1' and model!='resnet_v2' and model!='resnet_v3' and model!='resnet_v4' and model!='resnet_v5' and model!='bilstm_resnet' and model!='resnet_bilstm' and model!='resnet_bilstm_separated'):
    print("WRONG MODEL")
    f.write("WRONG MODEL\n")
    exit()
if(learning_rate>0.1):
    print("LEARNING RATE TOO BIG; SHOULD BE LESS OR EQUAL TO 0.1")
    f.write("LEARNING RATE TOO BIG; SHOULD BE LESS OR EQUAL TO 0.1\n")
    exit()
if(seed_id > 4 or seed_id < 0):
    print("SEED ID IS TOO BIG")
    f.write("SEED ID IS TOO BIG\n")
    exit()
if(preprocessing!="none" and preprocessing!="CWT-H" and preprocessing!="CWT-V"):
    print("Wrong preprocessing option!")
    f.write("Wrong preprocessing option!\n")
    exit()
if(kfold<1):
    kfold = 1
if(board!='sakura' and board!='alveo'):
    print("Wrong board!")
    out_file.write("Wrong board!"+"\n")
    out_file.flush()
    exit()
if(hierarchical not in ['none', 'top', 'arith', 'logic', 'compare', 'shift', 'load', 'store', 'branch', 'jump']):
    print("Wrong hierarchical model!")
    out_file.write("Wrong hierarchical model!"+"\n")
    out_file.flush()
    exit()

print("ARGUMENTS:")
f.write("ARGUMENTS:\n")
print("* Dataset: "+dataset_path)
f.write("* Dataset: "+dataset_path+"\n")
print("* Board: "+board)
f.write("* Board: "+board+"\n")
print("* Sample size: "+str(sample_size))
f.write("* Sample size: "+str(sample_size)+"\n")
print("* Normalization: "+str(normalization))
f.write("* Normalization: "+str(normalization)+"\n")
print("* Preprocessing: "+preprocessing)
f.write("* Preprocessing: "+preprocessing+"\n")
print("* Model: "+model)
f.write("* Model: "+model+"\n")
print("* Hierarchical: "+hierarchical)
f.write("* Hierarchical: "+hierarchical+"\n")
print("* Epochs: "+str(epochs))
f.write("* Epochs: "+str(epochs)+"\n")
print("* Batch size: "+str(batch_size))
f.write("* Batch size: "+str(batch_size)+"\n")
print("* Learning Rate: ", learning_rate)
f.write("* Learning Rate: "+str(learning_rate)+"\n")
print("* Dump Path: "+out_path)
f.write("* Dump Path: "+out_path+"\n")
f.flush()

f.write("----------------------------------------------------------\n")
f.write("WANDB INITIALIZATION:\n")
f.write("Command:\n")
command = 'python3 -m wandb login f3f1d052be089a34050d009e201c55c7b5838ddf'
f.write(command+"\n")
f.flush()
process = subprocess.call(command.split(), stdout=f, stderr=f_err)
f_err.flush()
f.flush()

f.write("----------------------------------------------------------\n")
f.write("COPY FROM NFS:\n")
f.write("Command:\n")
command = 'cp -r '+dataset_path+' .'
f.write(command+"\n")
f.flush()
process = subprocess.call(command.split(), stdout=f, stderr=f_err)
f_err.flush()
f.flush()

sensor_ids_arg = " -sid "
for i in args.sensor_ids:
    sensor_ids_arg += str(i)+" "

f.write("----------------------------------------------------------\n")
f.write("TRAINING:\n")
f.write("Command:\n")
command = 'python3 train.py -i '+os.path.basename(dataset_path)+' -b '+board+' -id '+run_id+' -seed '+str(seed_id)+' -ss '+str(sample_size)+' -nse '+str(n_sensors)+sensor_ids_arg+' -nsa '+str(n_samples)+' -m '+model+' -hr '+args.hierarchical+' -n '+args.normalization+' -pp '+preprocessing+' -e '+args.epochs+' -bs '+str(batch_size)+' -lr '+str(learning_rate)+' -kf '+str(kfold)+' -o out/'
print(command)
f.write(command+"\n")
f.flush()
process = subprocess.call(command.split(), stdout=f, stderr=f_err)
f_err.flush()
f.flush()

f.write("----------------------------------------------------------\n")
f.write("CREATE OUT DIRECTORY:\n")
f.write("Command:\n")
command = 'mkdir -p '+out_path
print(command)
f.write(command+"\n")
f.flush()
process = subprocess.call(command.split(), stdout=f, stderr=f_err)
f_err.flush()
f.flush()

f.close()
f_err.close()

command = 'zip -r out.zip out'
process = subprocess.call(command.split())

command = 'mv out.zip '+out_path+"/"
print(command)
os.system(command)
