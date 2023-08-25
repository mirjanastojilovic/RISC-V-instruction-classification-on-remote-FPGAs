#ifndef UTILS_H_
#define UTILS_H_

#include "host.hpp"

char *get_filename(char *filename);
char *get_instruction(char *filename);
char *get_dirname(char *filename);
char *get_id(char *filename);
void get_instruction_info(inst_info * info, char * line);
int get_line_number(char * file_name);
int load_instructions(char * file_name, uint32_t ** instructions, int * line_num);

#endif
