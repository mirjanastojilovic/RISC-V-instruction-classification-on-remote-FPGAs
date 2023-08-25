#include "host.hpp"
#include "calibrate/calib.hpp"
#include "utils.hpp"

//#define DEBUG 0

using namespace std;

// STILL LEFT TO DO: DUMP THE TRACES INTO ONE CSV CONTAINING: INSTRUCTION, INFO, TEMPLATE ID, SAMPLES

int main(int argc, char* argv[]) {

    // Parse the command line arguments
    if (argc != 14) {
        std::cerr << "usage: " << argv[0] << " XCLBIN N_SENSORS N_SAMPLES SENSOR_WIDTH IDC_SIZE IDF_SIZE N_TRACES TEMPERATURE BACKGROUND RAW CALIB_PATH INST_PATH OUT_PATH" << std::endl;
        printf("Error\n");
        std::exit(-1);
    }

    int N_SENSORS = atoi(argv[2]);
    int N_SAMPLES = atoi(argv[3]);
    int SENSOR_WIDTH = atoi(argv[4]);
    int IDC_SIZE = atoi(argv[5]);
    int IDF_SIZE = atoi(argv[6]);
    int N_TRACES = atoi(argv[7]);
    int TEMPERATURE = atoi(argv[8]);
    int BACKGROUND = atoi(argv[9]);
    int RAW = atoi(argv[10]);
    char * CALIB_PATH = argv[11];
    char * INST_PATH = argv[12];
    char * OUT_PATH = argv[13];

    char file_path[10000];

    // Create the device
    auto dev = xrt::device(0);

    // Load dummy verification bistream and program the FPGA with it, to force the the subsequent programming of the real bitstream
    auto xclbin = dev.load_xclbin("../../bitstreams/verify.xclbin");

    // load the binary into the memory
    xclbin = dev.load_xclbin(argv[1]);

    //wait_for_enter("\nPress ENTER to continue after setting up ILA trigger...\n");

    auto kernel = xrt::ip(dev, xclbin, "PicoRV32_SCA_kernel");

    // args: device, size in bytes, dram bank
    auto buffer = xrt::bo(dev, N_SAMPLES*64, 1);
    // buffers are also little-endian
    uint32_t* hbuf = buffer.map<uint32_t*>();

    int resp;
    uint32_t payload;
    int code_size;
    uint32_t * code;

    // Reset system
    printf("************************************************\n");
    printf("RESET SYSTEM...\n");
    printf("\tWriting data: %08x to address: %08x\n", RST_ADDR, 0x00);
    kernel.write_register(RST_ADDR, 0x00);

    // Set DRAM pointer
    printf("************************************************\n");
    printf("SET DRAM DUMP POINTER...\n");
    payload = buffer.address();
    printf("\tWriting data: %08x to address: %08x\n", payload, DUMP_PTR_BASE_ADDR);
    kernel.write_register(DUMP_PTR_BASE_ADDR, payload);
    payload = buffer.address() >> 32;
    printf("\tWriting data: %08x to address: %08x\n", payload, DUMP_PTR_BASE_ADDR+4);
    kernel.write_register(DUMP_PTR_BASE_ADDR+4, payload);

    // Load calibration data from file
    sprintf(file_path, "%s", CALIB_PATH);
    FILE * idc_idf_file;
    idc_idf_file = fopen(file_path, "rb");
    if(idc_idf_file == NULL) {
      printf("ERROR IN OPENING IDC IDF BIN FILE\n");
      printf("%s\n", file_path);
      return 0;
    }

    uint32_t ** idc_idf = (uint32_t **)malloc(N_SENSORS*sizeof(uint32_t *));
    for(int sensor = 0; sensor<N_SENSORS; sensor++){
      idc_idf[sensor] = (uint32_t *)malloc((IDC_SIZE+IDF_SIZE)/32*sizeof(uint32_t));
      fread(idc_idf[sensor], sizeof(uint32_t), (IDC_SIZE+IDF_SIZE)/32, idc_idf_file);
    }

    // Calibrate sensors
    printf("************************************************\n");
    printf("CALIBRATE SENSORS...\n");
    calibrate_sensors_from_file(kernel, buffer, hbuf, idc_idf, N_SENSORS, IDC_SIZE, IDF_SIZE); 

    // Trigger the recording of the calibration traces
    printf("TRIGGER TRACE RECORDING!...\n");
    printf("\tWriting data: %08x to address: %08x\n", 0x50000000, CALIB_TRACE_TRG_ADDR);
    kernel.write_register(CALIB_TRACE_TRG_ADDR, 0x50000000);

    // Wait until the trace is recorded and stored in DRAM
    do{
      resp = kernel.read_register(STATUS_REG_ADDR);
    } while ((resp&CALIB_DUMP_IDLE_MASK)!=CALIB_DUMP_IDLE_MASK); 

    // Read trace from DRAM
    buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

    for(int sample=0; sample<N_SAMPLES; sample++){
      //Print sample of a trace
      printf("Sample %d:\n", sample);
      printf("0x");
      for(int offset=15; offset>=0; offset--){
        printf("%08x|", hbuf[sample*16+offset]);
      }
      printf("\n");
    }

    // Record traces for all templates

    char sys_cmd[1000];
    int status;
    FILE * dataset_averaged_f;
    FILE * background_averaged_f;
    double ** background_averaged;
    //FILE * dataset_raw_f;
    FILE * opcodes_f;
    FILE * temperature_f;
    FILE * metadata_f;
    char previous_instruction[10] = "\0";
    ssize_t read;
    char * line = NULL;
    size_t len = 0;
    uint32_t trace_sample;
    char taken[10] = "-";
    inst_info * info = (inst_info *)malloc(sizeof(inst_info));

    #ifdef DEBUG
      int LALA =0;
    #endif

    // Open the final output file
    sprintf(file_path, "%s/dataset_averaged.csv", OUT_PATH);
    dataset_averaged_f = fopen(file_path, "w");
    if(dataset_averaged_f == NULL) {
      printf("ERROR IN OPENING DATASET AVERAGED FILE\n");
      printf("%s\n", file_path);
      return 0;
    }
    fprintf(dataset_averaged_f, "inst,info,template_id");
    //fprintf(dataset_averaged_f, "inst,info,template_id,opcode,");
    for(int i=0; i<N_SENSORS; i++){
      for(int j=0; j<N_SAMPLES; j++){
        fprintf(dataset_averaged_f, ",sensor_%d_sample_%d", i, j);
      }
    }
    fprintf(dataset_averaged_f, "\n");

      // Open the output (no averaging) file
      sprintf(file_path, "%s/dataset_raw.gz", OUT_PATH);
      ofstream file(file_path, ios_base::out | ios_base::binary);
      boost::iostreams::filtering_streambuf<boost::iostreams::output> outbuf;
      outbuf.push(boost::iostreams::gzip_compressor());
      outbuf.push(file);
      ostream dataset_raw_f(&outbuf);

    if(RAW==1) {

      dataset_raw_f << "inst,info,template_id";
      //dataset_raw_f << "inst,info,template_id,opcode,");
      for(int i=0; i<N_SENSORS; i++){
        for(int j=0; j<N_SAMPLES; j++){
          dataset_raw_f << ",sensor_" << i << "_sample_" << j;
        }
      }
      dataset_raw_f << "\n";

    }

    // Open the opcodes file
    sprintf(file_path, "%s/opcodes.csv", OUT_PATH);
    opcodes_f = fopen(file_path, "w");
    if(opcodes_f == NULL) {
      printf("ERROR IN OPENING OPCODES FILE\n");
      printf("%s\n", file_path);
      return 0;
    }
    fprintf(opcodes_f, "inst,info,template_id");
    //fprintf(opcodes_f, "inst,info,template_id,opcode,");
    for(int i=0; i<N_SAMPLES; i++){
      fprintf(opcodes_f, ",sample_%d", i);
    }
    fprintf(opcodes_f, "\n");

    if(TEMPERATURE==1) {
      // Open the temperature file
      sprintf(file_path, "%s/temperature.csv", OUT_PATH);
      temperature_f = fopen(file_path, "w");
      if(temperature_f == NULL) {
        printf("ERROR IN OPENING TEMPERATURE FILE\n");
        printf("%s\n", file_path);
        return 0;
      }
      fprintf(temperature_f, "inst,info,template_id,date,PCB_top_front,PCB_top_rear,PCB_bottom_front,FPGA,Int_VCC\n");
    }

    if(BACKGROUND==1) {
      // Open the background file
      sprintf(file_path, "%s/background_averaged.csv", OUT_PATH);
      background_averaged_f = fopen(file_path, "w");
      if(background_averaged_f == NULL) {
        printf("ERROR IN OPENING DATASET AVERAGED FILE\n");
        printf("%s\n", file_path);
        return 0;
      }
      fprintf(background_averaged_f, "inst,info,template_id");
      //fprintf(background_averaged_f, "inst,info,template_id,opcode,");
      for(int i=0; i<N_SENSORS; i++){
        for(int j=0; j<N_SAMPLES; j++){
          fprintf(background_averaged_f, ",sensor_%d_sample_%d", i, j);
        }
      }
      fprintf(background_averaged_f, "\n");

      // Allocate the trace array
      background_averaged = (double **)malloc(N_SENSORS*sizeof(double *));
      for(int i=0; i<N_SENSORS; i++)
        background_averaged[i] = (double *)malloc(N_SAMPLES*sizeof(double));

    }

    // Allocate the trace array
    double ** trace_averaged;
    trace_averaged = (double **)malloc(N_SENSORS*sizeof(double *));
    for(int i=0; i<N_SENSORS; i++)
      trace_averaged[i] = (double *)malloc(N_SAMPLES*sizeof(double));

    uint32_t ** trace_raw;
    trace_raw = (uint32_t **)malloc(N_SENSORS*sizeof(uint32_t *));
    for(int i=0; i<N_SENSORS; i++)
      trace_raw[i] = (uint32_t *)malloc(N_SAMPLES*sizeof(uint32_t));

    // Go over all templates
    // Open metadata file (containing all templates in the order to record)
    sprintf(file_path, "%s/metadata.csv", INST_PATH);
    int file_size = get_line_number(file_path);

    metadata_f = fopen(file_path, "r");
    if(metadata_f == NULL){
      printf("CANNOT OPEN METADATA FILE!\n");
      return 0;
    }

    // Create metadata structure
    metadata_line metadata;

    // Go over all the templates in the metadata file
    for(int line=0; line<file_size; line++){

      // Load a line from the metadata csv
      get_csv_line(&metadata, metadata_f);

      // Ignore the first line because it's the csv header
      if(line == 0)
        continue;

      // Get info on each template: instruction, template id, opcode
      // get_instruction_info(info, line);
      get_instruction_info_from_metadata(info, &metadata);

      // Load code of the template
      // If it's a branch take care of the not_taken/taken directory structure
      //if(info->instruction[0] == 'b'){
      //  sprintf(file_path, "%s/%s/%s/%s.txt", INST_PATH, info->instruction, info->info, info->template_name);
      //}
      //else{
        sprintf(file_path, "%s/%s/%s", INST_PATH, info->instruction, info->template_name); 
      //}

      if(load_instructions(file_path, &code, &code_size) == EXIT_FAILURE){
        printf("Unsucessful load of instructions!\n");
        return 0;
      }

      #ifdef DEBUG
        if(strcmp(previous_instruction, info->instruction) != 0){
          LALA = 0;
          strcpy(previous_instruction, info->instruction);
        } else {
          if(LALA > 5)
            continue;
          LALA++;
        }
      #endif

      // Initialize dram region with the template code
      for(int i=0; i<code_size; i++){
        hbuf[i] = code[i]; 
      }
      buffer.sync(XCL_BO_SYNC_BO_TO_DEVICE);

      // Set code length
      printf("************************************************\n");
      printf("SET CODE LENGTH...\n");
      payload = code_size; 
      printf("\tWriting data: %08x to address: %08x\n", payload, CODE_LEN_ADDR);
      kernel.write_register(CODE_LEN_ADDR, payload);

      // Load code to FPGA
      printf("************************************************\n");
      printf("LOAD CODE TO FPGA...\n");
      printf("\tWriting data: %08x to address: %08x\n", 0x00, LOAD_CODE_TRG_ADDR);
      kernel.write_register(LOAD_CODE_TRG_ADDR, 0x00);

      // Wait until the code is dumped
      do{
        resp = kernel.read_register(STATUS_REG_ADDR);
      } while ((resp&CODE_DUMP_IDLE_MASK)!=CODE_DUMP_IDLE_MASK); 

      for(int trace=0; trace<N_TRACES+1; trace++){

        // Record background trace
        if(BACKGROUND==1){
          // Trigger the recording of the calibration traces
          printf("TRIGGER TRACE RECORDING!...\n");
          printf("\tWriting data: %08x to address: %08x\n", 0x50000000, CALIB_TRACE_TRG_ADDR);
          kernel.write_register(CALIB_TRACE_TRG_ADDR, 0x50000000);

          // Wait until the trace is recorded and stored in DRAM
          do{
            resp = kernel.read_register(STATUS_REG_ADDR);
          } while ((resp&CALIB_DUMP_IDLE_MASK)!=CALIB_DUMP_IDLE_MASK); 

          // Read trace from DRAM
          buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

          for(int sample=0; sample<N_SAMPLES; sample++){

            for(int sensor=0; sensor<N_SENSORS; sensor++){
              trace_sample = get_sample(hbuf, SENSOR_WIDTH, sample, sensor);
              //if(sensor%2) {
              //  trace_sample = hamming_weight((0xffff0000 & hbuf[sample*16+int(sensor/2)])>>16);
              //}else{
              //  trace_sample = hamming_weight(0x0000ffff & hbuf[sample*16+int(sensor/2)]);
              //}

              if(trace == 0){
                // Ignore the first trace
                background_averaged[sensor][sample] = 0;//trace_sample;
              } else if(trace == N_TRACES){
                // Divide after the next N_TRACES are recorded 
                background_averaged[sensor][sample] += trace_sample; 
                background_averaged[sensor][sample] /= N_TRACES; 
              } else {
                background_averaged[sensor][sample] += trace_sample; 
              }
            }
          }
        }

        // Reset system
        printf("************************************************\n");
        printf("RESET CPU...\n");
        printf("\tWriting data: %08x to address: %08x\n", RST_ADDR, 0x00);
        kernel.write_register(RST_ADDR, 0x00);

        // Start CPU execution
        printf("************************************************\n");
        printf("START CPU EXECUTION...\n");
        printf("\tWriting data: %08x to address: %08x\n", 0x00, START_EXEC_ADDR);
        kernel.write_register(START_EXEC_ADDR, 0x00);
  
        // Wait until the trace is recorded
        do{
          resp = kernel.read_register(STATUS_REG_ADDR);
        } while ((resp&TRACE_DUMP_IDLE_MASK)!=TRACE_DONE_IDLE_MASK); 

        // Read trace from DRAM
        buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

        for(int sample=0; sample<N_SAMPLES; sample++){
          // Print sample of a trace
          //printf("Sample %d:\n", sample);
          //printf("0x");
          //for(int offset=15; offset>=0; offset--){
          //  printf("%08x|", hbuf[sample*16+offset]);
          //}
          //printf("\n");

          for(int sensor=0; sensor<N_SENSORS; sensor++){
            trace_sample = get_sample(hbuf, SENSOR_WIDTH, sample, sensor);
            //if(sensor%2) {
            //  trace_sample = hamming_weight((0xffff0000 & hbuf[sample*16+int(sensor/2)])>>16);
            //}else{
            //  trace_sample = hamming_weight(0x0000ffff & hbuf[sample*16+int(sensor/2)]);
            //}

            trace_raw[sensor][sample] = trace_sample; 
            if(trace == 0){
              // Ignore the first trace
              trace_averaged[sensor][sample] = 0;//trace_sample;
            } else if(trace == N_TRACES){
              // Divide after the next N_TRACES are recorded 
              trace_averaged[sensor][sample] += trace_sample; 
              trace_averaged[sensor][sample] /= N_TRACES; 
            } else {
              trace_averaged[sensor][sample] += trace_sample; 
            }
          }
        }

        if(RAW==1 && trace!=0) {
          // Write raw trace to raw dataset file
          dataset_raw_f << info->instruction << "," << info->info << "," << info->template_id;
          for(int sensor=0; sensor<N_SENSORS; sensor++){
            for(int sample=0; sample<N_SAMPLES; sample++){
              dataset_raw_f << "," << trace_raw[sensor][sample];
            }
          }
          dataset_raw_f << "\n";
        }

      }

      // Save opcodes
      fprintf(opcodes_f, "%s,%s,%d", info->instruction, info->info, info->template_id);
      for(int sample=0; sample<N_SAMPLES; sample++){
        uint64_t inst_data;
        if(float(int((N_SENSORS*SENSOR_WIDTH)/32)) == (N_SENSORS*SENSOR_WIDTH)/float(32)) {
          inst_data = (uint64_t(hbuf[sample*16+int((N_SENSORS*SENSOR_WIDTH)/32)+1]) << 32)|uint64_t(hbuf[sample*16+int((N_SENSORS*SENSOR_WIDTH)/32)]);
          fprintf(opcodes_f, ",%08x|%08x", uint32_t(inst_data & 0xf), uint32_t(inst_data >> 4));
        } else {
          inst_data = ((uint64_t(hbuf[sample*16+int((N_SENSORS*SENSOR_WIDTH)/32)+1]) << 32)>>SENSOR_WIDTH)|(uint64_t(hbuf[sample*16+int((N_SENSORS*SENSOR_WIDTH)/32)])>>SENSOR_WIDTH);
          fprintf(opcodes_f, ",%08x|%08x", uint32_t(inst_data & 0xf), uint32_t(inst_data >> 4));
        }
      }
      fprintf(opcodes_f, "\n");

      if(TEMPERATURE==1) {
        // Save temperature
        save_temperature(temperature_f, info->instruction, info->info, info->template_id);
      }

      // Write averaged trace to dataset file
      fprintf(dataset_averaged_f, "%s,%s,%d", info->instruction, info->info, info->template_id);
      for(int sensor=0; sensor<N_SENSORS; sensor++){
        for(int sample=0; sample<N_SAMPLES; sample++){
          fprintf(dataset_averaged_f, ",%lf", trace_averaged[sensor][sample]);
        }
      }
      fprintf(dataset_averaged_f, "\n");

      if(BACKGROUND==1) {
        // Write averaged background traces to dataset file
        fprintf(background_averaged_f, "%s,%s,%d", info->instruction, info->info, info->template_id);
        for(int sensor=0; sensor<N_SENSORS; sensor++){
          for(int sample=0; sample<N_SAMPLES; sample++){
            fprintf(background_averaged_f, ",%lf", background_averaged[sensor][sample]);
          }
        }
        fprintf(background_averaged_f, "\n");
      }

    }


    fclose(dataset_averaged_f);
    if(BACKGROUND==1)
      fclose(background_averaged_f);
    //fclose(dataset_raw_f);
    boost::iostreams::close(outbuf);
    file.close();
    fclose(opcodes_f);
    if(TEMPERATURE==1)
      fclose(temperature_f);
    fclose(metadata_f);

    return 0;

}
