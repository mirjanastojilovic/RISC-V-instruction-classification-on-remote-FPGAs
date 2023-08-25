/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

#ifndef AES_H
#define AES_H

#define ONE_BYTE 1
#define AES_SIZE 16 // in bytes

#include <stdio.h>
#include "Sasebogii.h"

typedef struct state_t {
  unsigned char key[AES_SIZE];
  unsigned char plain[AES_SIZE];
  unsigned char cipher[AES_SIZE];
  unsigned char cipher_chained[AES_SIZE];
} state_t;

int set_key(FT_HANDLE sasebo, unsigned char* key);
int encdec(FT_HANDLE sasebo, int data);
int encrypt(FT_HANDLE sasebo, unsigned char* plaintext, unsigned char* cipher);
void print_value(unsigned char* value, FILE* f);

FT_HANDLE* sasebo_reinit(FT_HANDLE* handle);
int calibrate_sensor_interactive(FT_HANDLE * handle, int n_samples);
int calibrate_sensor_multiple(FT_HANDLE * handle, int n_samples, int n_sensors, unsigned char idc_idf[][16]);
int calibrate_sensor(FT_HANDLE * handle, int n_samples);

#endif
