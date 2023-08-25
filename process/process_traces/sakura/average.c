/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

/*

This example presents how to communicate through FTD2xx to Sakura board, when this one is implementing AES
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <libgen.h>
#include <dirent.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>

//#define N_SENSORS 5
//#define N_SENSOR_TRACES 100
//#define N_SENSOR_SAMPLES 60
//#define AVG_SIZE 90

int main(int argc, char* argv[])
{

  FILE * sensor_f;
  FILE * opcodes_f;
  FILE * inst_directories;
  FILE * dataset_file;
  
  char * inst_directory;
  char * line = NULL;
  char file_name[1000];
  char sensor_path[1000];
  char opcode_line[10000];
  size_t len = 0;
  ssize_t read;

  if(argc != 6){
    printf("Usage:\n./average n_sensors n_sensor_traces n_sensor_samples average_size input_path\n");
    printf("Preferred values: n_sensors = 5, n_sensor_traces = 100, n_sensor_samples = 60, average_size = 100, input_path = ./\n");
    return 0;
  }

  int N_SENSORS = atoi(argv[1]);
  int N_SENSOR_TRACES = atoi(argv[2]);
  int N_SENSOR_SAMPLES = atoi(argv[3]);
  int AVG_SIZE = atoi(argv[4]);
  char * path = argv[5];  

  sprintf(file_name, "%s/file_paths.txt", path);
  inst_directories = fopen(file_name, "r");
  if(inst_directories == NULL){
    printf("CANNOT OPEN INSTRUCTION DIRECTORIES FILE!\n");
    return 0;
  }

  sprintf(file_name, "%s/dataset_avg_%d.csv", path, AVG_SIZE);
  dataset_file = fopen(file_name, "w");
  if(dataset_file == NULL){
    printf("Error in opening united files!\n");
    return 0;
  }

  uint8_t ** sensor_trace;
  sensor_trace = (uint8_t **)malloc(N_SENSOR_TRACES*sizeof(uint8_t *));
  for(uint8_t i=0; i<N_SENSOR_TRACES; i++)
    sensor_trace[i]=(uint8_t *)malloc(N_SENSOR_SAMPLES*sizeof(uint8_t));

  double * average_trace = (double *)malloc(N_SENSOR_SAMPLES*sizeof(double));

  // Print header to csv
  fprintf(dataset_file, "instruction,opcode");
  for(int sensor=0; sensor<N_SENSORS; sensor++){
    for(int sample=0; sample<N_SENSOR_SAMPLES; sample++){
      fprintf(dataset_file, ",s%d_%d", sensor, sample);
    }
  }
  fprintf(dataset_file, "\n");

  //int lala = 0;
  // LOOP OVER INSTRUCTIONS
  while((read = getline(&line, &len, inst_directories)) != -1){
    //if(lala>10)
    //  break;
    //lala++;

    // Get folder path
    inst_directory = line;
    inst_directory[read-1]='\0';

    // Extract instruction name
    char * instruction_dir_name = basename(inst_directory);
    char * separator = strchr(instruction_dir_name, '_');
    int position = separator - instruction_dir_name;
    char* instruction = (char*) malloc((position + 1) * sizeof(char));
    memcpy(instruction, instruction_dir_name, position);
    instruction[position] = '\0';

    // Add instruction id to csv line
    fprintf(dataset_file, "%s", instruction);

    // Load opcode to csv line
    sprintf(file_name, "%s/%s/opcodes.csv", path, inst_directory);
    opcodes_f = fopen(file_name, "r");
    if(opcodes_f == NULL){
      printf("Error in opening\n%s\n", file_name);
      return 0;
    }
    fscanf(opcodes_f, "%[^\n]", opcode_line);
    opcode_line[44]='\0';
    fprintf(dataset_file, ",%s", opcode_line+36);
    fclose(opcodes_f);
    

    // Load sensor traces
    for(int sensor = 0; sensor < N_SENSORS; sensor++){

      // Open sensor file
      sprintf(sensor_path, "%s/%s/sensor%d_encoded_hw.bin", path, inst_directory, sensor);
      sensor_f = fopen(sensor_path, "rb");
      if(sensor_f == NULL){
        printf("Error in opening\n%s\n", sensor_path);
        return 0;
      }

      // Load enough traces needed for averaging
      for(int i=0; i<AVG_SIZE; i++)
        fread(sensor_trace[i], sizeof(sensor_trace[0][0]), N_SENSOR_SAMPLES, sensor_f);
      fclose(sensor_f);

      // Average the specified number of traces
      for(int sample=0; sample < N_SENSOR_SAMPLES; sample++)
        average_trace[sample] = 0;
      for(int i=0; i<AVG_SIZE; i++){
        for(int sample=0; sample < N_SENSOR_SAMPLES; sample++){
          average_trace[sample] += sensor_trace[i][sample];
        }
      }
      for(int sample=0; sample < N_SENSOR_SAMPLES; sample++){
        average_trace[sample] /= AVG_SIZE;
        fprintf(dataset_file, ",%lf", average_trace[sample]);
      }
    }

    fprintf(dataset_file, "\n");
    free(instruction);

  }

  free(average_trace);
  for(int i=0; i<N_SENSOR_TRACES; i++)
    free(sensor_trace[i]);
  free(sensor_trace);
  
  fclose(dataset_file);
  fclose(inst_directories);

  return 0;
}
