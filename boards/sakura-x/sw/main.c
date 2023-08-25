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
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>

#include "Sasebogii.h"
#include "oscilloscope.h"
#include "utils.h"
#include "aes.h"
#include "aes_soft.h"

#define N_SENSORS 5

int main(int argc, char* argv[])
{

  // Path to the template folder containing the metadata.csv file
  char TEMPLATE_PATH[] = "/media/SSD/paper_data/sakura/Exp-OUT1/random_templates/round_robin/10k/templates/";
  // Path to the output folder which will contain the traces
  char DUMP_PATH[] = "/media/SSD/paper_data/sakura/Exp-OUT1/random_templates/round_robin/10k/raw/";

  struct timeval st, et;

  srand(time(0));

  FILE * sensor_delay_line_f[N_SENSORS];
  FILE * sensor_encoded_hw_bin_f[N_SENSORS];
  FILE * sensor_encoded_hw_csv_f[N_SENSORS];
  FILE * opcodes_f;
  FILE * cpu_en_f;

  // To iterate over instruction directory
  struct dirent *dp;
  DIR *dfd;

  config_t config;

  unsigned char sensor_sample[16];
  unsigned char ** sensor_trace;
  unsigned char ** sensor_trace_hw;

  unsigned char calibration_cmd[16] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03};
  unsigned char rst_cmd[16] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07};
  unsigned char sensor_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe};
  unsigned char end_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  unsigned char offset_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xf0, 0x00, 0xfc};

  //Board in big box; Exp-IN
  //unsigned char idc_idf[5][16] = {{0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00},
  //                                {0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xe0, 0x00, 0x00},
  //                                {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xf0, 0x00, 0xff, 0xff, 0xfc, 0x00},
  //                                // couple of overflows in sensor 1
  //                                {0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00},
  //                                {0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00}};
  //Board in big box; Exp-OUT1
  unsigned char idc_idf[5][16] = {{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0xff, 0xff, 0xfe, 0x00},
                                  {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0x80, 0x00},
                                  {0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00},
                                  {0xff, 0xff, 0xff, 0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xfe, 0x00},
                                  {0xff, 0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00}};
  //Board in big box; Exp-OUT2
  //unsigned char idc_idf[5][16] = {{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0x00},
  //                                {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0x80, 0x00},
  //                                {0xff, 0xff, 0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00},
  //                                {0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xfe, 0x00},
  //                                {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00}};

  int osc = -1;
  char file_name[300];
  char inst_file_path_full[1000];
  char inst_file_name[1000];
  char sys_cmd[1000];
  int no_fails = 0;
  int status;

  // Load program config passed by the command line arguments
  init_config(&config);
  if(parse_args(argc, argv, &config) == EXIT_FAILURE)
    return 0;
  // Print the config structure
  if(print_config(&config) == EXIT_FAILURE)
    return 0;


  // Allocate arrays for sensor traces
  sensor_trace = (unsigned char **)malloc(config.n_samples*sizeof(unsigned char *));
  for(int i=0; i<config.n_samples; i++)
    sensor_trace[i]=(unsigned char *)malloc(16*sizeof(unsigned char));

  sensor_trace_hw = (unsigned char **)malloc(N_SENSORS*sizeof(unsigned char *));
  for(int sensor=0; sensor<N_SENSORS; sensor++)
    sensor_trace_hw[sensor] = (unsigned char *)malloc(config.n_samples*sizeof(unsigned char));
  
  // Initialize oscilloscope if oscilloscope is enabled
  if(config.osc_en == 1)
    osc = init_osc();

  // Open Sasebo Device
  FT_HANDLE* handle;
  if((handle = sasebo_init()) == NULL) {
    return EXIT_FAILURE;
  }

  // Initialize the device
  if(select_comp(*handle) == EXIT_FAILURE) {
    sasebo_close(handle);
    return EXIT_FAILURE;
  }

  // Set the AES core to encryption mode
  if(encdec(*handle, MODE_ENC) == EXIT_FAILURE) {
    sasebo_close(handle);
    return EXIT_FAILURE;
  }

  // Reset entire system
  sasebo_write_unit(*handle, ADDR_CONT, 0x0004);
  sasebo_write_unit(*handle, ADDR_CONT, 0x0000);

  // Calibrate sensor
  if(config.calib == 0){
    //calibrate_sensor(handle, 16);
    calibrate_sensor_multiple(handle, 16, 5, idc_idf);
  } else {
    while(set_key(*handle, calibration_cmd) == EXIT_FAILURE) {
      if ((handle = sasebo_reinit(handle)) == NULL) {
        printf("Could not reinit device. EXIT\n");
        return EXIT_FAILURE;
      } 
    }
  }

  int line_no;
  unsigned char ** instructions;

  // open file containing the paths to all instruction directories
  ssize_t read;
  size_t len = 0;
  char * inst_directory;
  char metadata_path[1000];

  // LOOP OVER ALL TEMPLATES IN METADATA FILE
  sprintf(metadata_path, "%s/metadata.csv", TEMPLATE_PATH);
  int file_size = get_line_number(metadata_path);

  FILE * metadata_f = fopen(metadata_path, "r");
  if(metadata_f == NULL){
    printf("CANNOT OPEN METADATA FILE!\n");
    return 0;
  }

  metadata_line metadata;

  for(int line=0; line<file_size; line++){

    get_csv_line(&metadata, metadata_f);
    
    if(line == 0)
      continue;

    config.start_sample = metadata.start_sample;
    config.n_samples = metadata.end_sample - metadata.start_sample;

    sprintf(inst_file_path_full, "%s/%s/%s_template_%d.txt", TEMPLATE_PATH, metadata.inst_name, metadata.inst_name, metadata.template_id);

    strcpy(inst_file_name, inst_file_path_full);
      
    char * inst_file_name_no_ext = get_filename(inst_file_name);

    printf("Recording traces for file: %s\n%s\n", inst_file_path_full, inst_file_name_no_ext);

    sprintf(sys_cmd, "mkdir %s/%s", DUMP_PATH, inst_file_name_no_ext);
    status = system(sys_cmd);

    // Open files for results
    for(int sensor=0; sensor<N_SENSORS; sensor++){
      sprintf(file_name, "%s/sensor%d_delay_line.csv", config.dump_path, sensor);
      sensor_delay_line_f[sensor] = fopen(file_name, "w");
      if(sensor_delay_line_f[sensor] == NULL){
        printf("Error openning the sensor delay line file!\n");
        return 0;
      }

      sprintf(file_name, "%s/sensor%d_encoded_hw.bin", config.dump_path, sensor);
      sensor_encoded_hw_bin_f[sensor] = fopen(file_name, "wb");
      if(sensor_encoded_hw_bin_f[sensor] == NULL){
        printf("Error openning the sensor encoded HW binary file!\n");
        return 0;
      }

      sprintf(file_name, "%s/sensor%d_encoded_hw.csv", config.dump_path, sensor);
      sensor_encoded_hw_csv_f[sensor] = fopen(file_name, "w");
      if(sensor_encoded_hw_csv_f[sensor] == NULL){
        printf("Error openning the sensor encoded HW csv file!\n");
        return 0;
      }
    }

    sprintf(file_name, "%s/opcodes.csv", config.dump_path);
    opcodes_f = fopen(file_name, "w");
    if(opcodes_f == NULL){
      printf("Error openning the opcodes file!\n");
      return 0;
    }

    sprintf(file_name, "%s/cpu_en.csv", config.dump_path);
    cpu_en_f = fopen(file_name, "w");
    if(cpu_en_f == NULL){
      printf("Error openning the cpu enable file!\n");
      return 0;
    }
    
    if(load_instructions(inst_file_path_full, &instructions, &line_no) == EXIT_FAILURE){
    //if(load_instructions(instruction_file_names[inst_files], &instructions, &line_no) == EXIT_FAILURE){
    //if(load_instructions(config.inst_file, &instructions, &line_no) == EXIT_FAILURE){
      printf("Unsucessful load of instructions!\n");
      sasebo_close(handle);
      return 0;
    }

    // Repeat the experiment n_traces times
    for(int trace=0; trace<config.n_traces; trace++) {
    
      printf("Trace : %d\n", trace);
      if(config.osc_en == 1){
        usleep(20000);
      }
      //gettimeofday(&st,NULL);
      
      // Reset CPU and FIFOs
      
      while(set_key(*handle, rst_cmd) == EXIT_FAILURE) {
        if ((handle = sasebo_reinit(handle)) == NULL) {
          printf("Could not reinit device. EXIT\n");
          return EXIT_FAILURE;
        } 
        trace--;
        goto loop_end;
      }

      // Send instructions

      printf("**** SENDING INSTRUCTIONS ****\n");

      for(int line=0; line<line_no; line++){
        printf("Sending 3 instructions:\n");
        for(int byte=0; byte<16; byte++){
          printf("%02x", instructions[line][byte]);
        }
        printf("\n");

        if (set_key(*handle, instructions[line]) == EXIT_FAILURE) {
          // If send fails, reconnect the board and do the whole loop iteration again
          printf("Sending instruction payload %d failed!\n", line);
          no_fails++;
          if ((handle = sasebo_reinit(handle)) == NULL) {
            printf("Could not reinit device. EXIT\n");
            return EXIT_FAILURE;
          }
          trace--;
          goto loop_end;
        }
      }

      if (config.sensor_en == 1) {
        // Wait for CPU exec to end before reading sensor values
        //usleep(500);
        //sleep(1);

        if(config.start_sample != 0){
          // Ofset sample counter
          
          // Convert the start sample to hexadecimal bytes and put them in the offset_cmd(19 downto 8)
          offset_cmd[14] = config.start_sample & 0xff;
          offset_cmd[13] = ((config.start_sample >> 8) & 0xff) | 0xf0;
    
          printf("Start sample cmd = ");
          for(int i=0; i<16; i++){
            printf("%02x", offset_cmd[i]);
          }
          printf("\n");
    
          if(encrypt(*handle, offset_cmd, sensor_sample) == EXIT_FAILURE) {
    
            printf("Sensor trace collection failed\n");
            no_fails++;
    
            // Reinint the device
            if((handle = sasebo_reinit(handle)) == NULL){
              printf("Could not reinit device. EXIT\n");
              return EXIT_FAILURE;
            }
            trace--;
            goto loop_end;
    
          }
        }

        // Collect sensor traces
        printf("Transfering sensor trace...\n"); 
        for(int sample = 0; sample < config.n_samples; sample++){

          memset(sensor_sample, 0x00, sizeof(sensor_sample));

          // Write command to read sensor sample
          if(encrypt(*handle, sensor_cmd, sensor_sample) == EXIT_FAILURE) {

            printf("Sensor trace collection failed\n");
            no_fails++;

            // Reinint the device
            if((handle = sasebo_reinit(handle)) == NULL){
              printf("Could not reinit device. EXIT\n");
              return EXIT_FAILURE;
            }
            trace--;
            goto loop_end;

          }

          // Save sensor sample
          memcpy(sensor_trace[sample], sensor_sample, sizeof(sensor_sample));
        }
        printf("Sensor trace transfer done!\n"); 

      }

      // Send command to end experiment
      if(encrypt(*handle, end_cmd, sensor_sample) == EXIT_FAILURE) {

        printf("End command failed\n");
        no_fails++;

        // Reinint the device
        if((handle = sasebo_reinit(handle)) == NULL){
          printf("Could not reinit device. EXIT\n");
          return EXIT_FAILURE;
        }
        trace--;
        goto loop_end;

      }

      // Save sensor traces to file (both delay line and encoded)
      for(int sample = 0; sample < config.n_samples; sample++){
        
        for(int sensor=0; sensor<N_SENSORS; sensor++){
          sensor_trace_hw[sensor][sample] = 0;
          fprintf(sensor_delay_line_f[sensor], "%02x",sensor_trace[sample][6+2*sensor]);
          fprintf(sensor_delay_line_f[sensor], "%02x",sensor_trace[sample][7+2*sensor]);
          sensor_trace_hw[sensor][sample] += hamming_weight(sensor_trace[sample][6+2*sensor]);
          sensor_trace_hw[sensor][sample] += hamming_weight(sensor_trace[sample][7+2*sensor]);
          fprintf(sensor_encoded_hw_csv_f[sensor], "%d",sensor_trace_hw[sensor][sample]);
          if(sample!=(config.n_samples-1)){
            fprintf(sensor_delay_line_f[sensor], ",");
            fprintf(sensor_encoded_hw_csv_f[sensor], ",");
          }
          else {
            fprintf(sensor_delay_line_f[sensor], "\n");
            fprintf(sensor_encoded_hw_csv_f[sensor], "\n");
          }
        }

      }

      for(int sensor=0; sensor<N_SENSORS; sensor++){
        fwrite(sensor_trace_hw[sensor], sizeof(sensor_trace_hw[sensor][0]), config.n_samples, sensor_encoded_hw_bin_f[sensor]);
      }

      // Save opcodes to file
      for(int sample = 0; sample < config.n_samples; sample++){
        for (int i=0;i<4;i++){
          fprintf(opcodes_f, "%02x", sensor_trace[sample][i]);
        }
        if(sample!=(config.n_samples-1))
          fprintf(opcodes_f, ",");
        else
          fprintf(opcodes_f, "\n");
      }

      // Save CPU en to file
      for(int sample = 0; sample < config.n_samples; sample++){
        fprintf(cpu_en_f, "%d", sensor_trace[sample][5]);
        if(sample!=(config.n_samples-1))
          fprintf(cpu_en_f, ",");
        else
          fprintf(cpu_en_f, "\n");
      }
     
      // Read data from oscilloscope if oscilloscope is enabled
      if(config.osc_en == 1){
        quick_save(osc, trace, SIMPLE_PRECISION, config.dump_path);
        //trigger_save(osc, trace, SIMPLE_PRECISION, config.dump_path);
      }

loop_end: ;
      //gettimeofday(&et,NULL);
      //printf("Loop exec time: %ld microseconds\n", ((et.tv_sec - st.tv_sec) * 1000000) + (et.tv_usec - st.tv_usec));
    
    }

    for(int sensor=0; sensor<N_SENSORS; sensor++){
      fclose(sensor_delay_line_f[sensor]);
      fclose(sensor_encoded_hw_bin_f[sensor]);
      fclose(sensor_encoded_hw_csv_f[sensor]);
    }
    fclose(opcodes_f);
    fclose(cpu_en_f);

    sprintf(sys_cmd, "mv %s/* %s/%s/", config.dump_path, DUMP_PATH, inst_file_name_no_ext);
    status = system(sys_cmd);
  }

  sasebo_close(handle);
  if(config.osc_en == 1)
    close(osc);

  printf("Number of fails encountered: %d\n", no_fails);

  sprintf(sys_cmd, "python3 telegram_bot2.py");
  status = system(sys_cmd);

  fclose(metadata_f);
  

  return 0;
}
