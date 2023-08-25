#include <xrt/xrt_bo.h>
#include <xrt/xrt_device.h>
#include <xrt/xrt_kernel.h>
#include <xrt/xrt_uuid.h>
#include <experimental/xrt_error.h>
#include <experimental/xrt_ip.h>
#include <unistd.h>

#include <iostream>

int main(int argc, char* argv[]) {

    if (argc != 2) {
        std::cerr << "usage: " << argv[0] << " XCLBIN" << std::endl;
        printf("Error\n");
        std::exit(-1);
    }
    // export XCL_EMULATION_MODE=hw_emu to perform simulation

    // create the device
    auto dev = xrt::device(0);

    // load the binary into the memory
    auto xclbin = dev.load_xclbin(argv[1]);

    auto kernel = xrt::ip(dev, xclbin, "PicoRV32_SCA_kernel");

    // args: device, size in bytes, dram bank
    auto buffer = xrt::bo(dev, 1 << 13, 1);
    // buffers are also little-endian
    uint32_t* hbuf = buffer.map<uint32_t*>();

    uint32_t code[26] = {
      0xfef08093,
      0x9ed10113,
      0xfd118193,
      0x4dd20213,
      0x5d328293,
      0xd5d30313,
      0xfff38393,
      0x00140413,
      0x28748493,
      0x4a950513,
      0x18f58593,
      0xfff60613,
      0x0d468693,
      0x2ff70713,
      0x80378793,
      0xfff80813,
      0xdde88893,
      0x6bf90913,
      0xbde98993,
      0xbb0a0a13,
      0x4a2a8a93,
      0xcf9b0b13,
      0x3f7b8b93,
      0x000c0c13,
      0xfbfc8c93,
      0x00100073
    };

    uint32_t cmd_addr[27] = {
      // reset system
      0x100,
      // set dump ptr pt 1
      0x200,
      // set dump ptr pt 2
      0x204,
      // store sensor 0 calib pt 1
      0x500,
      // store sensor 0 calib pt 2
      0x504,
      // store sensor 0 calib pt 3
      0x508,
      // store sensor 0 calib pt 4
      0x50c,
      // store calib to sensor 0
      0x600,
      // store sensor 1 calib pt 1
      0x500,
      // store sensor 1 calib pt 2
      0x504,
      // store sensor 1 calib pt 3
      0x508,
      // store sensor 1 calib pt 4
      0x50c,
      // store calib to sensor 1
      0x600,
      // store sensor 2 calib pt 1
      0x500,
      // store sensor 2 calib pt 2
      0x504,
      // store sensor 2 calib pt 3
      0x508,
      // store sensor 2 calib pt 4
      0x50c,
      // store calib to sensor 2
      0x600,
      // store sensor 3 calib pt 1
      0x500,
      // store sensor 3 calib pt 2
      0x504,
      // store sensor 3 calib pt 3
      0x508,
      // store sensor 3 calib pt 4
      0x50c,
      // store calib to sensor 3
      0x600,
      // record calib trace
      0x700,
      // set code length
      0x300,
      // start loading code 
      0x400,
      // start exec
      0x800
      };

    uint32_t cmd[27] = {
      // reset system
      0x00000000,
      // set dump ptr pt 1
      0x12345678,
      // set dump ptr pt 2
      0x9ABCD012,
      // store sensor 0 calib pt 1
      // 32-bit IDC
      0xFFFFF000,
      // store sensor 0 calib pt 2
      // 96-bit IDF (upper part)
      0xFFFF0000,
      // store sensor 0 calib pt 3
      // 96-bit IDF (middle part)
      0xFFFFFFFF,
      // store sensor 0 calib pt 4
      // 96-bit IDF (lower part)
      0xFFFFFFFF,
      // store calib to sensor 0
      0x00000000,
      // store sensor 1 calib pt 1
      0xFF000000,
      // store sensor 1 calib pt 2
      0xFFFFFF00,
      // store sensor 1 calib pt 3
      0xFFFFFFFF,
      // store sensor 1 calib pt 4
      0xFFFFFFFF,
      // store calib to sensor 1
      0x00000001,
      // store sensor 2 calib pt 1
      0xFFFFFF00,
      // store sensor 2 calib pt 2
      0xFFFFFF00,
      // store sensor 2 calib pt 3
      0xFFFFFFFF,
      // store sensor 2 calib pt 4
      0xFFFFFFFF,
      // store calib to sensor 2
      0x00000002,
      // store sensor 3 calib pt 1
      0xFFF00000,
      // store sensor 3 calib pt 2
      0xF0000000,
      // store sensor 3 calib pt 3
      0xFFFFFFFF,
      // store sensor 3 calib pt 4
      0xFFFFFFFF,
      // store calib to sensor 3
      0x00000003,
      // record calib trace
      0x50000000,
      // set code length
      0x0000001A,
      // start loading code 
      0x00000000,
      // start exec
      0x80000000
       };

    int resp;

    cmd[1] = buffer.address();
    cmd[2] = buffer.address() >> 32;

    int i = 0;
    while(cmd_addr[i]!=0x300){
      printf("writing:\ndata: %08x\naddress: %08x\n", cmd[i], cmd_addr[i]);
      kernel.write_register(cmd_addr[i], cmd[i]);
      i++;
    }

    //wait until trace is stored in bram
    do{
      resp = kernel.read_register(0x00);
      printf("Status register: %08X\n", resp);
      printf("Masked %08X\n", resp&0x8);
      printf("Should be %08X\n", 0x00000008);
      printf("Condition %d\n", (resp&0x8)!=0x8);
    } while ((resp&0x8)!=0x8); 

    //trigger trace load
    uint32_t xx = 0x00000b00;
    uint32_t yy = 0x00000000;
    kernel.write_register(xx, yy);

    //wait until the trace is recorded
    do{
      resp = kernel.read_register(0x00);
      printf("Status register: %08X\n", resp);
      printf("Masked %08X\n", resp&0x2);
      printf("Should be %08X\n", 0x00000002);
      printf("Condition %d\n", (resp&0x2)!=0x2);
    } while ((resp&0x2)!=0x2); 
    //sleep(1);

    buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    for(int sample=0; sample<128; sample++){
      printf("Sample %d:\n", sample);
      printf("0x");
      for(int offset=15; offset>=0; offset--){
        printf("%08x", hbuf[sample*16+offset]);
      }
      printf("\n");
      //for(int offset=0; offset<16; offset++){
      //  if(offset != 15){
      //    printf("Sensor %d: %02x\n", (hbuf[sample*16+offset]&0x0000ff00)>>8, hbuf[sample*16+offset]&0xff);
      //    printf("Sensor %d: %02x\n", ((hbuf[sample*16+offset]>>16)&0x0000ff00)>>8, (hbuf[sample*16+offset]>>16)&0xff);
      //  }
      //  if(offset == 15){
      //    printf("Instruction: %08x\n", hbuf[sample*16+offset]);
      //  }
      //}
    }

    // initialize dram region with code
    for(int i=0; i<26; i++){
      hbuf[i] = code[i]; 
    }
    buffer.sync(XCL_BO_SYNC_BO_TO_DEVICE);

    while(cmd_addr[i]!=0x800){
      printf("writing:\ndata: %08x\naddress: %08x\n", cmd[i], cmd_addr[i]);
      kernel.write_register(cmd_addr[i], cmd[i]);
      i++;
    }

    //wait until the code is dumped
    do{
      resp = kernel.read_register(0x00);
    } while ((resp&0x1)!=0x1); 
    //sleep(1);

    // start exec
    kernel.write_register(cmd_addr[i], cmd[i]);

    //wait until traces dumped to bram
    do{
      resp = kernel.read_register(0x00);
      printf("Status register: %08X\n", resp);
      printf("Masked %08X\n", resp&0x8);
      printf("Should be %08X\n", 0x00000008);
      printf("Condition %d\n", (resp&0x8)!=0x8);
    } while ((resp&0x8)!=0x8); 

    //trigger trace load
    kernel.write_register(xx, yy);
    //wait until the trace is recorded
    do{
      resp = kernel.read_register(0x00);
    } while ((resp&0x2)!=0x2); 
    //sleep(1);

    buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    for(int sample=0; sample<128; sample++){
      printf("Sample %d:\n", sample);
      printf("0x");
      for(int offset=15; offset>=0; offset--){
        printf("%08x", hbuf[sample*16+offset]);
      }
      printf("\n");
      //for(int offset=0; offset<16; offset++){
      //  if(offset != 15){
      //    printf("Sensor %d: %02x\n", (hbuf[sample*16+offset]&0x0000ff00)>>8, hbuf[sample*16+offset]&0xff);
      //    printf("Sensor %d: %02x\n", ((hbuf[sample*16+offset]>>16)&0x0000ff00)>>8, (hbuf[sample*16+offset]>>16)&0xff);
      //  }
      //  if(offset == 15){
      //    printf("Instruction: %08x\n", hbuf[sample*16+offset]);
      //  }
      //}
    }

    //read from 3rd sensor bank
    kernel.write_register(0x900, 0x03);

    //wait until traces dumped to bram
    do{
      resp = kernel.read_register(0x00);
      printf("Status register: %08X\n", resp);
      printf("Masked %08X\n", resp&0x8);
      printf("Should be %08X\n", 0x00000008);
      printf("Condition %d\n", (resp&0x8)!=0x8);
    } while ((resp&0x8)!=0x8); 

    //trigger trace load
    kernel.write_register(xx, yy);
    //wait until the trace is recorded
    do{
      resp = kernel.read_register(0x00);
    } while ((resp&0x2)!=0x2); 
    //sleep(1);

    buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    for(int sample=0; sample<128; sample++){
      printf("Sample %d:\n", sample);
      printf("0x");
      for(int offset=15; offset>=0; offset--){
        printf("%08x", hbuf[sample*16+offset]);
      }
      printf("\n");
      //for(int offset=0; offset<16; offset++){
      //  if(offset != 15){
      //    printf("Sensor %d: %02x\n", (hbuf[sample*16+offset]&0x0000ff00)>>8, hbuf[sample*16+offset]&0xff);
      //    printf("Sensor %d: %02x\n", ((hbuf[sample*16+offset]>>16)&0x0000ff00)>>8, (hbuf[sample*16+offset]>>16)&0xff);
      //  }
      //  if(offset == 15){
      //    printf("Instruction: %08x\n", hbuf[sample*16+offset]);
      //  }
      //}
    }


    
    return 0;

    //hbuf[0] = 0; // set the first 4 bytes to zero
    //hbuf[1] = 1; // set the second 4 bytes


    //buffer.sync(XCL_BO_SYNC_BO_FROM_DEVICE);
    // little-endian registers
    //kernel.write_register(0x10, buffer.address());
    //kernel.write_register(0x10 + 4, buffer.address() >> 32);

}
