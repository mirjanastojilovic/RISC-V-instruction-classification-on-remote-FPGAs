# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# Keras
import numpy as np
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

import wandb
from wandb.keras import WandbCallback

"""
ResNet Architecture

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

def resnet_bilstm_separated(X_train, y_train, X_test, y_test, epochs, batch_size, path, earlystop, learning_rate, run_id):

    wandb.init(project="Instruction_Identification", entity="instruction-identification", name=run_id)

    wandb.config = {
        "learning_rate": learning_rate,
        "epochs" : epochs,
        "batch_size" : batch_size
    }

    print("INPUT MODEL SHAPE:", X_train.shape)
    
    n_timesteps, n_features, n_outputs = X_train.shape[1], X_train.shape[2], y_train.shape[1]
    n_feature_maps = 64

    # head 1
    inputs_layer1 = Input(shape=(n_timesteps,n_features))

    conv_x = Conv1D(filters=n_feature_maps, kernel_size=8, padding='same')(inputs_layer1)
    conv_x = BatchNormalization()(conv_x)
    conv_x = Activation('relu')(conv_x)

    conv_y = Conv1D(filters=n_feature_maps, kernel_size=5, padding='same')(conv_x)
    conv_y = BatchNormalization()(conv_y)
    conv_y = Activation('relu')(conv_y)

    conv_z = Conv1D(filters=n_feature_maps, kernel_size=3, padding='same')(conv_y)
    conv_z = BatchNormalization()(conv_z)

    # expand channels for the sum 
    shortcut_y = Conv1D(filters=n_feature_maps, kernel_size=1, padding='same')(inputs_layer1)
    shortcut_y = BatchNormalization()(shortcut_y)

    output_block_1 = add([shortcut_y, conv_z])
    output_block_1 = Activation('relu')(output_block_1)

    # BLOCK 2 

    conv_x = Conv1D(filters=n_feature_maps*2, kernel_size=8, padding='same')(output_block_1)
    conv_x = BatchNormalization()(conv_x)
    conv_x = Activation('relu')(conv_x)

    conv_y = Conv1D(filters=n_feature_maps*2, kernel_size=5, padding='same')(conv_x)
    conv_y = BatchNormalization()(conv_y)
    conv_y = Activation('relu')(conv_y)

    conv_z = Conv1D(filters=n_feature_maps*2, kernel_size=3, padding='same')(conv_y)
    conv_z = BatchNormalization()(conv_z)

    # expand channels for the sum 
    shortcut_y = Conv1D(filters=n_feature_maps*2, kernel_size=1, padding='same')(output_block_1)
    shortcut_y = BatchNormalization()(shortcut_y)

    output_block_2 = add([shortcut_y, conv_z])
    output_block_2 = Activation('relu')(output_block_2)

    # BLOCK 3 

    conv_x = Conv1D(filters=n_feature_maps*2, kernel_size=8, padding='same')(output_block_2)
    conv_x = BatchNormalization()(conv_x)
    conv_x = Activation('relu')(conv_x)

    conv_y = Conv1D(filters=n_feature_maps*2, kernel_size=5, padding='same')(conv_x)
    conv_y = BatchNormalization()(conv_y)
    conv_y = Activation('relu')(conv_y)

    conv_z = Conv1D(filters=n_feature_maps*2, kernel_size=3, padding='same')(conv_y)
    conv_z = BatchNormalization()(conv_z)

    # no need to expand channels because they are equal 
    shortcut_y = BatchNormalization()(output_block_2)

    output_block_3 = add([shortcut_y, conv_z])
    output_block_3 = Activation('relu')(output_block_3)

    # FINAL 
    
    gap_layer = GlobalAveragePooling1D()(output_block_3)


    # LSTM block
    
    inputs_layer2 = Input(shape=(n_timesteps,n_features))
    lstm = LSTM(128, return_sequences=True)(inputs_layer2)
    flat = Flatten()(lstm)
    
    merged = concatenate([gap_layer, flat])

    output_layer = Dense(n_outputs, activation='softmax')(merged)

    model = Model(inputs=[inputs_layer1, inputs_layer2], outputs=output_layer)

    # Model compile
    opti = Adam(lr=learning_rate)
    model.compile(loss='categorical_crossentropy', optimizer=opti, metrics=['accuracy'])
    # rate learning
    reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=5, min_lr=0.000001)
    # model checkpoint saving the best model based on val_loss 
    mc = ModelCheckpoint(path+'_best_model.h5', monitor='val_loss', mode='min', verbose=1, save_best_only=True)
    # simple early stopping
    if earlystop == 1:
        es = EarlyStopping(monitor='val_loss', mode='min', verbose=1, patience=200)
        # fit network
        history = model.fit(X_train, y_train, epochs=epochs, batch_size=batch_size, validation_data=(X_test, y_test), verbose=2, callbacks=[es, mc, reduce_lr, WandbCallback()])
    
    else:
        history = model.fit(X_train, y_train, epochs=epochs, batch_size=batch_size, validation_data=(X_test, y_test), verbose=2, callbacks=[mc, reduce_lr, WandbCallback()])

    wandb.finish()
    
    return model, history

