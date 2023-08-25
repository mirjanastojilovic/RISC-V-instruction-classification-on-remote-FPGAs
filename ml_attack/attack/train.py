# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# Jinwei Yao Summer@EPFL 21
## code structure
# Steps
# Step 1. Do the settings: 
# 1.1 select dataset type(exp-in or exp-out, using sensor_out_flag), you can change the dataset for exp-in and exp-out that you want to use in function load_dataset.
#  
# 1.2 select method(no-cwt, ,CH-cwt, cwt-CH, cw-CV, cwt-3D,cwt-single, "bestCombine" for cwt-best-combinations, "worstCombine" for cwt-worst-combinations), 
# 1.3 training settings(epoch, batch_size), 
# 1.4 folder names, 
# 1.5 K-fold or not(K_Fold_flag), 
# 1.6 best list and worst list for sensor combinations.
# Sept 2. load preprossed dataset: load dataset and do preprocessing according to the dataset type and method type in function "load_dataset" 
# Sept 3. Select the model: select model for deep learning training 
# Sept 4. Train and Test: use the model selected and get the accuracy.
# Sept 5. Output confusion metrix: a CSV file and a fig file.

# You can search "Step 1." to "Step 5." to quickly find the corresponding part.

from itertools import combinations
from sklearn import preprocessing
import os
import pickle
import numpy as np
### To reproduce, set the random set 
import tensorflow as tf
import random
from numpy import mean
from numpy import std
from numpy import dstack
from numpy import newaxis
from pandas import read_csv
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
from tensorflow.keras.layers import Flatten
from tensorflow.keras.layers import Dropout
from tensorflow.keras.layers import LSTM
from tensorflow.keras.layers import ConvLSTM2D
from tensorflow.keras.models import load_model
# from keras.utils import to_categorical
from tensorflow.keras.utils import to_categorical
from matplotlib import pyplot
import pandas as pd
from sklearn.metrics import classification_report
from sklearn import model_selection
from sklearn.model_selection import KFold
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import MinMaxScaler, StandardScaler
from sklearn.utils.multiclass import unique_labels
from sklearn.metrics import confusion_matrix
import matplotlib.pyplot as plt
# CWT 
from cwt_feature_extraction import CTW_extract_feature
import pycwt as wavelet
import argparse
import wandb
from wandb.keras import WandbCallback

import sys
sys.path.insert(1, './models/')

# LDA
## import other models
import m_lstm_cnn
import m_lstm
import m_cnn #1
import m_cnn_small
import m_mlp
import m_random_forest
import m_cnn_lstm
import m_resnet
import m_resnet_v1
import m_resnet_v2
import m_resnet_v3
import m_resnet_v4
import m_resnet_v5
import m_bilstm_resnet
import m_resnet_bilstm
import m_resnet_bilstm_separated
import m_transformers

def setup_seed(seed):
    random.seed(seed)  # set random seed for python
    np.random.seed(seed)  # set random seed for  numpy
    tf.random.set_seed(seed)  # tf cpu fix seed
    os.environ['PYTHONHASHSEED']=str(seed)
    os.environ['TF_DETERMINISTIC_OPS'] = '1'  # tf gpu fix seed, please `pip install tensorflow-determinism` first


def data_normalize(dataset):
    scaler = MinMaxScaler(feature_range=(-1,1))
    # https://www.cnblogs.com/weiyunpeng/p/12250308.html z-scorre
    #scaler = StandardScaler()
    scaler.fit(dataset)#  
    # scaler.data_max_
    dataset_normorlize = scaler.transform(dataset) #
    return dataset_normorlize

# load the dataset, returns train and test X and y elements
# load the dataset, returns train and test X and y elements
def load_dataset(train_percent, dataset_path, board, shuffle, normalize, n_sensors, sensor_ids, n_samples, preprocessing, seed_id, hierarchical_type, out_file, sample_size=-1):

    arith = ['add', 'addi', 'sub', 'lui', 'auipc']
    logic = ['xor', 'xori', 'or', 'ori', 'and', 'andi']
    compare = ['slt', 'slti', 'sltu', 'sltiu']
    shift = ['sll', 'slli', 'srl', 'srli', 'sra', 'srai']
    load = ['lb', 'lh', 'lw', 'lbu', 'lhu']
    store = ['sb', 'sh', 'sw']
    branch = ['beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu']
    jump = ['jal', 'jalr']

    instruction_types = [arith, logic, compare, shift, load, store, branch, jump]
    instruction_type_names = ['arith', 'logic', 'compare', 'shift', 'load', 'store', 'branch', 'jump']

    df = pd.read_csv(dataset_path)

    if(shuffle == True):
        df = df.sample(frac=1).reset_index(drop=True)

    if(board == "alveo"):

        branch_class_count = df[df.inst == df.loc[(df.inst.str.startswith('b'))].inst.unique()[0]].shape[0]
        # USE BRANCH TAKEN AND BRANCH NOT TAKEN AS SEPARATE INSTRUCTIONS
        #df.loc[(df.inst.str.startswith('b')) & (df.template_id >= int(branch_class_count/2)), 'inst'] = df.loc[(df.inst.str.startswith('b')) & (df.template_id >= int(branch_class_count/2)), 'inst']+'_nt'
        #df.loc[(df.inst.str.startswith('b')) & (df.template_id < int(branch_class_count/2)), 'inst'] = df.loc[(df.inst.str.startswith('b')) & (df.template_id < int(branch_class_count/2)), 'inst']+'_t'

        # USE BRANCH TAKEN AND BRANCH NOT TAKEN AS SAME INSTRUCTIONS, BUT 
        drop_idx = df.loc[(df.inst.str.startswith('b')) & (df.template_id >= int(3*branch_class_count/4)), 'inst'].index
        df.drop(drop_idx, inplace=True)
        drop_idx = df.loc[(df.inst.str.startswith('b')) & (df.template_id < int(branch_class_count/4)), 'inst'].index
        df.drop(drop_idx, inplace=True)

        if(sample_size == 0 or sample_size>(df.shape[0]/df.inst.unique().shape[0])):
            print("INVALID SAMPLE SIZE, MUST BE BIGGER THAN 0 OR LESS THAN THE MAX SAMPLE SIZE OF "+str(df.shape[0]/df.inst.unique().shape[0]))
            out_file.write("INVALID SAMPLE SIZE, MUST BE BIGGER THAN 0 OR LESS THAN THE MAX SAMPLE SIZE OF "+str(df.shape[0]/df.inst.unique().shape[0])+"\n")
            out_file.flush()
        elif(sample_size != -1):
            df = df[df.groupby(['inst']).cumcount()<sample_size]

        # IF WE HAVE A HIERARCHICAL MODEL, RENAME CLASSES
        if(hierarchical_type == 'top'):
            for inst_type_id, inst_type in enumerate(instruction_types):
                for inst in inst_type:
                    df['inst'] = df['inst'].replace({inst:instruction_type_names[inst_type_id]})
        elif(hierarchical_type in instruction_type_names):
            inst_index = instruction_type_names.index(hierarchical_type)
            df = df[df.inst.isin(instruction_types[inst_index])]

        df = df.drop("info", axis=1)
        df = df.drop("template_id", axis=1)

        #names = df.inst.unique()
        df.set_index('inst', inplace=True)

    else:
        if(sample_size == 0 or sample_size>(df.shape[0]/df.instruction.unique().shape[0])):
            print("INVALID SAMPLE SIZE, MUST BE BIGGER THAN 0 OR LESS THAN THE MAX SAMPLE SIZE OF "+str(df.shape[0]/df.instruction.unique().shape[0]))
            out_file.write("INVALID SAMPLE SIZE, MUST BE BIGGER THAN 0 OR LESS THAN THE MAX SAMPLE SIZE OF "+str(df.shape[0]/df.instruction.unique().shape[0])+"\n")
            out_file.flush()
        elif(sample_size != -1):
            df = df[df.groupby(['instruction']).cumcount()<sample_size]

        # IF WE HAVE A HIERARCHICAL MODEL, RENAME CLASSES
        if(hierarchical_type == 'top'):
            for inst_type_id, inst_type in enumerate(instruction_types):
                for inst in inst_type:
                    df['instruction'] = df['instruction'].replace({inst:instruction_type_names[inst_type_id]})
        elif(hierarchical_type in instruction_type_names):
            inst_index = instruction_type_names.index(hierarchical_type)
            df = df[df.instruction.isin(instruction_types[inst_index])]

        df = df.drop("opcode", axis=1)
        #names = df.instruction.unique()
        df.set_index('instruction', inplace=True)

    n_traces = len(df)
    print("It contains " + str(n_traces) + " traces!")
    out_file.write("It contains " + str(n_traces) + " traces!"+"\n")
    out_file.flush()
    # data
    X = df.values
    # label
    y = list(df.index)

    category = pd.Categorical(y)
    names = np.array(category.categories)
    print(category)
    print("--------")
    out_file.write("PRINTED CATEGORIES"+"\n")
    out_file.flush()
    print(category.codes)
    y = category.codes

    loaded=list()

    if(preprocessing=="none"):
        for i in sensor_ids:#range(0, n_sensors):
            S = X[:,i*n_samples:(i+1)*n_samples]
            loaded.append(S)
        loaded=np.dstack(loaded)
    elif(preprocessing=='CWT-H' or preprocessing=='CWT-V'):
        #if(seed_id == 0 and sample_size == 10000):
        #    loaded = np.load("dataset_"+preprocessing+".npy")
        #else:
        for trace in range(n_traces):
            for i in sensor_ids:#range(0, n_sensors):
                S = np.vstack((X[trace,i*n_samples:(i+1)*n_samples],np.absolute(CTW_extract_feature(X[trace,i*n_samples:(i+1)*n_samples]))))
                if(i == sensor_ids[0]):
                    wave_new = S
                else:
                    if(preprocessing=='CWT-H'):
                        wave_new = np.hstack((wave_new, S))
                    elif(preprocessing=='CWT-V'):
                        wave_new = np.vstack((wave_new, S))
            loaded.append(wave_new)  
        loaded = np.dstack(loaded)
        loaded = np.transpose(loaded, (2, 1, 0))

    loaded = np.array(loaded)

    print(loaded.shape)
    print(loaded.shape, file=out_file)
    print("\n", file=out_file)
    out_file.flush()

    if(normalize==True):
        for sensor in range(loaded.shape[2]):
            loaded[:,:,sensor]=data_normalize(loaded[:,:,sensor])

    print(y)
    print(y, file=out_file)
    print("\n", file=out_file)
    out_file.flush()
    print(y.shape)
    print(y.shape, file=out_file)
    print("\n", file=out_file)
    out_file.flush()
    y = to_categorical(y)
    print("one hot y:" + str(y))
    print("one hot y:" + str(y)+"\n", file=out_file)
    out_file.flush()

    X_train, X_test, y_train, y_test = model_selection.train_test_split(loaded, y, test_size=1-train_percent, random_state=42, stratify=y)

    return loaded,y, X_train, y_train, X_test,  y_test, names

#### draw confusion metrix
def plot_confusion_matrix(y_true, y_pred, out_file, classes,
                          normalize=False,
                          title=None,
                          cm_name="",
                          cmap=plt.cm.Blues):
    """
    This function prints and plots the confusion matrix.
    Normalization can be applied by setting `normalize=True`.
    """
    if not title:
        if normalize:
            title = 'Normalized confusion matrix'
        else:
            title = 'Confusion matrix, without normalization'

    # Compute confusion matrix
    cm = confusion_matrix(y_true, y_pred)
    # # Only use the labels that appear in the data
    # classes = classes[unique_labels(y_true, y_pred)]
    if normalize:
        cm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]
        #print("Normalized confusion matrix")
    else:
        pass
        #print('Confusion matrix, without normalization')
    ## store the confusion metrix
    print("confusion matrix:")
    print("confusion matrix:"+"\n", file=out_file)
    out_file.flush()
    print(cm)
    print(cm, file=out_file)
    print("\n", file=out_file)
    out_file.flush()
    cm_df=pd.DataFrame(cm,index=classes,columns=classes)
    cm_df.to_csv(cm_name+"confusion_metrix.csv")
    np.save(cm_name+"confusion_metrix.npy",cm)
    fig, ax = plt.subplots()
    im = ax.imshow(cm, interpolation='nearest', cmap=cmap)
    ax.figure.colorbar(im, ax=ax)
    # We want to show all ticks...
    ax.set(xticks=np.arange(cm.shape[1]),
           yticks=np.arange(cm.shape[0]),
           # ... and label them with the respective list entries
           xticklabels=classes, yticklabels=classes,
           title=title,
           ylabel='True label',
           xlabel='Predicted label')

    ax.set_ylim(len(classes)-0.5, -0.5)

    # Rotate the tick labels and set their alignment.
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right",
             rotation_mode="anchor")

    # Loop over data dimensions and create text annotations.
    fmt = '.2f' if normalize else 'd'
    thresh = cm.max() / 2.
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(j, i, format(cm[i, j], fmt),
                    ha="center", va="center",
                    color="white" if cm[i, j] > thresh else "black")
    # fig.tight_layout()
    plt.savefig(cm_name +"confusion_matrix.png", format='png')
    return ax

### function: generate the folder to store the data
def generate_folder(path,folder_name, out_file):
    isExists = os.path.exists(path+"//"+folder_name)
    print(isExists)
    out_file.write(str(isExists)+"\n")
    out_file.flush()
    if not isExists:
        os.makedirs(path+"//"+folder_name)
        print("Creat "+path+"//"+folder_name)
        out_file.write("Creat "+path+"//"+folder_name+"\n")
        out_file.flush()

    newpath=path+"//"+folder_name
    return newpath



parser = argparse.ArgumentParser(description='Model training program.')
parser.add_argument("-i", "--path_to_dataset", help="Path to dataset.csv.", required=True)
parser.add_argument("-b", "--board", help="Which board the dataset comes from: sakura or alveo.", required=True)
parser.add_argument("-id", "--run_id", help="Text id of the run.", required=True)
parser.add_argument("-seed", "--seed_id", help="The random seed.", required=True)
parser.add_argument("-ss", "--sample_size", help="How many samples per class to take from dataset", required=True)
parser.add_argument("-nse", "--n_sensors", help="How many sensors do the traces contain", required=True)
parser.add_argument("-sid", "--sensor_ids", help="Which sensors to use in the attack", required=True, type=int, nargs="*", default=[])
parser.add_argument("-nsa", "--n_samples", help="How many samples does each sensor trace contain", required=True)
parser.add_argument("-m", "--model", help="ML model: LSTM, CNN, CNN_small, LSTM+CNN, MLP, RFC", required=True)
parser.add_argument("-hr", "--hierarchical", help="hierarchical training: none, top, arith, logic, compare, shift, load, store, branch, jump", required=True)
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
sensor_ids = args.sensor_ids
n_sensors=int(args.n_sensors)
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

out_file = open(out_path+"/training_dump.txt", "w")
out_file.write("START TRAINING SCRIPT!!!!")
out_file.flush()

if(model!='LSTM' and model!='CNN' and model!='CNN_small' and model!='MLP' and model!='RFC' and model!='LSTM+CNN' and model!='CNN+LSTM' and model!='resnet' and model!='transformers' and model!='resnet_v1' and model!='resnet_v2' and model!='resnet_v3' and model!='resnet_v4' and model!='resnet_v5' and model!='bilstm_resnet' and model!='resnet_bilstm' and model!='resnet_bilstm_separated'):
    print("WRONG MODEL")
    out_file.write("WRONG MODEL"+"\n")
    out_file.flush()
    exit()
if(learning_rate>0.1):
    print("LEARNING RATE TOO BIG; SHOULD BE LESS OR EQUAL TO 0.1")
    out_file.write("LEARNING RATE TOO BIG; SHOULD BE LESS OR EQUAL TO 0.1"+"\n")
    out_file.flush()
    exit()
if(seed_id > 4 or seed_id < 0):
    print("SEED ID IS TOO BIG")
    out_file.write("SEED ID IS TOO BIG"+"\n")
    out_file.flush()
    exit()
if(preprocessing!="none" and preprocessing!="CWT-H" and preprocessing!="CWT-V"):
    print("Wrong preprocessing option!")
    out_file.write("Wrong preprocessing option!"+"\n")
    out_file.flush()
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
out_file.write("ARGUMENTS:"+"\n")
out_file.flush()
print("* Dataset: "+dataset_path)
out_file.write("* Dataset: "+dataset_path+"\n")
out_file.flush()
print("* Board: "+board)
out_file.write("* Board: "+board+"\n")
out_file.flush()
print("* N SENSORS: "+str(n_sensors))
out_file.write("* N SENSORS: "+str(n_sensors)+"\n")
out_file.flush()
print("* N SAMPLES: "+str(n_samples))
out_file.write("* N SAMPLES: "+str(n_samples)+"\n")
out_file.flush()
print("* Normalization: "+str(normalization))
out_file.write("* Normalization: "+str(normalization)+"\n")
out_file.flush()
print("* Preprocessing: "+preprocessing)
out_file.write("* Preprocessing: "+preprocessing+"\n")
out_file.flush()
print("* Model: "+model)
out_file.write("* Model: "+model+"\n")
out_file.flush()
print("* Hierarchical: "+hierarchical)
out_file.write("* Hierarchical: "+hierarchical+"\n")
out_file.flush()
print("* Epochs: "+str(epochs))
out_file.write("* Epochs: "+str(epochs)+"\n")
out_file.flush()
print("* Batch size: "+str(batch_size))
out_file.write("* Batch size: "+str(batch_size)+"\n")
out_file.flush()
print("* Learning Rate: ", learning_rate)
out_file.write("* Learning Rate: "+str(learning_rate)+"\n")
out_file.flush()
print("* K-fold rate: ", kfold)
out_file.write("* K-fold rate: "+str(kfold)+"\n")
out_file.flush()
print("* Dump Path: "+out_path)
out_file.write("* Dump Path: "+out_path+"\n")
out_file.flush()

seeds = [42, 906504, 8153, 10924, 3]
# Set input parameters
seed=setup_seed(seeds[seed_id])
model_folder='out/model/'
dataset_folder="out/dataset/"
record_folder="out/record/"
log_folder="out/log/"
cm_folder="out/cm/"

# Generate output folders
path=os.getcwd()
print(path)
out_file.write(path+"\n")
out_file.flush()
generate_folder(path,out_path, out_file)

#model_selected=model
model_selected='LSTM+CNN'

X, y, trainX, trainy, testX, testy, target_names = load_dataset(0.9, dataset_path, board, True, normalization, n_sensors, sensor_ids, n_samples, preprocessing, seed_id, hierarchical, out_file, sample_size)

generate_folder(path,model_folder, out_file)
generate_folder(path,dataset_folder, out_file)
generate_folder(path,record_folder, out_file)
generate_folder(path,log_folder, out_file)
generate_folder(path,cm_folder, out_file)

filename=record_folder+model_selected+"_record.txt"
f = open(filename,'w')
f.write("-------------"+str(model_selected)+'--------------------\n')
f.flush()

#DEFINE KFOLD
X_train_index_sets = []
X_test_index_sets  = []
Y_train_index_sets = []
Y_test_index_sets  = []
run_id_sets = []
model_name_sets = []
cm_name_sets = []
log_name_sets = []

if(kfold >= 2):
    filename="out/kfold_results.txt"
    acc_loss_f = open(filename,'w')
    acc_loss_f.write("-------------"+str(model_selected)+'--------------------\n')
    acc_loss_f.flush()
    kfold_accuracies = []
    kfold_losses = []

# IF KFOLD, THEN CREATE LIST OF SPLITS FOR TRAINING
if(kfold >= 2):
    kf = StratifiedKFold(n_splits=kfold)
    kf_iter = 0
    for train, test in kf.split(X, y.argmax(1)):
        X_train_index_sets.append(train)
        X_test_index_sets.append(test)
        Y_train_index_sets.append(train)
        Y_test_index_sets.append(test)
        run_id_sets.append(run_id+"_kf"+str(kf_iter))
        model_name_sets.append(model_folder+model_selected+"_kf"+str(kf_iter))
        cm_name_sets.append(cm_folder+model_selected+"_kf"+str(kf_iter))
        log_name_sets.append(log_folder+model_selected+"_kf"+str(kf_iter)+'.txt')
        kf_iter = kf_iter+1
else:
    # Append no matter what so that the next loop executes once
    X_train_index_sets.append(0)

#ITERATE OVER THE LISTS (IF NO KFOLD OVER THE ONE ELEMENT, IF KFOLD OVER ALL THE SPLITS)
for kf_index in range(len(X_train_index_sets)):

    f.write("----------------------------------------------------------------\n")
    f.flush()
    if(kfold < 2):
        f.write("---------------------- NO KFOLD --------------------------\n")
        f.flush()
        trainX_ = trainX
        testX_ = testX
        trainy_ = trainy
        testy_ = testy
        run_id_ = run_id
        model_name = model_folder+model_selected
        cm_name = cm_folder+model_selected
        log_name = log_folder+model_selected+'.txt'
    else:
        f.write("---------------------- KFOLD ITERATION "+str(kf_index)+"--------------------------\n")
        f.flush()
        trainX_ = X[X_train_index_sets[kf_index]]
        testX_ = X[X_test_index_sets[kf_index]]
        trainy_ = y[Y_train_index_sets[kf_index]]
        testy_ = y[Y_test_index_sets[kf_index]]
        run_id_ = run_id_sets[kf_index]
        model_name = model_name_sets[kf_index]
        cm_name = cm_name_sets[kf_index]
        log_name = log_name_sets[kf_index]

    print("Train X shape: ",trainX_.shape)
    print("Train Y shape: ",trainy_.shape)
    print("Test X shape: ", testX_.shape)
    print("Test Y shape: ", testy_.shape)

    out_file.write("START MODEL TRAINING"+"\n")
    out_file.flush()

    # model, history =run_model_selected(model_selected,trainX, trainy, testX, testy, epochs, batch_size, model_name, earlystop = 1)
    if(model=="LSTM+CNN"):
        model_out, history = m_lstm_cnn.lstm_cnn(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="CNN"):
        model_out, history = m_cnn.cnn(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="CNN_small"):
        model_out, history = m_cnn_small.cnn_small(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="LSTM"):
        model_out, history = m_lstm.lstm(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="MLP"):
        model_out, history = m_mlp.mlp(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="CNN+LSTM"):
        model_out, history = m_cnn_lstm.cnn_lstm(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="resnet"):
        model_out, history = m_resnet.resnet(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="resnet_v1"):
        model_out, history = m_resnet_v1.resnet_v1(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="resnet_v2"):
        model_out, history = m_resnet_v2.resnet_v2(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="resnet_v3"):
        model_out, history = m_resnet_v3.resnet_v3(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="resnet_v4"):
        model_out, history = m_resnet_v4.resnet_v4(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="resnet_v5"):
        model_out, history = m_resnet_v5.resnet_v5(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="bilstm_resnet"):
        model_out, history = m_bilstm_resnet.bilstm_resnet(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="resnet_bilstm"):
        model_out, history = m_resnet_bilstm.resnet_bilstm(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="resnet_bilstm_separated"):
        model_out, history = m_resnet_bilstm_separated.resnet_bilstm_separated(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="transformers"):
        model_out, history = m_transformers.transformers(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)
    elif(model=="RFC"):
        model_out, history = m_random_forest.rfc(trainX_, trainy_, testX_, testy_, epochs, batch_size, model_name, earlystop = 1, learning_rate=learning_rate, run_id=run_id_)#001)

    out_file.write("END MODEL TRAINING"+"\n")
    out_file.flush()

    # save the log

    if(model!="RFC"):
        saved_model = load_model(model_name +'_best_model.h5')
        with open(log_name,mode='wb') as file_txt:
            pickle.dump(str(history.history), file_txt)
        loss, score = saved_model.evaluate(testX_, testy_, batch_size=batch_size, verbose=2)
        score = score * 100.0
        print('score: %.3f' % (score))
        out_file.write('score: %.3f' % (score)+"\n")
        out_file.flush()
        f.write("loss:"+str(loss)+'\n')
        f.flush()
        f.write("accuracy:"+str(score)+'\n')
        f.flush()

        if(kfold>=2):
            acc_loss_f.write("kf: "+str(kf_index)+"; loss = "+str(loss)+"; accuracy = "+str(score)+"\n")
            acc_loss_f.flush()
            kfold_accuracies.append(score)
            kfold_losses.append(loss)

        ## evalyate the dataset
        Y_test = np.argmax(testy_, axis=1)
        predict_y = saved_model.predict(testX_)
        y_pred = np.argmax(predict_y, axis=1)
    else:
        with open(log_name,mode='wb') as file_txt:
            pickle.dump(str(history), file_txt)
        saved_model = pickle.load(open(model_name+'_best_model.h5', 'rb'))
        f.write("Accuracy: "+str(history))
        f.flush()
        ## evalyate the dataset
        Y_test = np.argmax(testy_, axis=1)
        X_test_2D = testX_.reshape((testX_.shape[0],testX_.shape[1]*testX_.shape[2]))
        predict_y = saved_model.predict(X_test_2D)
        y_pred = np.argmax(predict_y, axis=1)

    print(classification_report(Y_test, y_pred, target_names=target_names))
    out_file.write(classification_report(Y_test, y_pred, target_names=target_names)+"\n")
    print(classification_report(Y_test, y_pred, target_names=target_names), file=out_file)
    print("\n", file=out_file)
    out_file.flush()
    f.write("report for every class:\n")
    f.flush()
    f.write(classification_report(Y_test, y_pred, target_names=target_names))
    f.flush()
    # draw confusion metic
    # Sept 5. Output confusion metrix: a CSV file and a fig file.
    plot_confusion_matrix(Y_test, y_pred, out_file, classes=target_names, cm_name=cm_name, normalize=True)

if(kfold >= 2):
    acc_loss_f.write("AVERAGE LOSS: "+str(np.array(kfold_losses).mean())+"\n")
    acc_loss_f.flush()
    acc_loss_f.write("AVERAGE ACCURACY: "+str(np.array(kfold_accuracies).mean())+"\n")
    acc_loss_f.flush()
    acc_loss_f.close()

f.close()
out_file.close()
