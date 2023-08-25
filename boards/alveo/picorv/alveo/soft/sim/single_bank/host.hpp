#ifndef HOST_H
#define HOST_H
#include <xrt/xrt_bo.h>
#include <xrt/xrt_device.h>
#include <xrt/xrt_kernel.h>
#include <xrt/xrt_uuid.h>
#include <experimental/xrt_error.h>
#include <experimental/xrt_ip.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <iostream>
#include <dirent.h>
#include <libgen.h>

// Write register addresses
#define RST_ADDR             0x100
#define DUMP_PTR_BASE_ADDR   0x200
#define CALIB_REG_BASE_ADDR  0x500
#define CALIB_TRG_ADDR       0x600
#define CALIB_TRACE_TRG_ADDR 0x700
#define CODE_LEN_ADDR        0x300
#define LOAD_CODE_TRG_ADDR   0x400
#define START_EXEC_ADDR      0x800

// Read register address
#define STATUS_REG_ADDR      0x000

// Read register masks
#define CODE_DUMP_IDLE_MASK  0x01
#define CALIB_DUMP_IDLE_MASK 0x06
#define TRACE_DUMP_IDLE_MASK 0x26
#define TRACE_DONE_IDLE_MASK 0x06
#define BRAM_DUMP_IDLE_MASK  0x03

#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c\n"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0')

typedef enum {ALL_ZEROS, ALL_ONES, RISING_EDGE, FALLING_EDGE, ERROR} calib_state_t;

typedef struct Code{

  uint32_t * code;
  uint32_t code_size;

} Code;

typedef struct {

  char template_name[1000];
  char instruction[1000];
  char info[1000];
  int template_id;

} inst_info;

#endif
