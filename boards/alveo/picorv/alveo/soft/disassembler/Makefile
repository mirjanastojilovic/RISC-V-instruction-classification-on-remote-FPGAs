# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

INCLUDE=disassembler.h
CFLAGS=-Wall -std=c99 -pedantic -g -include $(INCLUDE)
SRCS=$(wildcard *.c)
OBJS=$(SRCS:.c=.o)

PROG=main

all: $(PROG)
main: loader.o disassembler.o

clean:
	rm -rf $(PROG) $(OBJS)
