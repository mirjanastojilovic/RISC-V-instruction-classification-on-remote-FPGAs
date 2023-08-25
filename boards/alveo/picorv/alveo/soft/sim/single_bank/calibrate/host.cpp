#include "../host.hpp"
#include "calib.hpp"

#include <iostream>

int main(int argc, char* argv[]) {

    if (argc != 8) {
        std::cerr << "usage: " << argv[0] << " XCLBIN N_SENSORS N_SAMPLES SENSOR_WIDTH IDC_SIZE IDF_SIZE PATH" << std::endl;
        printf("Error\n");
        std::exit(-1);
    }

    int N_SENSORS = atoi(argv[2]);
    int N_SAMPLES = atoi(argv[3]);
    int SENSOR_WIDTH = atoi(argv[4]);
    int IDC_SIZE = atoi(argv[5]);
    int IDF_SIZE = atoi(argv[6]);
    char * PATH = argv[7];

    char file_path[1000];

    // create the device
    auto dev = xrt::device(0);

    // load dummy verification bistream to force the actual one to be programmed
    //auto xclbin = dev.load_xclbin("../../../bitstreams/verify.xclbin");

    // load the binary into the memory
    auto xclbin = dev.load_xclbin(argv[1]);

    wait_for_enter("\nPress ENTER to continue after setting up ILA trigger...\n");

    auto kernel = xrt::ip(dev, xclbin, "PicoRV32_SCA_kernel");

    // args: device, size in bytes, dram bank
    auto buffer = xrt::bo(dev, N_SAMPLES*64, 1);
    // buffers are also little-endian
    uint32_t* hbuf = buffer.map<uint32_t*>();

    int resp;
    uint32_t payload;

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

    uint32_t ** idc_idf;
    idc_idf = (uint32_t **)malloc(N_SENSORS*sizeof(uint32_t *));

    // open config file to dump sensor width, idc size, idf size, n_sensors
    sprintf(file_path, "%s/idc_idf_config.txt", PATH);
    FILE * idc_idf_config;
    idc_idf_config = fopen(file_path, "w");
    if(idc_idf_config == NULL) {
      printf("ERROR IN OPENING CONFIG FILE\n");
      printf("%s\n", file_path);
      return 0;
    }

    fprintf(idc_idf_config, "Number of sensors: %d\n", N_SENSORS);
    fprintf(idc_idf_config, "Sensor OD   width: %d\n", SENSOR_WIDTH);
    fprintf(idc_idf_config, "Sensor IDC  width: %d\n", IDC_SIZE);
    fprintf(idc_idf_config, "Sensor IDF  width: %d\n", IDF_SIZE);
    fprintf(idc_idf_config, "Calibration file path: ./idc_idf.bin\n");

    fclose(idc_idf_config);

    // open file that will contain the idc_idf for each sensor
    //sprintf(file_path, "%s/idc_idf.bin", PATH);
    //FILE * idc_idf_file;
    //idc_idf_file = fopen(file_path, "wb");
    //if(idc_idf_file == NULL) {
    //  printf("ERROR IN OPENING IDC IDF BIN FILE\n");
    //  printf("%s\n", file_path);
    //  return 0;
    //}

    // Calibrate all sensors
    for(int sensor=0; sensor<N_SENSORS; sensor++){
      printf("************************************************\n");
      printf("CALIBRATE SENSOR %d...\n", sensor);

      //// Get calibration for sensor
      //idc_idf[sensor] = calibrate_sensor(kernel, buffer, hbuf, sensor, SENSOR_WIDTH, N_SAMPLES, IDC_SIZE, IDF_SIZE);
      idc_idf_sweep(kernel, buffer, hbuf, sensor, SENSOR_WIDTH, N_SAMPLES, IDC_SIZE, IDF_SIZE);

      //// Store it in sensor calibration file
      //fwrite(idc_idf[sensor], sizeof(uint32_t), (IDC_SIZE+IDF_SIZE)/32, idc_idf_file);

    }

    //fclose(idc_idf_file);

    return 0;

}
