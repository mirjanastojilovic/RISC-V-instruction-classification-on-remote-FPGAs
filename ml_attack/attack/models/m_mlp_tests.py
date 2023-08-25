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
from tensorflow.keras.optimizers import SGD
from keras.callbacks import ReduceLROnPlateau
from keras.layers import LeakyReLU

import wandb
from wandb.keras import WandbCallback

def mlp1(X_train, y_train, X_test, y_test, epochs, batch_size, path, learning_rate, optimizer, run_id):

    wandb.init(project="MLP_Exploration", entity="instruction-identification", name=run_id)

    wandb.config = {
        "learning_rate": learning_rate,
        "epochs" : epochs,
        "batch_size" : batch_size
    }

    print("INPUT MODEL SHAPE:", X_train.shape)

    n_timesteps, n_features, n_outputs = X_train.shape[1], X_train.shape[2], y_train.shape[1]

    model = Sequential()
    model.add(Flatten())
    model.add(Dense(300, input_shape=(n_timesteps*n_features,)))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(200))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(150))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(150))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(80))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(n_outputs, activation='softmax'))

    # Model compile
    if(optimizer == 'Adam'):
        opti = Adam(lr=learning_rate)
    else:
        opti = SGD(lr=learning_rate)
    model.compile(loss='categorical_crossentropy', optimizer=opti, metrics=['accuracy'])
    # model checkpoint saving the best model based on val_loss 
    mc = ModelCheckpoint(path+'_best_model.h5', monitor='val_loss', mode='min', verbose=1, save_best_only=True)
    # simple early stopping
    history = model.fit(X_train, y_train, epochs=epochs, batch_size=batch_size, validation_data=(X_test, y_test), verbose=2, callbacks=[mc, WandbCallback()])

    wandb.finish()

    return model, history

def mlp2(X_train, y_train, X_test, y_test, epochs, batch_size, path, learning_rate, optimizer, run_id):

    wandb.init(project="MLP_Exploration", entity="instruction-identification", name=run_id)

    wandb.config = {
        "learning_rate": learning_rate,
        "epochs" : epochs,
        "batch_size" : batch_size
    }

    print("INPUT MODEL SHAPE:", X_train.shape)

    n_timesteps, n_features, n_outputs = X_train.shape[1], X_train.shape[2], y_train.shape[1]

    model = Sequential()
    model.add(Flatten())
    model.add(Dense(300, input_shape=(n_timesteps*n_features,)))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(500))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(800))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(600))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(400))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(200))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(150))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(80))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(n_outputs, activation='softmax'))

    # Model compile
    if(optimizer == 'Adam'):
        opti = Adam(lr=learning_rate)
    else:
        opti = SGD(lr=learning_rate)
    model.compile(loss='categorical_crossentropy', optimizer=opti, metrics=['accuracy'])
    # model checkpoint saving the best model based on val_loss 
    mc = ModelCheckpoint(path+'_best_model.h5', monitor='val_loss', mode='min', verbose=1, save_best_only=True)
    # simple early stopping
    history = model.fit(X_train, y_train, epochs=epochs, batch_size=batch_size, validation_data=(X_test, y_test), verbose=2, callbacks=[mc, WandbCallback()])

    wandb.finish()

    return model, history

def mlp_embedding(X_train, y_train, X_test, y_test, unique, epochs, batch_size, path, learning_rate, optimizer, out_dim, run_id):

    wandb.init(project="MLP_Exploration", entity="instruction-identification", name=run_id)

    wandb.config = {
        "learning_rate": learning_rate,
        "epochs" : epochs,
        "batch_size" : batch_size
    }

    print("INPUT MODEL SHAPE:", X_train.shape)

    n_timesteps, n_features, n_outputs = X_train.shape[1], X_train.shape[2], y_train.shape[1]

    model = Sequential()
    model.add(Flatten())
    model.add(Embedding(input_dim=unique, output_dim=out_dim, input_length=n_timesteps*n_features))
    model.add(Flatten())
    model.add(Dense(300))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(500))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(800))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(600))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(400))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(200))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(150))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(80))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(n_outputs, activation='softmax'))

    # Model compile
    if(optimizer == 'Adam'):
        opti = Adam(lr=learning_rate)
    else:
        opti = SGD(lr=learning_rate)
    model.compile(loss='categorical_crossentropy', optimizer=opti, metrics=['accuracy'])
    # model checkpoint saving the best model based on val_loss 
    mc = ModelCheckpoint(path+'_best_model.h5', monitor='val_loss', mode='min', verbose=1, save_best_only=True)
    # simple early stopping
    history = model.fit(X_train, y_train, epochs=epochs, batch_size=batch_size, validation_data=(X_test, y_test), verbose=2, callbacks=[mc, WandbCallback()])

    wandb.finish()

    return model, history

def mlp_embedding2(X_train, y_train, X_test, y_test, unique, epochs, batch_size, path, learning_rate, optimizer, out_dim, run_id):

    wandb.init(project="MLP_Exploration", entity="instruction-identification", name=run_id)

    wandb.config = {
        "learning_rate": learning_rate,
        "epochs" : epochs,
        "batch_size" : batch_size
    }

    print("INPUT MODEL SHAPE:", X_train.shape)

    n_timesteps, n_features, n_outputs = X_train.shape[1], X_train.shape[2], y_train.shape[1]

    model = Sequential()
    model.add(Flatten())
    model.add(Embedding(input_dim=unique, output_dim=out_dim, input_length=n_timesteps*n_features))
    model.add(Flatten())
    model.add(Dense(300))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(200))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(150))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dense(150))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(80))
    model.add(LeakyReLU(alpha=0.3))
    model.add(Dropout(0.2))
    model.add(Dense(n_outputs, activation='softmax'))

    # Model compile
    if(optimizer == 'Adam'):
        opti = Adam(lr=learning_rate)
    else:
        opti = SGD(lr=learning_rate)
    model.compile(loss='categorical_crossentropy', optimizer=opti, metrics=['accuracy'])
    # model checkpoint saving the best model based on val_loss 
    mc = ModelCheckpoint(path+'_best_model.h5', monitor='val_loss', mode='min', verbose=1, save_best_only=True)
    # simple early stopping
    history = model.fit(X_train, y_train, epochs=epochs, batch_size=batch_size, validation_data=(X_test, y_test), verbose=2, callbacks=[mc, WandbCallback()])

    wandb.finish()

    return model, history



def mlp_embedding_sine(X_train, y_train, X_test, y_test, unique, epochs, batch_size, path, learning_rate, optimizer, out_dim, run_id):

    wandb.init(project="MLP_Exploration", entity="instruction-identification", name=run_id)

    wandb.config = {
        "learning_rate": learning_rate,
        "epochs" : epochs,
        "batch_size" : batch_size
    }

    print("INPUT MODEL SHAPE:", X_train.shape)

    n_timesteps, n_features, n_outputs = X_train.shape[1], X_train.shape[2], y_train.shape[1]

    input_layer = Input(shape=(n_timesteps, n_features))
    flattened_input = Flatten()(input_layer)
    embedding = Embedding(input_dim=unique, output_dim=out_dim, input_length=n_timesteps*n_features)(flattened_input)
    positional_encoding = keras_nlp.layers.SinePositionEncoding()(embedding)
    embedded_outputs = embedding + positional_encoding
    l1 = Flatten()(embedded_outputs)
    l2 = Dense(300)(l1)
    l3 = LeakyReLU(alpha=0.3)(l2)
    l4 = Dense(500)(l3)
    l5 = LeakyReLU(alpha=0.3)(l4)
    l6 = Dropout(0.2)(l5)
    l7 = Dense(800)(l6)
    l8 = LeakyReLU(alpha=0.3)(l7)
    l9 = Dense(600)(l8)
    l10 = LeakyReLU(alpha=0.3)(l9)
    l11 = Dropout(0.2)(l10)
    l12 = Dense(400)(l11)
    l13 = LeakyReLU(alpha=0.3)(l12)
    l14 = Dense(200)(l13)
    l15 = LeakyReLU(alpha=0.3)(l14)
    l16 = Dropout(0.2)(l15)
    l17 = Dense(150)(l16)
    l18 = LeakyReLU(alpha=0.3)(l17)
    l19 = Dense(80)(l18)
    l20 = LeakyReLU(alpha=0.3)(l19)
    l21 = Dropout(0.2)(l20)
    output_layer = Dense(n_outputs, activation='softmax')(l21)

    model = Model(inputs=input_layer, outputs=output_layer)

    # Model compile
    if(optimizer == 'Adam'):
        opti = Adam(lr=learning_rate)
    else:
        opti = SGD(lr=learning_rate)
    model.compile(loss='categorical_crossentropy', optimizer=opti, metrics=['accuracy'])
    # model checkpoint saving the best model based on val_loss 
    mc = ModelCheckpoint(path+'_best_model.h5', monitor='val_loss', mode='min', verbose=1, save_best_only=True)
    # simple early stopping
    history = model.fit(X_train, y_train, epochs=epochs, batch_size=batch_size, validation_data=(X_test, y_test), verbose=2, callbacks=[mc, WandbCallback()])

    wandb.finish()

    return model, history
