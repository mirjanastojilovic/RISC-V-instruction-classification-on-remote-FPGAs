# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# Jinwei Yao summer@epfl
# PCA/LDA + GDM/kNN/QDA/SVM

import pickle
import numpy as np
from numpy import mean
from numpy import std
from numpy import dstack
from pandas import read_csv

#sklearn
from matplotlib import pyplot
import pandas as pd
from sklearn.metrics import classification_report
from sklearn import model_selection
from sklearn.model_selection import KFold
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import MinMaxScaler, StandardScaler
from sklearn.model_selection import train_test_split

from tensorflow.keras.utils import to_categorical
# CWT 
import pycwt as wavelet
from cwt_feature_extraction import CTW_extract_feature
# LDA
from LDA import myLDA
# PCA
from sklearn.decomposition import PCA
import argparse
import random
import os

#### classifiers
##GDM/kNN/QDA/SVM
from sklearn.naive_bayes import GaussianNB
## KNN
from sklearn.neighbors import KNeighborsClassifier
from sklearn.discriminant_analysis import QuadraticDiscriminantAnalysis
from sklearn.svm import LinearSVC

def setup_seed(seed):
    random.seed(seed)  # set random seed for python
    np.random.seed(seed)  # set random seed for  numpy
    #tf.random.set_seed(seed)  # tf cpu fix seed
    os.environ['PYTHONHASHSEED']=str(seed)
    os.environ['TF_DETERMINISTIC_OPS'] = '1'  # tf gpu fix seed, please `pip install tensorflow-determinism` first

def data_normalize(dataset):
    #scaler = MinMaxScaler(feature_range=(-1,1))
    # https://www.cnblogs.com/weiyunpeng/p/12250308.html z-scorre
    scaler = StandardScaler()
    scaler.fit(dataset)#  
    # scaler.data_max_
    dataset_normorlize = scaler.transform(dataset) #
    return dataset_normorlize

# load the dataset, returns train and test X and y elements
# load the dataset, returns train and test X and y elements
def load_dataset(train_percent, dataset_path, shuffle, normalize, n_sensors, sensor_ids, n_samples, seed_id, out_file, sample_size=-1):

    df = pd.read_csv(dataset_path)

    if(shuffle == True):
        df = df.sample(frac=1).reset_index(drop=True)

    if(sample_size == 0 or sample_size>(df.shape[0]/df.instruction.unique().shape[0])):
        print("INVALID SAMPLE SIZE, MUST BE BIGGER THAN 0 OR LESS THAN THE MAX SAMPLE SIZE OF "+str(df.shape[0]/df.instruction.unique().shape[0]))
        out_file.write("INVALID SAMPLE SIZE, MUST BE BIGGER THAN 0 OR LESS THAN THE MAX SAMPLE SIZE OF "+str(df.shape[0]/df.instruction.unique().shape[0])+"\n")
        out_file.flush()
    elif(sample_size != -1):
        df = df[df.groupby(['instruction']).cumcount()<sample_size]

    df = df.drop("opcode", axis=1)

    names = df.instruction.unique()

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
    print(category)
    print("--------")
    out_file.write("PRINTED CATEGORIES"+"\n")
    out_file.flush()
    print(category.codes)
    y = category.codes
    
    loaded = np.array(X)

    print(loaded.shape)
    print(loaded.shape, file=out_file)
    print("\n", file=out_file)
    out_file.flush()

    if(normalize==True):
        loaded = data_normalize(loaded)

    print(y)
    print(y, file=out_file)
    print("\n", file=out_file)
    out_file.flush()
    print(y.shape)
    print(y.shape, file=out_file)
    print("\n", file=out_file)
    out_file.flush()

    return loaded, y

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
parser.add_argument("-seed", "--seed_id", help="The random seed.", required=True)
parser.add_argument("-ss", "--sample_size", help="How many samples per class to take from dataset", required=True)
parser.add_argument("-nse", "--n_sensors", help="How many sensors do the traces contain", required=True)
parser.add_argument("-sid", "--sensor_ids", help="Which sensors to use in the attack", required=True, type=int, nargs="*", default=[])
parser.add_argument("-nsa", "--n_samples", help="How many samples does each sensor trace contain", required=True)
parser.add_argument("-m", "--model", help="ML model: LSTM, CNN, CNN_small, LSTM+CNN, MLP, RFC", required=True)
parser.add_argument("-n", "--normalization", help="0: no normalization, 1: normalization", required=True)#default=”default path”
parser.add_argument("-kf", "--kfold", help="<=1: no kfolding, >=2 kfold with 2 or higher", required=True)
parser.add_argument("-o", "--path_to_output", help="Path to output directory.", required=True)

args = parser.parse_args()

dataset_path=args.path_to_dataset
seed_id = int(args.seed_id)
sample_size=int(args.sample_size)
sensor_ids = args.sensor_ids
n_sensors=int(args.n_sensors)
n_samples=int(args.n_samples)
normalization=bool(int(args.normalization))
model=args.model
kfold=int(args.kfold)
out_path=args.path_to_output

out_file = open(out_path+"/training_dump.txt", "w")
out_file.write("START TRAINING SCRIPT!!!!"+"\n")
out_file.flush()

f = open(out_path+"/results.txt", "w")
f.write("Training results"+"\n")
f.flush()

if(kfold>=2):
    avg_f = open(out_path+"/results_averaged.txt", "w")
    avg_f.write("Training results"+"\n")
    avg_f.flush()

if(model!='classical'):
    print("WRONG MODEL")
    out_file.write("WRONG MODEL"+"\n")
    out_file.flush()
    exit()
if(seed_id > 4 or seed_id < 0):
    print("SEED ID IS TOO BIG")
    out_file.write("SEED ID IS TOO BIG"+"\n")
    out_file.flush()
    exit()
if(kfold<1):
    kfold = 1

print("ARGUMENTS:")
out_file.write("ARGUMENTS:"+"\n")
out_file.flush()
print("* Dataset: "+dataset_path)
out_file.write("* Dataset: "+dataset_path+"\n")
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
print("* K-fold rate: ", kfold)
out_file.write("* K-fold rate: "+str(kfold)+"\n")
out_file.flush()
print("* Dump Path: "+out_path)
out_file.write("* Dump Path: "+out_path+"\n")
out_file.flush()

seeds = [42, 906504, 8153, 10924, 3]
# Set input parameters
seed=setup_seed(seeds[seed_id])
# Generate output folders
path=os.getcwd()
print(path)
out_file.write(path+"\n")
out_file.flush()
generate_folder(path,out_path, out_file)

feature_extr=['PCA','LDA']
classifiers=['GDM','KNN','QDA','SVM']
classifier_idx = {'GDM': 0,'KNN': 1,'QDA':2,'SVM':3}

X_ld, y = load_dataset(0.9, dataset_path, True, normalization, n_sensors, sensor_ids, n_samples, seed_id, out_file, sample_size)

#DEFINE KFOLD
X_train_index_sets = []
X_test_index_sets  = []
Y_train_index_sets = []
Y_test_index_sets  = []

if(kfold >= 2):
    kfold_accuracies = [[], [], [], []]
    kfold_accuracies_true = [[], [], [], []]

# IF KFOLD, THEN CREATE LIST OF SPLITS FOR TRAINING
if(kfold >= 2):
    kf = StratifiedKFold(n_splits=kfold)
    for train, test in kf.split(X_ld, y):
        X_train_index_sets.append(train)
        X_test_index_sets.append(test)
        Y_train_index_sets.append(train)
        Y_test_index_sets.append(test)
else:
    # Append no matter what so that the next loop executes once
    X_train_index_sets.append(0)

for fea_select in feature_extr:

    print("PREPROCESSING : "+fea_select)
    out_file.write("PREPROCESSING : "+fea_select+"\n")
    if fea_select=='PCA':
        # default setting: n_components == min(n_samples, n_features)
        pca = PCA( )
        X=pca.fit_transform(X_ld, y=None)
        print("PCA data size",X.shape)
        print("PCA data size",file=out_file)
        print(X.shape, file=out_file)
        print("\n", file=out_file)
    elif fea_select=='LDA':
        new_features_number=19
        X=myLDA(X_ld,y,new_features_number)
        print("LDA data size",X.shape)
        print("LDA data size",file=out_file)
        print(X.shape, file=out_file)
        print("\n", file=out_file)

    #ITERATE OVER THE LISTS (IF NO KFOLD OVER THE ONE ELEMENT, IF KFOLD OVER ALL THE SPLITS)
    for kf_index in range(len(X_train_index_sets)):

        out_file.write("----------------------------------------------------------------\n")
        out_file.flush()
        if(kfold < 2):
            out_file.write("---------------------- NO KFOLD --------------------------\n")
            out_file.flush()
            X_train, X_test, y_train, y_test = model_selection.train_test_split(X, y, test_size=1-0.9, random_state=42, stratify=y)
        else:
            out_file.write("---------------------- KFOLD ITERATION "+str(kf_index)+"--------------------------\n")
            out_file.flush()
            X_train = X[X_train_index_sets[kf_index]]
            X_test = X[X_test_index_sets[kf_index]]
            y_train = y[Y_train_index_sets[kf_index]]
            y_test = y[Y_test_index_sets[kf_index]]

        for classifier in classifiers:
            print("MODEL : "+classifier)
            out_file.write("MODEL : "+classifier+"\n")
            out_file.flush()
            if classifier=='GDM':
                gnb = GaussianNB()
                y_pred = gnb.fit(X_train, y_train).predict(X_test)
                acc=1.00*(y_test == y_pred).sum()/(X_test.shape[0])
                true_acc=1.00*(y_test == y_pred).sum()/(X_test.shape[0])
            elif classifier=='KNN':
                knn = KNeighborsClassifier(n_neighbors=3)
                knn.fit(X_train,y_train)
                y_pred=knn.predict(X_test)
                acc=knn.score( X_test , y_test , sample_weight = None )
                true_acc=1.00*(y_test == y_pred).sum()/(X_test.shape[0])
            elif classifier=='QDA':
                qda=QuadraticDiscriminantAnalysis()
                qda.fit(X_train,y_train)
                y_pred=qda.predict(X_test)
                acc=qda.score( X_test , y_test , sample_weight = None )
                true_acc=1.00*(y_test == y_pred).sum()/(X_test.shape[0])
            elif classifier=='SVM':
                svm=LinearSVC(max_iter=10000, dual=False)
                svm.fit(X_train,y_train)
                y_pred=svm.predict(X_test)
                acc=svm.score( X_test , y_test , sample_weight = None )
                true_acc=1.00*(y_test == y_pred).sum()/(X_test.shape[0])
            if(kfold>=2):
                kfold_accuracies_true[classifier_idx[classifier]].append(true_acc)
                kfold_accuracies[classifier_idx[classifier]].append(acc)
                print("KF"+str(kf_index)+": "+classifier+" "+fea_select+"; accuracy: "+ str(acc)+" true accuracy: "+ str(true_acc))
                out_file.write("KF"+str(kf_index)+": "+classifier+" "+fea_select+"; accuracy: "+ str(acc)+" true accuracy: "+ str(true_acc)+"\n")
                f.write("KF"+str(kf_index)+": "+classifier+" "+fea_select+"; accuracy: "+ str(acc)+" true accuracy: "+ str(true_acc)+"\n")
                f.flush()
            else:
                print(classifier+" "+fea_select+"; accuracy: "+ str(acc)+" true accuracy: "+ str(true_acc))
                out_file.write(classifier+" "+fea_select+"; accuracy: "+ str(acc)+" true accuracy: "+ str(true_acc)+"\n")
                f.write(classifier+" "+fea_select+"; accuracy: "+ str(acc)+" true accuracy: "+ str(true_acc)+"\n")
                f.flush()
    if(kfold >= 2):
        for classifier in classifiers:
            avg_f.write("AVERAGE ACCURACY: "+classifier+" "+fea_select+";"+str(np.array(kfold_accuracies[classifier_idx[classifier]]).mean())+"\n")
            avg_f.write("AVERAGE ACCURACY TRUE: "+classifier+" "+fea_select+";"+str(np.array(kfold_accuracies_true[classifier_idx[classifier]]).mean())+"\n")
            avg_f.flush()

if(kfold >= 2):
    avg_f.close()
out_file.close()
f.close()
