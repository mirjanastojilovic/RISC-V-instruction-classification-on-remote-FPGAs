#include "host.hpp"
#include "calibrate/calib.hpp"
#include "utils.hpp"

//#define DEBUG 0

// STILL LEFT TO DO: DUMP THE TRACES INTO ONE CSV CONTAINING: INSTRUCTION, INFO, TEMPLATE ID, SAMPLES

int main(int argc, char* argv[]) {

    // Parse the command line arguments
    if (argc != 11) {
        std::cerr << "usage: " << argv[0] << " XCLBIN N_SENSORS N_SAMPLES SENSOR_WIDTH IDC_SIZE IDF_SIZE N_TRACES CALIB_PATH INST_PATH OUT_PATH" << std::endl;
        printf("Error\n");
        std::exit(-1);
    }

    int N_SENSORS = atoi(argv[2]);
    int N_SAMPLES = atoi(argv[3]);
    int SENSOR_WIDTH = atoi(argv[4]);
    int IDC_SIZE = atoi(argv[5]);
    int IDF_SIZE = atoi(argv[6]);
    int N_TRACES = atoi(argv[7]);
    char * CALIB_PATH = argv[8];
    char * INST_PATH = argv[9];
    char * OUT_PATH = argv[10];

    char file_path[10000];

    // Create the device
    auto dev = xrt::device(0);

    // Load dummy verification bistream and program the FPGA with it, to force the the subsequent programming of the real bitstream
    //auto xclbin = dev.load_xclbin("../../bitstreams/verify.xclbin");

    // load the binary into the memory
    auto xclbin = dev.load_xclbin(argv[1]);

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
    sprintf(file_path, "%s/idc_idf_v1.bin", CALIB_PATH);
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
    FILE * template_list;
    FILE * dataset_averaged_f;
    FILE * dataset_raw_f;
    FILE * opcodes_f;
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
    sprintf(file_path, "%s/dataset_raw.csv", OUT_PATH);
    dataset_raw_f = fopen(file_path, "w");
    if(dataset_raw_f == NULL) {
      printf("ERROR IN OPENING DATASET NOT AVERAGED FILE\n");
      printf("%s\n", file_path);
      return 0;
    }
    fprintf(dataset_raw_f, "inst,info,template_id");
    //fprintf(dataset_raw_f, "inst,info,template_id,opcode,");
    for(int i=0; i<N_SENSORS; i++){
      for(int j=0; j<N_SAMPLES; j++){
        fprintf(dataset_raw_f, ",sensor_%d_sample_%d", i, j);
      }
    }
    fprintf(dataset_raw_f, "\n");

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

    // Allocate the trace array
    double ** trace_averaged;
    trace_averaged = (double **)malloc(N_SENSORS*sizeof(double *));
    for(int i=0; i<N_SENSORS; i++)
      trace_averaged[i] = (double *)malloc(N_SAMPLES*sizeof(double));

    uint32_t ** trace_raw;
    trace_raw = (uint32_t **)malloc(N_SENSORS*sizeof(uint32_t *));
    for(int i=0; i<N_SENSORS; i++)
      trace_raw[i] = (uint32_t *)malloc(N_SAMPLES*sizeof(uint32_t));

    // Get a list of all templates
    // Print the template file names in the log file
    sprintf(sys_cmd, "find %s -type f > log.txt", INST_PATH);
    status = system(sys_cmd);

    // Read the template file names from the log file
    template_list = fopen("log.txt", "r");
    if(template_list == NULL){
      printf("CANNOT OPEN INSTRUCTION DIRECTORIES FILE!\n");
      return 0;
    }

    // Iterate over each template in the list
    while((read = getline(&line, &len, template_list)) != -1){

      // Get info on each template: instruction, template id, opcode
      get_instruction_info(info, line);

      // Load code of the template
      // If it's a branch take care of the not_taken/taken directory structure
      //if(info->instruction[0] == 'b'){
      //  sprintf(file_path, "%s/%s/%s/%s.txt", INST_PATH, info->instruction, info->info, info->template_name);
      //}
      //else{
      //  sprintf(file_path, "%s/%s/%s.txt", INST_PATH, info->instruction, info->template_name); 
      //}
      sprintf(file_path, "%s/%s/%s.txt", INST_PATH, info->instruction, info->template_name); 

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

      for(int trace=0; trace<N_TRACES; trace++){

        //wait_for_enter("\nPress ENTER to continue after setting up ILA trigger...\n");

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
          //Print sample of a trace
          printf("Sample %d:\n", sample);
          printf("0x");
          for(int offset=15; offset>=0; offset--){
            printf("%08x|", hbuf[sample*16+offset]);
          }
          printf("\n");

          for(int sensor=0; sensor<N_SENSORS; sensor++){
            if(sensor%2) {
              trace_sample = hamming_weight((0xffff0000 & hbuf[sample*16+int(sensor/2)])>>16);
            }else{
              trace_sample = hamming_weight(0x0000ffff & hbuf[sample*16+int(sensor/2)]);
            }

            trace_raw[sensor][sample] = trace_sample; 
            if(trace == 0){
              trace_averaged[sensor][sample] = trace_sample;
            } else if(trace == (N_TRACES-1)){
              trace_averaged[sensor][sample] += trace_sample; 
              trace_averaged[sensor][sample] /= N_TRACES; 
            } else {
              trace_averaged[sensor][sample] += trace_sample; 
            }
          }
        }

        // Write raw trace to raw dataset file
        fprintf(dataset_raw_f, "%s,%s,%d", info->instruction, (info->info == NULL)? "-" : info->info, info->template_id);
        for(int sensor=0; sensor<N_SENSORS; sensor++){
          for(int sample=0; sample<N_SAMPLES; sample++){
            fprintf(dataset_raw_f, ",%d", trace_raw[sensor][sample]);
          }
        }
        fprintf(dataset_raw_f, "\n");

      }

      // Save opcodes
      fprintf(opcodes_f, "%s,%s,%d", info->instruction, (info->info == NULL)? "-" : info->info, info->template_id);
      for(int sample=0; sample<N_SAMPLES; sample++){
        fprintf(opcodes_f, ",%08x", hbuf[sample*16+15]);
      }
      fprintf(opcodes_f, "\n");

      // Write averaged trace to dataset file
      fprintf(dataset_averaged_f, "%s,%s,%d", info->instruction, (info->info == NULL)? "-" : info->info, info->template_id);
      for(int sensor=0; sensor<N_SENSORS; sensor++){
        for(int sample=0; sample<N_SAMPLES; sample++){
          fprintf(dataset_averaged_f, ",%lf", trace_averaged[sensor][sample]);
        }
      }
      fprintf(dataset_averaged_f, "\n");

    }

    fclose(dataset_averaged_f);
    fclose(dataset_raw_f);
    fclose(opcodes_f);

    return 0;

}
