#ifndef CALIB_H
#define CALIB_H

#include "../host.hpp"

void wait_for_enter(const std::string &msg);
void calibrate_sensors_from_file(xrt::ip kernel, xrt::bo buffer, uint32_t* hbuf, uint32_t **idc_idf, int n_sensors, int idc_size, int idf_size);
uint32_t * calibrate_sensor(xrt::ip kernel, xrt::bo buffer, uint32_t* hbuf, int sensor_id, int sensor_width, int trace_size, int idc_size, int idf_size);
void idc_idf_sweep(xrt::ip kernel, xrt::bo buffer, uint32_t* hbuf, int sensor_id, int sensor_width, int trace_size, int idc_size, int idf_size);
uint32_t * pack_idc_idf(uint32_t * idc_idf, int idc, int idf, int idc_MAX, int idf_MAX);
calib_state_t check(uint32_t trace_sample, int sensor_width);
unsigned char hamming_weight(uint32_t data);

#endif
