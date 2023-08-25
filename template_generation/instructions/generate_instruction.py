# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

from utils import *
import argparse

random.seed(10)

parser = argparse.ArgumentParser(description='Template generation program.')
parser.add_argument("-t", "--template_type", help="Template type. nops or random", required=True)
parser.add_argument("-n", "--n_templates", help="Number of templates generated.", required=True)
parser.add_argument("-c", "--CPU", help="CPU type. riscy or picorv32", required=True)
args = parser.parse_args()

N_TEMPLATES = int(args.n_templates) #10000
RANDOM = args.template_type #"random"
PROCESSOR = args.CPU #"riscy"
if(PROCESSOR != "picorv32" and PROCESSOR !="riscy"):
    print("Wrong processor!")
    exit()

print("N_TEMPLATES = "+str(N_TEMPLATES))
print("RANDOM = "+RANDOM)
print("PROCESSOR = "+PROCESSOR)

arith_logic_shift_compare_instructions = ["add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu","addi", "xori", "ori", "andi", "slli", "srli", "srai", "slti", "sltiu", "lui", "auipc"]
branch_instructions = ["beq", "bne", "blt", "bge", "bltu", "bgeu"]
store_instructions = ["sw", "sh", "sb"]
load_instructions = ["lw", "lh", "lb", "lhu", "lbu"]
jump_instructions = ["jal", "jalr"]

branch_outcomes = ["taken", "not_taken"]
N_NOPS = 6
#N_TEMPLATES = 10000
#RANDOM = "random"
#PROCESSOR = "riscy"

cwd = os.getcwd()

metadata_csv_f = open("metadata.csv", "w")
metadata_csv_f.write("instruction,info,template_id,asm_line\n")

for TARGET_INSTRUCTION in arith_logic_shift_compare_instructions:
    generate_arith_logic_shift_compare(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, RANDOM, metadata_csv_f)

for TARGET_INSTRUCTION in branch_instructions:
    #for BRANCH_OUTCOME in branch_outcomes:
    #    generate_branch(cwd, TARGET_INSTRUCTION, BRANCH_OUTCOME, N_TEMPLATES, N_NOPS, PROCESSOR, RANDOM, metadata_csv_f)
    generate_branch(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, RANDOM, metadata_csv_f)

for TARGET_INSTRUCTION in store_instructions:
    generate_store(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, RANDOM, metadata_csv_f)

for TARGET_INSTRUCTION in load_instructions:
    generate_load(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, RANDOM, metadata_csv_f) 

for TARGET_INSTRUCTION in jump_instructions:
    generate_jump(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, RANDOM, metadata_csv_f)

metadata_csv_f.close()

### LIMITATIONS
### EXPLAIN BETTER
### Add comment that explains the code, a read me
#1. Branches and jumps have a destination distance of only 0-200 instructions, to limit the size of the code
#2. jalr has rs1 set to 0xffff8000, because RISCY expects the code address has this as a base offset, but otherwise it would be set to 0
#3. lw and sw instructions have the immediate set to 0
#4. random instructions before and after the target instructions are only arith/logic/shift/compare because of RISCY
#5. lw and sw address has the top 16 bits set to 0 (because of RISCY) and the bottom 2 bits set to 0 (byte aligned addressing)
#6. No hazards (because of RISCY's pipelined architecture)
    # Remove for PicoRV
