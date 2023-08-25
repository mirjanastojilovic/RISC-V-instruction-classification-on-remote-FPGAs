# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

LDLIBS += -lm
CFLAGS += -g -fopenmp

all: average

average.o: average.c

average: average.o
	$(CC) $^ -o $@ $(LDLIBS) $(CFLAGS)

clean:
	rm -f *.o average

