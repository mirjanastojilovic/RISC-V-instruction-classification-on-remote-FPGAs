#include "calib.hpp"

void wait_for_enter(const std::string &msg) {
    std::cout << msg << std::endl;
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
}
//wait_for_enter("\nPress ENTER to continue after setting up ILA trigger...\n");

void calibrate_sensors_from_file(xrt::ip kernel, xrt::bo buffer, uint32_t* hbuf, 
                               uint32_t **idc_idf, int N_SENSORS, int IDC_SIZE, int IDF_SIZE){

  int init_delay_size = IDC_SIZE+IDF_SIZE;

  for(int sensor = 0; sensor < N_SENSORS; sensor++){
    printf("!!!! CALIBRATING SENSOR %d\n", sensor);
    for(int chunk = 0; chunk < init_delay_size/32; chunk++){
      if(chunk == 0)
        printf("SEND IDC...\n");
      else
        printf("SEND IDF...\n");
      // idc_idf[0-X] is IDF but addr[0] is IDC so invert these two 
      printf("\tWriting data: %08x to address: %08x\n", idc_idf[sensor][init_delay_size/32-1-chunk], CALIB_REG_BASE_ADDR+4*chunk);
      kernel.write_register(CALIB_REG_BASE_ADDR+4*chunk, idc_idf[sensor][init_delay_size/32-1-chunk]);
    }
    // Calibrate sensor
    printf("\tWriting data: %08x to address: %08x\n", sensor, CALIB_TRG_ADDR);
    kernel.write_register(CALIB_TRG_ADDR, sensor);
  }

}

uint32_t * calibrate_sensor(xrt::ip kernel, xrt::bo buffer, uint32_t* hbuf, int sensor_id, int SENSOR_WIDTH, int N_SAMPLES, int IDC_SIZE, int IDF_SIZE){

  // Create an IDC and IDF value for each sensor
  int idc;
  int idf;
  int init_delay_size = IDC_SIZE+IDF_SIZE;

  // Create a variable to store the current sensor sample
  uint32_t trace_sample;

  // Create a binary IDC/IDF array for each sensor
  uint32_t * idc_idf;
  idc_idf = (uint32_t *) malloc((init_delay_size/32)*sizeof(uint32_t));
  for(int i=0; i<(init_delay_size)/32; i++){
    idc_idf[i] = 0;
  }

  // Initialize initial delays to 0
  idc = 0;
  idf = 0;

  bool calibrated = 0;
  uint32_t resp;
  int calibrated_samples;
  int manual_calib = 0;
  int * trace = (int *)malloc(N_SAMPLES*sizeof(int));

  // Start the calibration loop
  while (!calibrated){

    idc_idf = pack_idc_idf(idc_idf, idc, idf, IDC_SIZE, IDF_SIZE);

    // Write current initial delays to the sensors
    for(int chunk = 0; chunk < init_delay_size/32; chunk++){
      // idc_idf[0-X] is IDF but addr[0] is IDC so invert these two 
      //printf("\tWriting data: %08x to address: %08x\n", idc_idf[init_delay_size/32-1-chunk], CALIB_REG_BASE_ADDR+4*chunk);
      kernel.write_register(CALIB_REG_BASE_ADDR+4*chunk, idc_idf[init_delay_size/32-1-chunk]);
    }

    // Calibrate sensor
    //printf("\tWriting data: %08x to address: %08x\n", sensor_id, CALIB_TRG_ADDR);
    kernel.write_register(CALIB_TRG_ADDR, sensor_id);

    // Trigger the recording of the trace
    //printf("TRIGGER TRACE RECORDING!...\n");
    //printf("\tWriting data: %08x to address: %08x\n", 0x50000000, CALIB_TRACE_TRG_ADDR);
    kernel.write_register(CALIB_TRACE_TRG_ADDR, 0x50000000);

    // Wait until the trace is recorded and stored in DRAM
    do{
      resp = kernel.read_register(STATUS_REG_ADDR);
    } while ((resp&CALIB_DUMP_IDLE_MASK)!=CALIB_DUMP_IDLE_MASK); 

    // Read trace from DRAM
    buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

    // Check if there are calibrated samples
    calibrated_samples = 0;

    for(int sample=0; sample<N_SAMPLES; sample++){

      if(sensor_id%2) {
        trace[sample] = (0xffff0000 & hbuf[sample*16+int(sensor_id/2)])>>16;
      }else{
        trace[sample] = 0x0000ffff & hbuf[sample*16+int(sensor_id/2)];
      }

      if(check(trace[sample], 16)!=ALL_ZEROS){
        calibrated_samples++;
      }

    }

    if(calibrated_samples == 0 && manual_calib == 0){
      if(idf == IDC_SIZE+1){
        idf = 0;
        idc++;
      } else {
        idf++;
      }
    } else {
      manual_calib = 1;
      printf("Sensor might be calibrated!\n");
      printf("***************************\n");
      printf("IDC = %d\nIDF = %d\n", idc, idf);
      printf("IDC IDF array:\n");
      for(int i=0; i<(init_delay_size)/32; i++){
        printf("%08x", idc_idf[i]);
      }
      printf("\n");
      printf("***************************\n");
      printf("SENSOR TRACE:\n");

      for(int sample=0; sample<N_SAMPLES; sample++){
        printf("trace[%d]: %04x\n", sample, trace[sample]);
      }

      char reply;
      std::cout << "Is the sensor properly calibrated? (y/n)";
      std::cin >> reply;
      if(reply == 'y'){
        calibrated = 1;
      } else {
        if(idf == IDC_SIZE+1){
          idf = 0;
          idc++;
        } else {
          idf++;
        }
      }
    }

  }

  free(trace);
  return idc_idf;

}

void idc_idf_sweep(xrt::ip kernel, xrt::bo buffer, uint32_t* hbuf, int sensor_id, int SENSOR_WIDTH, int N_SAMPLES, int IDC_SIZE, int IDF_SIZE){

  // Create an IDC and IDF value for each sensor
  int init_delay_size = IDC_SIZE+IDF_SIZE;

  // Create a variable to store the current sensor sample
  uint32_t trace_sample;

  // Create a binary IDC/IDF array for each sensor
  uint32_t * idc_idf;
  idc_idf = (uint32_t *) malloc((init_delay_size/32)*sizeof(uint32_t));
  for(int i=0; i<(init_delay_size)/32; i++){
    idc_idf[i] = 0;
  }

  uint32_t resp;
  int calibrated_samples;
  int * trace = (int *)malloc(N_SAMPLES*sizeof(int));
  int * trace_hw = (int *)malloc(N_SAMPLES*sizeof(int));
  FILE * trace_f;
  FILE * trace_hw_f;
  char file_path[1000];

  // Open log file for delay line values
  sprintf(file_path, "idc_idf_sweep_sensor%d_raw.csv", sensor_id);
  trace_f = fopen(file_path, "w");
  if(trace_f == NULL){
    printf("CANNOT OPEN SWEEP LOG FILE!\n");
    return;
  }

  // Open log file for HW values
  sprintf(file_path, "idc_idf_sweep_sensor%d_HW.csv", sensor_id);
  trace_hw_f = fopen(file_path, "w");
  if(trace_hw_f == NULL){
    printf("CANNOT OPEN SWEEP LOG FILE!\n");
    return;
  }

  fprintf(trace_f, "idc,idf");
  fprintf(trace_hw_f, "idc,idf");
  for(int i = 0; i<N_SAMPLES; i++){
    fprintf(trace_f, ",s%d", i);
    fprintf(trace_hw_f, ",s%d", i);
  }
  fprintf(trace_f, "\n");
  fprintf(trace_hw_f, "\n");

  // Start the sweep
  for(int idc = 0; idc<=IDC_SIZE; idc++){
    for(int idf = 0; idf<=IDF_SIZE; idf++){

      idc_idf = pack_idc_idf(idc_idf, idc, idf, IDC_SIZE, IDF_SIZE);

      // Write current initial delays to the sensors
      for(int chunk = 0; chunk < init_delay_size/32; chunk++){
        // idc_idf[0-X] is IDF but addr[0] is IDC so invert these two 
        //printf("\tWriting data: %08x to address: %08x\n", idc_idf[init_delay_size/32-1-chunk], CALIB_REG_BASE_ADDR+4*chunk);
        kernel.write_register(CALIB_REG_BASE_ADDR+4*chunk, idc_idf[init_delay_size/32-1-chunk]);
      }

      // Calibrate sensor
      //printf("\tWriting data: %08x to address: %08x\n", sensor_id, CALIB_TRG_ADDR);
      kernel.write_register(CALIB_TRG_ADDR, sensor_id);

      // Trigger the recording of the trace
      //printf("TRIGGER TRACE RECORDING!...\n");
      //printf("\tWriting data: %08x to address: %08x\n", 0x50000000, CALIB_TRACE_TRG_ADDR);
      kernel.write_register(CALIB_TRACE_TRG_ADDR, 0x50000000);

      // Wait until the trace is recorded and stored in DRAM
      do{
        resp = kernel.read_register(STATUS_REG_ADDR);
      } while ((resp&CALIB_DUMP_IDLE_MASK)!=CALIB_DUMP_IDLE_MASK); 

      // Read trace from DRAM
      buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

      fprintf(trace_f, "%d,%d", idc, idf);
      fprintf(trace_hw_f, "%d,%d", idc, idf);

      for(int sample=0; sample<N_SAMPLES; sample++){
        if(sensor_id%2) {
          trace[sample] = (0xffff0000 & hbuf[sample*16+int(sensor_id/2)])>>16;
          trace_hw[sample] = hamming_weight((0xffff0000 & hbuf[sample*16+int(sensor_id/2)])>>16);
        }else{
          trace[sample] = 0x0000ffff & hbuf[sample*16+int(sensor_id/2)];
          trace_hw[sample] = hamming_weight(0x0000ffff & hbuf[sample*16+int(sensor_id/2)]);
        }
        fprintf(trace_f, ",%04x", trace[sample]);
        fprintf(trace_hw_f, ",%d", trace_hw[sample]);
      }
      fprintf(trace_f, "\n");
      fprintf(trace_hw_f, "\n");

    }
  }

  fclose(trace_f);
  fclose(trace_hw_f);

  free(trace);
  free(trace_hw);
  return;

}

int get_sample(uint32_t *hbuf, int SENSOR_WIDTH, int sample, int sensor) {

  int trace_sample;
  uint32_t mask;

  if(SENSOR_WIDTH < 32) {
    switch (SENSOR_WIDTH) {
      case 4:
        mask = 0x0000000f << 4*(sensor%8);
        trace_sample = hamming_weight((mask & hbuf[sample*16+int(sensor/8)])>>(4*(sensor%8)));
        break;
      case 8:
        mask = 0x000000ff << 8*(sensor%4);
        trace_sample = hamming_weight((mask & hbuf[sample*16+int(sensor/4)])>>(8*(sensor%4)));
        break;
      case 16:
        mask = 0x0000ffff << 16*(sensor%2);
        trace_sample = hamming_weight((mask & hbuf[sample*16+int(sensor/2)])>>(16*(sensor%2)));
        break;
    }
  } else if (SENSOR_WIDTH == 32) {
    trace_sample = hamming_weight(hbuf[sample*16+sensor]);
  } else {
    trace_sample = 0;
    for (int chunk = 0; chunk < int(SENSOR_WIDTH/32); chunk++) {
      trace_sample += hamming_weight(hbuf[sample*16+sensor*int(SENSOR_WIDTH/32)+chunk]);

    }
  }

  return trace_sample;

}

int get_min_sample(uint32_t *hbuf, int N_SAMPLES, int SENSOR_WIDTH, int sensor) {
    int min = SENSOR_WIDTH * 8;
    int current = 0;
    for (int j = 0; j < N_SAMPLES; ++j) {
        current = get_sample(hbuf, SENSOR_WIDTH, j, sensor);
        if (min > current) {
            min = current;
        }
    }
    return min;
}

int get_max_sample(uint32_t *hbuf, int N_SAMPLES, int SENSOR_WIDTH, int sensor) {
    int max = 0;
    int current = 0;

    for (int j = 0; j < N_SAMPLES; ++j) {
        current = get_sample(hbuf, SENSOR_WIDTH, j, sensor);
        if (max < current) {
            max = current;
        }
    }
    return max;
}

uint32_t * pack_idc_idf(uint32_t * idc_idf, int idc, int idf, int IDC_SIZE, int IDF_SIZE){

  // CHECK IF THIS IS OK IN ALL CASES!!!!!!!!!!!!
  for(int i=0; i<(IDC_SIZE+IDF_SIZE)/32; i++){
    idc_idf[i] = 0;
  }

  for(int i = 0; i<int(idf/32); i++){
    idc_idf[i]=0xffffffff;
  }
  idc_idf[int(idf/32)]=0;
  for(int i = 0; i<(idf%32); i++){
    idc_idf[int(idf/32)]=0x80000000|(idc_idf[int(idf/32)]>>1);
  }

  for(int i = IDF_SIZE/32; i < IDF_SIZE/32+int(idc/32); i++){
    idc_idf[i]=0xffffffff;
  }
  idc_idf[IDF_SIZE/32+int(idc/32)]=0;
  for(int i = 0; i<(idc%32); i++){
    idc_idf[IDF_SIZE/32+int(idc/32)]=0x80000000|(idc_idf[IDF_SIZE/32+int(idc/32)]>>1);
  }

  return idc_idf;

}

calib_state_t check(uint32_t trace_sample, int SENSOR_WIDTH){

  if(trace_sample == 0) {
    return ALL_ZEROS;
  } else if (hamming_weight(trace_sample) == SENSOR_WIDTH) {
    return ALL_ONES;
  } else if (hamming_weight(trace_sample) > 0 and hamming_weight(trace_sample) < SENSOR_WIDTH){
    if((trace_sample&0x1) == 0 && (trace_sample&0x8000) != 0) {
      return RISING_EDGE;
    } else if((trace_sample&0x1) == 1 && (trace_sample&0x8000) == 0) {
      return FALLING_EDGE;
    }
  }

  return ERROR;
}

unsigned char hamming_weight(uint32_t data) {

  unsigned char weight = 0;

  for(int i=0; i<(8*sizeof(data)); i++){
    weight += (data&(1<<i))>>i;
  }

  return weight;

}

uint32_t ** calibrate_rds(xrt::ip kernel, xrt::bo buffer, uint32_t *hbuf,
                       int N_SENSORS, int N_SAMPLES,
                       int IDC_SIZE, int IDF_SIZE,
                       int SENSOR_WIDTH) {
    uint32_t **idc_idf = (uint32_t **)malloc(N_SENSORS * sizeof(uint32_t *));
    for (int sensor = 0; sensor < N_SENSORS; sensor++) {
        idc_idf[sensor] =
            (uint32_t *)malloc((IDC_SIZE + IDF_SIZE) / 32 * sizeof(uint32_t));
    }
    for (int sensor = 0; sensor < N_SENSORS; sensor++){
      int idc = 0;
      printf("!!!!!!!!!!CALIBRATING SENSOR %d\n", sensor);
      for (idc; idc <= IDC_SIZE; idc++) {
          pack_idc_idf(idc_idf[sensor], idc, 0, IDC_SIZE, IDF_SIZE);

          // Calibrate sensors
          printf("************************************************\n");
          printf("CALIBRATE SENSORS...\n");

          calibrate_sensors_from_file(kernel, buffer, hbuf, idc_idf, N_SENSORS,
                                      IDC_SIZE, IDF_SIZE);

          bool max_hw_violated = false;
          for (int i = 0; i < 10; i++) {
              // Trigger the recording of the calibration traces
              printf("TRIGGER TRACE RECORDING!...\n");
              printf("\tWriting data: %08x to address: %08x\n", 0x50000000,
                     CALIB_TRACE_TRG_ADDR);
              kernel.write_register(CALIB_TRACE_TRG_ADDR, 0x50000000);

              // Wait until the trace is recorded and stored in DRAM
              uint32_t resp;
              do {
                  resp = kernel.read_register(STATUS_REG_ADDR);
              } while ((resp & CALIB_DUMP_IDLE_MASK) != CALIB_DUMP_IDLE_MASK);

              // Read trace from DRAM
              buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

              for (int sample = 0; sample < N_SAMPLES; sample++) {
                  // Print sample of a trace
                  printf("Sample %d:\n", sample);
                  printf("0x");
                  for (int offset = 15; offset >= 0; offset--) {
                      printf("%08x|", hbuf[sample * 16 + offset]);
                  }
                  printf("\n");
              }
              int min_sample = get_min_sample(hbuf, N_SAMPLES, SENSOR_WIDTH, sensor);

              if (min_sample != SENSOR_WIDTH) {
                  max_hw_violated = true;
                  break;
              }
          }
          if (!max_hw_violated) {
              break;
          }
      }

      int break_idc_loop = false;
      for (idc; idc <= IDC_SIZE; idc++) {
          for (int idf = 0; idf < IDF_SIZE; idf++) {
              pack_idc_idf(idc_idf[sensor], idc, idf, IDC_SIZE, IDF_SIZE);
              // Calibrate sensors
              printf("************************************************\n");
              printf("CALIBRATE SENSORS...\n");

              calibrate_sensors_from_file(kernel, buffer, hbuf, idc_idf,
                                          N_SENSORS, IDC_SIZE, IDF_SIZE);

              int violated = false;
              for (int i = 0; i < 10; i++) {
                  // Trigger the recording of the calibration traces
                  printf("TRIGGER TRACE RECORDING!...\n");
                  printf("\tWriting data: %08x to address: %08x\n", 0x50000000,
                         CALIB_TRACE_TRG_ADDR);
                  kernel.write_register(CALIB_TRACE_TRG_ADDR, 0x50000000);

                  // Wait until the trace is recorded and stored in DRAM
                  uint32_t resp;
                  do {
                      resp = kernel.read_register(STATUS_REG_ADDR);
                  } while ((resp & CALIB_DUMP_IDLE_MASK) != CALIB_DUMP_IDLE_MASK);

                  // Read trace from DRAM
                  buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

                  for (int sample = 0; sample < N_SAMPLES; sample++) {
                      // Print sample of a trace
                      printf("Sample %d:\n", sample);
                      printf("0x");
                      for (int offset = 15; offset >= 0; offset--) {
                          printf("%08x|", hbuf[sample * 16 + offset]);
                      }
                      printf("\n");
                  }

                  int min = get_min_sample(hbuf, N_SAMPLES, SENSOR_WIDTH, sensor);
                  int max = get_max_sample(hbuf, N_SAMPLES, SENSOR_WIDTH, sensor);
                  if (min < 32) {
                      violated = true;
                      break;
                  }
                  if (max == SENSOR_WIDTH) {
                      violated = true;
                      break;
                  }
              }
              if (!violated) {
                  break_idc_loop = true;
                  break;
              }
          }
      }
      if(break_idc_loop){
          break;
      }
    }

    return idc_idf;
}
