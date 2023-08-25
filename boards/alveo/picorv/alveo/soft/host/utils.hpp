#ifndef UTILS_H_
#define UTILS_H_

#include "host.hpp"

char *get_filename(char *filename);
char *get_instruction(char *filename);
char *get_dirname(char *filename);
char *get_id(char *filename);
void get_instruction_info(inst_info * info, char * line);
void get_instruction_info_from_metadata(inst_info * info, metadata_line * metadata);
int get_line_number(char * file_name);
int load_instructions(char * file_name, uint32_t ** instructions, int * line_num);
void save_temperature(FILE * temperature_f, char * instruction, char * instruction_info, int template_id);
void get_csv_line(metadata_line * metadata, FILE * metadata_f);

#endif
