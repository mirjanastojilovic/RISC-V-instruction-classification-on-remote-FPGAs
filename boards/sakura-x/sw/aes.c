/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "aes.h"

int encdec(FT_HANDLE sasebo, int data) {
  printf("Encryption mode set to %d\n", data);
  if(sasebo_write_unit(sasebo, ADDR_MODE, data) == EXIT_FAILURE) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

int set_key(FT_HANDLE sasebo, unsigned char* key) {
  if(key == NULL) {
    fprintf(stderr, "null key passed to set_key\n");
    return EXIT_FAILURE;
  }

  // write key to corresponding addr
  if(sasebo_write(sasebo, (char *)key, AES_SIZE, ADDR_KEY0) == EXIT_FAILURE) {
    return EXIT_FAILURE;
  }

  // execute key generation on HW
  if(sasebo_write_unit(sasebo, ADDR_CONT, 0x0002) == EXIT_FAILURE) {
    return EXIT_FAILURE;
  }

  //sleep(0.5); // probably useless

  //int ret;
  //while((ret = sasebo_read_unit(sasebo, ADDR_CONT)) != 0) { // wait for key computations to be done
  //  printf("nop.. %d\n", ret);
  //}
  if(sasebo_read_unit(sasebo, ADDR_CONT) == EXIT_FAILURE) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

int encrypt(FT_HANDLE sasebo, unsigned char* plaintext, unsigned char* cipher) {
  if(sasebo == NULL || plaintext == NULL || cipher == NULL) {
    fprintf(stderr, "null args to encrypt\n");
    return EXIT_FAILURE;
  }

  // write plaintext to cipher module
  if(sasebo_write(sasebo, (char *)plaintext, AES_SIZE, ADDR_ITEXT0) == EXIT_FAILURE) {
    return EXIT_FAILURE;
  }

  // cipher processing
  if(sasebo_write_unit(sasebo, ADDR_CONT, 0x0001) == EXIT_FAILURE) {
    return EXIT_FAILURE;
  }

  //int ret;
  //while((ret = sasebo_read_unit(sasebo, ADDR_CONT)) != 0) { // wait for key computations to be done
  //  printf("nop.. %d\n", ret);
  //}
  if(sasebo_read_unit(sasebo, ADDR_CONT) == EXIT_FAILURE) {
    return EXIT_FAILURE;
  }

  // read encrypted cyphertext
  if(sasebo_read(sasebo, (char *)cipher, AES_SIZE, ADDR_OTEXT0) == EXIT_FAILURE) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

void print_value(unsigned char* value, FILE* f) {

  // Print key
  printf("Key: ");
  for (int i=0;i<16;i++){
    fprintf(f, "%02x ",(unsigned char)value[i]);
  }
  fprintf(f, "\n");

}

FT_HANDLE* sasebo_reinit(FT_HANDLE* handle) {

  // Reset entire system
  sasebo_write_unit(*handle, ADDR_CONT, 0x0004);
  sasebo_write_unit(*handle, ADDR_CONT, 0x0000);

  // If read failed, close the handle
  sasebo_close(handle);

  // Open the device again
  if((handle = sasebo_init()) == NULL) {
    return NULL;
  }

  sasebo_write_unit(*handle, ADDR_CONT, 0x0004);
  sasebo_write_unit(*handle, ADDR_CONT, 0x0000);

  // Setup the device
  //if(select_comp(*handle) == EXIT_FAILURE) {
  //  sasebo_close(handle);
  //  return NULL;
  //}

  // Set encryption mode
  if(encdec(*handle, MODE_ENC) == EXIT_FAILURE) {
    sasebo_close(handle);
    return NULL;
  }

  // TEST
  //sleep(10);

  return handle;

}

int calibrate_sensor(FT_HANDLE * handle, int n_samples){

  unsigned char sensor_sample[16];
  unsigned char calibration_cmd[16] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03};
  unsigned char sensor_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe};
  unsigned char end_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  //correct calibration :
  //IDF                      IDC
  //fff000000000000000000000|fffff000
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xf0, 0x00};
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0xff, 0xff, 0xfc, 0x00};
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00};
  unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xf0, 0x00};
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00};

  //64-bit sensor callibration at 200 MHz
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xe0, 0x00};
  //16-bit sensor callibration at 200 MHz
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xf0, 0x00};


start: ;

  while(set_key(*handle, calibration_cmd) == EXIT_FAILURE) {
    printf("Calibration command failed!\n");
    if ((handle = sasebo_reinit(handle)) == NULL) {
      printf("Could not reinit device. EXIT\n");
      return EXIT_FAILURE;
    } 
  }

  printf("IDF&IDC = ");
  for(int i=0; i<16; i++){
    printf("%02x", idc_idf[i]);
  }
  printf("\n");

  while(set_key(*handle, idc_idf) == EXIT_FAILURE) {
    printf("Calibration failed!\n");
    if ((handle = sasebo_reinit(handle)) == NULL) {
      printf("Could not reinit device. EXIT\n");
      return EXIT_FAILURE;
    } 
  }
  
  printf("For IDC = \n\t"); 
  for(int i=12; i<16; i++){
    printf("%02x", idc_idf[i]);
  }
  printf("\nand IDF = \n\t"); 
  for(int i=0; i<12; i++){
    printf("%02x", idc_idf[i]);
  }
  printf("\nsome sensor samples are:\n"); 
  for(int sample = 0; sample < n_samples; sample++){

    memset(sensor_sample, 0x00, sizeof(sensor_sample));

    // Write command to read sensor sample
    if(encrypt(*handle, sensor_cmd, sensor_sample) == EXIT_FAILURE) {

      printf("Calibration sensor trace collection failed\n");

      // Reinint the device
      if((handle = sasebo_reinit(handle)) == NULL){
        printf("Could not reinit device. EXIT\n");
        return EXIT_FAILURE;
      }
      goto start;
    }
    for (int i=8;i<16;i++){
      printf("%02x",sensor_sample[i]);
    }
    printf("\n");
  }

  // Send command to end read
  if(encrypt(*handle, end_cmd, sensor_sample) == EXIT_FAILURE) {

    printf("End command failed\n");

    // Reinint the device
    if((handle = sasebo_reinit(handle)) == NULL){
      printf("Could not reinit device. EXIT\n");
      return EXIT_FAILURE;
    }
    goto start;

  }

  //printf("Is the sensor calibrated?\n");
  //char choice = getc(stdin);

  //if(choice == 'y'){
  //  return EXIT_SUCCESS;
  //} else {
  //  return EXIT_FAILURE;
  //}
  return EXIT_SUCCESS;

}

int calibrate_sensor_multiple(FT_HANDLE * handle, int n_samples, int n_sensors, unsigned char idc_idf[][16]){

  unsigned char sensor_sample[16];
  unsigned char calibration_cmd[16] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03};
  unsigned char sensor_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe};
  unsigned char end_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  //correct calibration :
  //IDF                      IDC
  //fff000000000000000000000|fffff000
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xf0, 0x00};
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0xff, 0xff, 0xfc, 0x00};
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00};
  //unsigned char idc_idf[16] = {0xff, 0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xf0, 0x00};

start: ;

  for(int sensor=0; sensor<n_sensors; sensor++){

    //printf("Start loop %d\n", sensor);
    //char choice = getc(stdin);
    //int ch;
    //while ( ((ch = getchar()) != '\n') && ch != EOF);

    while(set_key(*handle, calibration_cmd) == EXIT_FAILURE) {
      printf("Calibration command failed!\n");
      if ((handle = sasebo_reinit(handle)) == NULL) {
        printf("Could not reinit device. EXIT\n");
        return EXIT_FAILURE;
      } 
      goto start;
    }

    printf("Sensor %d IDF&IDC:\n", sensor);
    for(int i=0; i<16; i++){
      printf("%02x", idc_idf[sensor][i]);
    }
    printf("\n");

    while(set_key(*handle, idc_idf[sensor]) == EXIT_FAILURE) {
      printf("Calibration failed!\n");
      if ((handle = sasebo_reinit(handle)) == NULL) {
        printf("Could not reinit device. EXIT\n");
        return EXIT_FAILURE;
      } 
      goto start;
    }
    
    printf("For sensor %d IDC = \n\t", sensor); 
    for(int i=12; i<16; i++){
      printf("%02x", idc_idf[sensor][i]);
    }
    printf("\nand IDF = \n\t"); 
    for(int i=0; i<12; i++){
      printf("%02x", idc_idf[sensor][i]);
    }
    printf("\nsome sensor samples are:\n"); 
    for(int sample = 0; sample < n_samples; sample++){

      memset(sensor_sample, 0x00, sizeof(sensor_sample));

      // Write command to read sensor sample
      if(encrypt(*handle, sensor_cmd, sensor_sample) == EXIT_FAILURE) {

        printf("Calibration sensor trace collection failed\n");

        // Reinint the device
        if((handle = sasebo_reinit(handle)) == NULL){
          printf("Could not reinit device. EXIT\n");
          return EXIT_FAILURE;
        }
        goto start;
      }
      for (int i=6;i<16;i++){
        if(i%2==0){
          printf("%02x",sensor_sample[i]);
        } else {
          printf("%02x|",sensor_sample[i]);
        }
      }
      printf("\n");
    }

    // Send command to end read
    if(encrypt(*handle, end_cmd, sensor_sample) == EXIT_FAILURE) {

      printf("End command failed\n");

      // Reinint the device
      if((handle = sasebo_reinit(handle)) == NULL){
        printf("Could not reinit device. EXIT\n");
        return EXIT_FAILURE;
      }
      goto start;

    }

  }

  //printf("Are all the sensors calibrated?\n");
  //char choice = getc(stdin);

  //if(choice == 'y'){
  //  return EXIT_SUCCESS;
  //} else {
  //  return EXIT_FAILURE;
  //}
  return EXIT_SUCCESS;

}

int calibrate_sensor_interactive(FT_HANDLE * handle, int n_samples){

  unsigned char sensor_sample[16];
  unsigned char calibration_cmd[16] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03};
  unsigned char sensor_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe};
  unsigned char end_cmd[16] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  //correct calibration :
  //IDF                      IDC
  //fff000000000000000000000|fffff000
  unsigned char idc_idf[16] = {0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xf0, 0x00};

  char str[300];

start: ;

  while(set_key(*handle, calibration_cmd) == EXIT_FAILURE) {
    if ((handle = sasebo_reinit(handle)) == NULL) {
      printf("Could not reinit device. EXIT\n");
      return EXIT_FAILURE;
    } 
  }

  printf("IDF&IDC = ");
  for(int i=0; i<16; i++){
    printf("%02x", idc_idf[i]);
  }
  printf("\n");

  while(set_key(*handle, idc_idf) == EXIT_FAILURE) {
    if ((handle = sasebo_reinit(handle)) == NULL) {
      printf("Could not reinit device. EXIT\n");
      return EXIT_FAILURE;
    } 
  }
  
  printf("Transfering sensor trace...\n"); 
  for(int sample = 0; sample < n_samples; sample++){

    memset(sensor_sample, 0x00, sizeof(sensor_sample));

    // Write command to read sensor sample
    if(encrypt(*handle, sensor_cmd, sensor_sample) == EXIT_FAILURE) {

      printf("Calibration sensor trace collection failed\n");

      // Reinint the device
      if((handle = sasebo_reinit(handle)) == NULL){
        printf("Could not reinit device. EXIT\n");
        return EXIT_FAILURE;
      }
      goto start;
    }
  }
  printf("Sensor trace transfer done!\n"); 

  // Send command to end read
  if(encrypt(*handle, end_cmd, sensor_sample) == EXIT_FAILURE) {

    printf("End command failed\n");

    // Reinint the device
    if((handle = sasebo_reinit(handle)) == NULL){
      printf("Could not reinit device. EXIT\n");
      return EXIT_FAILURE;
    }
    goto start;

  }

  printf("Sensor sample:\n");
  for (int i=8;i<16;i++){
    printf("%02x",sensor_sample[i]);
  }
  printf("\n");

  printf("Is the sensor calibrated?\n");
  char choice = getc(stdin);

  if(choice == 'y'){
    return EXIT_SUCCESS;
  } else {
    int ch;
    while ( ((ch = getchar()) != '\n') && ch != EOF);
    printf("New IDF & IDC value?\n");
    fgets(str, 129, stdin);
    printf("Entered IDF&IDC = %s\n", str);
    memset(idc_idf, 0x00, sizeof(idc_idf));
    for(int i=0; i<128; i++){
      printf("str %d = %d\n", i, (-1*(48-str[127-i])));
      printf("IDF&IDC[%d] = %d\n", i/8, idc_idf[i/8]|((-1*(48-str[127-i]))*(0x01<<(i%8))));
      idc_idf[15 - i/8] = idc_idf[15 -i/8]|((-1*(48-str[127-i]))*(0x01<<(i%8)));
    }
    printf("New IDF&IDC = ");
    for(int i=0; i<16; i++){
      printf("%02x", idc_idf[i]);
    }
    printf("\n");
    goto start;
  }

}


