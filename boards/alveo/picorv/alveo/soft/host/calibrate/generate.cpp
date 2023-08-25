#include <iostream>

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

int main() {

  uint32_t * idc_idf = (uint32_t *)malloc(4*sizeof(uint32_t));
  char file_path[1000];
  int IDC_SIZE = 32;
  int IDF_SIZE = 96;

  int idc[29] = {15, 15, 13, 11, 16, 16, 15, 10, 12, 16, 16, 14, 13, 13, 16, 16, 17, 15, 10, 16, 17, 17, 13, 15, 16, 17, 14, 11, 15};

  int idf[30] = {95, 78, 60, 26, 53, 84, 84, 17, 32, 63, 95, 71, 25, 27, 18, 83, 20, 79,  1, 52, 83, 76, 33,  4, 25, 24, 61, 29, 79};

  sprintf(file_path, "bram/tdc_29/with_CPU_flags/idc_idf.bin");
  FILE * idc_idf_file;
  idc_idf_file = fopen(file_path, "wb");
  if(idc_idf_file == NULL) {
    printf("ERROR IN OPENING IDC IDF BIN FILE\n");
    printf("%s\n", file_path);
    return 0;
  }

  for(int i = 0; i<29; i++){
    printf("Sensor %d: IDC = %d, IDF = %d\n", i, idc[i], idf[i]);
    idc_idf = pack_idc_idf(idc_idf, idc[i], idf[i], 32, 96);
    fwrite(idc_idf, sizeof(uint32_t), (IDC_SIZE+IDF_SIZE)/32, idc_idf_file);
  }

  fclose(idc_idf_file);

  return 0;

};
