#include "host.hpp"

char *get_filename(char *filename) {

  char * bname = basename(filename);
  char *dot = strrchr(bname, '.');
  if(!dot || dot == bname) return NULL;
  int offset = dot - bname;
  bname[offset] = '\0';
  return bname;

}

char *get_instruction(char *filename) {

  char * bname = basename(filename);
  char *dot = strchr(bname, '_');
  if(!dot || dot == bname) return NULL;
  int offset = dot - bname;
  bname[offset] = '\0';
  return bname;

}

char *get_dirname(char *filename) {

  //char * bname = dirname(filename);
  *strrchr(filename, '/') = '\0';
  char *dot = strrchr(filename, '/');
  if(!dot ) return NULL;
  //if(!dot || dot == bname) return NULL;
  return dot+1;

}

char *get_id(char *filename) {

  char * bname = dirname(filename);
  char *dot = strrchr(bname, '_');
  if(!dot || dot == bname) return NULL;
  return dot+1;

}

void get_instruction_info(inst_info * info, char * line){

  char line_cpy0[1000];
  char line_cpy1[1000];
  char line_cpy2[1000];
  char line_cpy3[1000];

  strcpy(line_cpy0, line);
  strcpy(info->template_name, get_filename(line_cpy0));

  strcpy(line_cpy1, line);
  strcpy(info->instruction, get_instruction(line_cpy1));

  //if(info->instruction[0] == 'b'){
  //  strcpy(line_cpy2, line);
  //  strcpy(info->info, get_dirname(line_cpy2));
  //} else {
    info->info[0] = '-';
    info->info[1] = '\0';
  //}

  strcpy(line_cpy3, line);
  info->template_id = atoi(strrchr(get_filename(line_cpy3), '_')+1);

}

void get_instruction_info_from_metadata(inst_info * info, metadata_line * metadata){

  sprintf(info->template_name, "%s_template_%d.txt", metadata->inst_name, metadata->template_id);
  strcpy(info->instruction, metadata->inst_name);
  strcpy(info->info, metadata->inst_info);
  info->template_id = metadata->template_id;

}

int get_line_number(char * file_name){

  FILE * instruction_f;
  instruction_f = fopen(file_name, "r");
  if (instruction_f == NULL) {
    printf("%s\n", file_name);
    printf("Error opening the instructions file!\n");
    return -1;
  }

  char ch;
  int line_no = 0;

  for (ch = getc(instruction_f); ch != EOF; ch = getc(instruction_f))
        if (ch == '\n') // Increment count if this character is newline
            line_no = line_no + 1;

  fclose(instruction_f);

  return line_no;

}

int load_instructions(char * file_name, uint32_t ** instructions, int * line_num){

  printf("Opening instruction file: %s\n", file_name);

  int line_no = get_line_number(file_name);

  //printf("Instruction file has %d lines.\n", line_no);

  (* instructions) = (uint32_t *)malloc(line_no*sizeof(uint32_t *));

  FILE * instruction_f;
  instruction_f = fopen(file_name, "r");
  if (instruction_f == NULL) {
    printf("Error opening the instructions file!\n");
    return EXIT_FAILURE;
  }

  char line[300];

  for(int line_cnt=0; line_cnt<line_no; line_cnt++){
    fgets(line, sizeof(line), instruction_f);
    (* instructions)[line_cnt] = (uint32_t)strtol(line, NULL, 16);

  }

  (* line_num) = line_no;
  fclose(instruction_f);

  return EXIT_SUCCESS;

}

void save_temperature(FILE * temperature_f, char * instruction, char * instruction_info, int template_id){

  int status = system("xbutil examine -d 0000:01:00.1 --report thermal > tmp.txt");

  char line[256];
  int line_no = 0;
  int temp[5];
  int i=0;
  char temperature[3];

  time_t rawtime;
  struct tm * timeinfo;

  time(&rawtime);
  timeinfo = localtime(&rawtime);

  FILE * temp_file = fopen("tmp.txt", "r");
  if(temp_file == NULL){
    printf("ERROR IN OPENING TEMP TEMPERATURE FILE");
    return;
  }

  while(fgets(line, sizeof(line), temp_file)){
    if(line_no>5 && line_no<11){
      temperature[0] = line[31];
      temperature[1] = line[32];
      temperature[3] = '\0';
      temp[i] = atoi(temperature);
      i++;
    }
    line_no++;
  }

  char * time_string = asctime(timeinfo);
  time_string[strlen(time_string)-1] = 0;
  fprintf(temperature_f, "%s,%s,%d,", instruction, (instruction_info == NULL)? "-" : instruction_info, template_id);
  fprintf(temperature_f, "%s,", time_string);
  fprintf(temperature_f, "%d,", temp[0]);
  fprintf(temperature_f, "%d,", temp[1]);
  fprintf(temperature_f, "%d,", temp[2]);
  fprintf(temperature_f, "%d,", temp[3]);
  fprintf(temperature_f, "%d\n", temp[4]);

  fclose(temp_file);
  return;

}

void get_csv_line(metadata_line * metadata, FILE * metadata_f){

  fscanf(metadata_f, "%s", metadata->csv_line);

  char *ptr = strtok(metadata->csv_line, ",");
  char tmp_string[100];

  strcpy(metadata->inst_name, ptr);
  ptr = strtok(NULL, ",");

  strcpy(metadata->inst_info, ptr);
  ptr = strtok(NULL, ",");

  strcpy(tmp_string, ptr);
  metadata->template_id = atoi(tmp_string);
  ptr = strtok(NULL, ",");

  strcpy(tmp_string, ptr);
  metadata->asm_line = atoi(tmp_string);
  ptr = strtok(NULL, ",");

  strcpy(metadata->hex_val, ptr);
  ptr = strtok(NULL, ",");

  //strcpy(tmp_string, ptr);
  //metadata->start_sample = atoi(tmp_string);
  //ptr = strtok(NULL, ",");

  //strcpy(tmp_string, ptr);
  //metadata->end_sample = atoi(tmp_string);
  //ptr = strtok(NULL, ",");

  //printf("%s,%s,%d,%d,%s,%d,%d\n", metadata->inst_name, metadata->inst_info, metadata->template_id, metadata->asm_line, metadata->hex_val, metadata->start_sample, metadata->end_sample);

  return;

}

