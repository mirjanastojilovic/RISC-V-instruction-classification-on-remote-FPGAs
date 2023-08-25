/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

#include "utils.h"

void print_help() {
  printf("HELP\n");
  printf("\n==================================================\n");
  printf("CPU Power Side-Channel Measurement Software\n");
  printf("\n==================================================\n");
  printf("\nShort summary:\n");
  printf("\t- This program sends instructions to a CPU on FPGA, and reads the recorded sensor and oscilloscope power traces of its execution.\n");
  printf("\n==================================================\n");
  printf("\nProgram arguments:\n");
  printf("\t-h:               print help\n");
  printf("\t-t <number>:      number of repeated traces per instruction file.\n");
  printf("\t-o:               save oscilloscope traces\n");
  printf("\t-s <start> <end>: save sensor traces starting from sample <start> until sample <end>\n");
  printf("\t-c <number>:      calibration type\n");
  printf("\t\t- 0              use default calibration value\n");
  printf("\t\t- 1              use automatic calibration in software\n");
  printf("\t-i <file-path>:   specify path to file containing instructions for the CPU\n");
  printf("\t-d <dir-path>:    specify output directory\n");
  printf("\n\n\n");

  return;
}

int parse_args(int argc, char* argv[], config_t* config) {
  if(argc == 1) {
    return EXIT_SUCCESS;
  }

  if(argv == NULL) {
    fprintf(stderr, "Passed NULL argument string to parse_args\n");
    return EXIT_FAILURE;
  }

  for(int i = 1; i < argc; i++) {
    if(argv[i][1] == 'h') {
      print_help();
      exit(1);
    } else if(argv[i][1] == 't') {
      i++;
      config->n_traces = atoi(argv[i]);
    } else if(argv[i][1] == 'o') {
      config->osc_en = 1;
    } else if(argv[i][1] == 's') {
      i++;
      config->sensor_en = 1;
      config->start_sample = atoi(argv[i]);
      i++;
      config->n_samples = atoi(argv[i]) - config->start_sample;
    } else if(argv[i][1] == 'c') {
      i++;
      config->calib = atoi(argv[i]);
      if(config->calib > 1){
        printf("Unknown calibration mode : -c %d\n\n", config->calib);
        print_help();
        return EXIT_FAILURE;
      }
    } else if(argv[i][1] == 'i') {
      i++;
      memcpy(config->inst_file, argv[i], strlen(argv[i]));
      config->inst_file[strlen(argv[i])] = '\0';
    } else if(argv[i][1] == 'd') {
      i++;
      memcpy(config->dump_path, argv[i], strlen(argv[i]));
      config->dump_path[strlen(argv[i])] = '\0';
    } else {
      printf("Unknown argument: -%c\n\n", argv[i][1]);
      print_help();
      return EXIT_FAILURE;
    }
  }

  return EXIT_SUCCESS;

}

int init_config(config_t* config){

  if (config == NULL)
    return EXIT_FAILURE;
  
  config->n_traces     = 10; 
  config->osc_en       = 0; 
  config->calib        = 0; 
  config->sensor_en    = 0; 
  config->n_samples    = 1024; 
  config->start_sample = 0; 
  config->dump_path[0] = '.'; 
  config->dump_path[1] = '\0'; 
  config->inst_file[0] = '.';
  config->inst_file[1] = '\0';

  return EXIT_SUCCESS;

}

int print_config(config_t* config){

  if (config == NULL)
    return EXIT_FAILURE;
  
  printf("\nProgram configuration:\n");
  printf("\t- number of traces: %d\n", config->n_traces);
  printf("\t- osciloscope enabled: %d\n", config->osc_en);
  printf("\t- calibration mode: %d\n", config->calib);
  printf("\t- sensor enabled: %d\n", config->sensor_en);
  printf("\t- starting sensor sample: %d\n", config->start_sample);
  printf("\t- number of sensor samples: %d\n", config->n_samples);
  printf("\t- instruction file: %s\n\n", config->inst_file);
  printf("\t- output path: %s\n\n", config->dump_path);

  return EXIT_SUCCESS;

}

void initialize_random(unsigned char array[16]){

  for (int i = 0; i < 16; i++) {
        array[i] = rand() % 256;
  }

  return;

}

void sbox_key_pt(int trace, unsigned char pt[16], unsigned char key[16]){

  if(trace == 0){
    for(int i=0; i<16; i++){
      pt[i]  = 0;
      key[i] = 0;
    }
  } else {

    for(int i=0; i<16; i++){
      pt[i]++;
      pt[i] = pt[i]%256;
    }

    if(trace%256 == 0 && trace != 0){
      for(int i=0; i<16; i++){
        key[i]++;
        key[i] = key[i]%256;
      }
    }

  }

  return;  

}

unsigned char hamming_weight(unsigned char byte) {

  unsigned char weight = 0;

  for(int i=0; i<(8*sizeof(byte)); i++){
    weight += (byte&(1<<i))>>i;
  }

  return weight;

}

int get_line_number(char * file_name){

  FILE * instruction_f;
  instruction_f = fopen(file_name, "r");
  if (instruction_f == NULL) {
    printf("%s\n", file_name);
    printf("Error opening the instructions file!\n");
    return -1;
  }

  char ch;
  int line_no = 0;
	
  //while(!feof(instruction_f))
  //{
  //  ch = fgetc(instruction_f);
  //  if(ch == '\n')
  //  {
  //    line_no++;
  //  }
  //}
  for (ch = getc(instruction_f); ch != EOF; ch = getc(instruction_f))
        if (ch == '\n') // Increment count if this character is newline
            line_no = line_no + 1;

  fclose(instruction_f);

  return line_no;

}


int load_instructions(char * file_name, unsigned char *** instructions, int * line_num){

  printf("Opening instruction file: %s\n", file_name);

  int line_no = get_line_number(file_name);

  printf("Instruction file has %d lines.\n", line_no);

  (* instructions) = (unsigned char **)malloc(line_no*sizeof(unsigned char *));
  for(int i=0; i<line_no; i++)
    (* instructions)[i]=(unsigned char *)malloc(16*sizeof(unsigned char));

  FILE * instruction_f;
  instruction_f = fopen(file_name, "r");
  if (instruction_f == NULL) {
    printf("Error opening the instructions file!\n");
    return EXIT_FAILURE;
  }

  char line[300];
  int index = 0;
  char* token;

  for(int line_cnt=0; line_cnt<line_no; line_cnt++){
    fgets(line, sizeof(line), instruction_f);
    index = 0;
    token = strtok(line, " ");
    while (token !=NULL){
      (* instructions)[line_cnt][index] = (unsigned char)strtol(token, NULL, 16);
      index++;
      token = strtok(NULL, " ");
    }
  }

  (* line_num) = line_no;
  fclose(instruction_f);

  return EXIT_SUCCESS;

}

char *get_filename(char *filename) {

  char * bname = basename(filename);
  char *dot = strrchr(bname, '.');
  if(!dot || dot == bname) return "";
  int offset = dot - bname;
  bname[offset] = '\0';
  return bname;

}

void get_csv_line(metadata_line * metadata, FILE * metadata_f){

  fscanf(metadata_f, "%s", metadata->csv_line);

  char *ptr = strtok(metadata->csv_line, ",");
  char tmp_string[100];

  strcpy(metadata->inst_name, ptr);
  ptr = strtok(NULL, ",");

  strcpy(metadata->inst_info, ptr);
  ptr = strtok(NULL, ",");

  strcpy(tmp_string, ptr);
  metadata->template_id = atoi(tmp_string);
  ptr = strtok(NULL, ",");

  strcpy(tmp_string, ptr);
  metadata->asm_line = atoi(tmp_string);
  ptr = strtok(NULL, ",");

  strcpy(metadata->hex_val, ptr);
  ptr = strtok(NULL, ",");

  strcpy(tmp_string, ptr);
  metadata->start_sample = atoi(tmp_string);
  ptr = strtok(NULL, ",");

  strcpy(tmp_string, ptr);
  metadata->end_sample = atoi(tmp_string);
  ptr = strtok(NULL, ",");

  //printf("%s,%s,%d,%d,%s,%d,%d\n", metadata->inst_name, metadata->inst_info, metadata->template_id, metadata->asm_line, metadata->hex_val, metadata->start_sample, metadata->end_sample);

  return;

}

