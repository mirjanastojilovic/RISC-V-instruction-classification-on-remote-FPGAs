/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

#ifndef UTILS_H
#define UTILS_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <libgen.h>
#include <time.h>

typedef struct config {

  int n_traces;
  int osc_en;
  int calib;
  int sensor_en;
  int n_samples;
  int start_sample;
  char dump_path[200];
  char inst_file[200];

} config_t;

typedef struct metadata_line {

  char csv_line[1000];
  char inst_name[100];
  char inst_info[100];
  int  template_id;
  int  asm_line;
  char hex_val[100];
  int  start_sample;
  int  end_sample;

} metadata_line;


void print_help();
int parse_args(int argc, char* argv[], config_t* config); 
int init_config(config_t* config);
int print_config(config_t* config);
void initialize_random(unsigned char array[16]);
void sbox_key_pt(int trace, unsigned char pt[16], unsigned char key[16]);
unsigned char hamming_weight(unsigned char byte);

int get_line_number(char * file_name);
int load_instructions(char * file_name, unsigned char *** instructions, int * line_num);
char *get_filename(char *filename);
void get_csv_line(metadata_line * metadata, FILE * metadata_f);

#endif
