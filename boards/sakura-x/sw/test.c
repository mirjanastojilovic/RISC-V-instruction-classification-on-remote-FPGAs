/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

#include <stdio.h>
#include <dirent.h>
#include <libgen.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>

char *get_filename(char *filename) {

  char * bname = basename(filename);
  char *dot = strrchr(bname, '.');
  if(!dot || dot == bname) return "";
  int offset = dot - bname;
  bname[offset] = '\0';
  return bname;

}

int main(int argc, char** argv)
{
  struct dirent *dp;
  DIR *dfd;
 
  char * dir;
 
  FILE * fp;
  char * line = NULL;
  size_t len = 0;
  ssize_t read;

  fp = fopen("asm/inst_paths.txt", "r");
  if (fp == NULL)
    return 0;

  while ((read = getline(&line, &len, fp)) != -1) {
    printf("Retrieved line of length %zu:\n", read);
    printf("Line from file:\n%s", line);
    dir = line;
    dir[read-1] = '\0';

    if ((dfd = opendir(dir)) == NULL)
    {
     fprintf(stderr, "Can't open %s\n", dir);
     return 0;
    }
 
    char inst_file_path_full[1000] ;
    char inst_file_name[1000] ;

 
    while ((dp = readdir(dfd)) != NULL)
    {
    
      struct stat stbuf ;
      sprintf( inst_file_path_full , "%s/%s",dir,dp->d_name) ;

      if( stat(inst_file_path_full,&stbuf ) == -1 )
      {
       printf("Unable to stat file: %s\n",inst_file_path_full) ;
       return 0;
       continue ;
      }
 
      if ( ( stbuf.st_mode & S_IFMT ) == S_IFDIR )
      {
       continue;
       // Skip directories
      }
      strcpy(inst_file_name, inst_file_path_full);
      char * inst_file_name_no_ext = get_filename(inst_file_name);
 
      printf("File info:\n%s\n%s\n%s\n", inst_file_path_full, basename(inst_file_path_full), inst_file_name_no_ext);
    }
  }

  fclose(fp);
  if (line)
      free(line);
  return 0;

}

