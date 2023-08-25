# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# Keras
import numpy as np
import pickle
import os
import tensorflow as tf
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from keras.models import Sequential, Model
from keras.layers import BatchNormalization, TimeDistributed, Input, Dense, Flatten, LSTM, Conv1D, Conv2D,MaxPooling1D, Dropout, Activation, Reshape, ConvLSTM2D, add
from keras.layers.embeddings import Embedding
from keras.layers.pooling import GlobalAveragePooling1D
from keras.layers.merge import concatenate
from keras.utils.vis_utils import plot_model
from keras.callbacks import EarlyStopping
from keras.callbacks import ModelCheckpoint
from tensorflow.keras.optimizers import Adam
from keras.callbacks import ReduceLROnPlateau
from keras.layers import LeakyReLU
from sklearn.ensemble import RandomForestClassifier
import sklearn

import wandb
from wandb.keras import WandbCallback

"""
BiLSTM-CNN Architecture 

Parameters:
    - X_train, X_test -> Time series values divided in train and test data
    - y_train, y test -> Time series classes divided in train and test data
    - epochs -> Number of epochs for learning
    - batch_size -> Size of the batch for training
    - path -> Where it will be stored
    - earlystop -> 0 if don't use early stopping, or 1 otherwise
Ouputs:
    - model -> Last model trained
    - history -> Learning history
"""

def rfc(X_train, y_train, X_test, y_test, epochs, batch_size, path, earlystop, learning_rate, run_id):

    wandb.init(project="Instruction_Identification", entity="instruction-identification", name=run_id)

    wandb.config = {
        "learning_rate": learning_rate,
        "epochs" : epochs,
        "batch_size" : batch_size
    }

    print("INPUT MODEL SHAPE:", X_train.shape)

    n_timesteps, n_features, n_outputs = X_train.shape[1], X_train.shape[2], y_train.shape[1]

    X_train_2D = X_train.reshape((X_train.shape[0],n_timesteps*n_features))
    X_test_2D = X_test.reshape((X_test.shape[0],X_test.shape[1]*X_test.shape[2]))

    #Create a Gaussian Classifier
    clf=RandomForestClassifier(n_estimators=100)

    #Train the model using the training sets y_pred=clf.predict(X_test)
    model = clf.fit(X_train_2D,y_train)

    y_pred=clf.predict(X_test_2D)

    accuracy = sklearn.metrics.accuracy_score(y_test, y_pred)

    wandb.log({"accuracy": accuracy})

    filename = path+'_best_model.h5'
    pickle.dump(clf, open(filename, 'wb'))

    wandb.finish()

    return clf, accuracy
