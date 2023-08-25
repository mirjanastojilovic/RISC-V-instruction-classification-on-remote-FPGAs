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

  if(info->instruction[0] == 'b'){
    strcpy(line_cpy2, line);
    strcpy(info->info, get_dirname(line_cpy2));
  } else {
    info->info[0] = '-';
    info->info[1] = '\0';
  }

  strcpy(line_cpy3, line);
  info->template_id = atoi(strrchr(get_filename(line_cpy3), '_')+1);

}

int get_line_number(char * file_name){

  FILE * instruction_f;
  instruction_f = fopen(file_name, "r");
  if (instruction_f == NULL) {
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

  printf("Instruction file has %d lines.\n", line_no);

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

