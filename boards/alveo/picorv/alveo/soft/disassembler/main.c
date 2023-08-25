/*
 Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
 Copyright 2023, School of Computer and Communication Sciences, EPFL.

 All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE.md file. 
 */

int main () {

  u32 insn = 0x00e70a33;
  int i = 0;
  printf("%4x:  %08x          %-8s %3s %3s %3s\n", 4*i, insn, name(insn), op0(insn), op1(insn), op2(insn));
  return 0;

}
