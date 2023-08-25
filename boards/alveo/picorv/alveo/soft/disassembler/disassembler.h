/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

#ifndef DISASSEMBLER_H
#define DISASSEMBLER_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef int32_t s32;

/* stream of 32 bit fixed length instructions */
struct progbits {
	u32 size;
	u32 *data;
};

struct progbits loadbits(char *filename);

int format(u8 opcode);
char *name(u32 insn);
char *op0(u32 insn);
char *op1(u32 insn);
char *op2(u32 insn);

#endif
