# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import random
import numpy as np
import re
import os

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val                         # return positive value as is

def tohex(val, nbits):
    return hex((val + (1 << nbits)) % (1 << nbits))

def invert_bits(imm, bits):
    inverted_imm = ""#imm#.copy()
    for i in range(0, bits):
        if (imm[i] == '0'):
            inverted_imm += '1'
        else:
            inverted_imm += '0'
    return inverted_imm

def generate_random_value(bits, exclude_zero):

    if(exclude_zero == 1):
        HW = random.randint(1, bits)
    else:
        HW = random.randint(0, bits)

    num = []
    for i in range(0, HW):
        num.append('1')
    for j in range(0, bits - HW):
        num.append('0')

    random.shuffle(num)
    num_str = num[0]
    for i in range(1, bits):
        num_str = num_str + num[i]
    return num_str


def init_reg(reg, rand, val):

    init_string = ""

    if(rand == "random"):
        # if init is random, then initialize to random 32 bits
        imm = generate_random_value(bits=32, exclude_zero=0)
    else:
        # else initialize to the passed value (binary array)
        #imm ='{0:032b}'.format(val)
        imm=val
    imm_low = int(imm[20:32], 2)
    imm_high = int(imm[0:20], 2)

    if imm[20] == "1":
        imm_bin = bin(int(tohex(imm_high, 32), 16))[2:].zfill(20)
        imm_bin_inv = invert_bits(imm_bin,20)
        init_string = init_string + "lui x" + str(reg) + "," + hex(int(imm_bin_inv, 2)) + '\n'
    else:
        init_string = init_string + "lui x" + str(reg) + "," + tohex(imm_high, 32) + '\n'
    imm_low = twos_comp(int(tohex(imm_low, 32), 16), 12)
    init_string = init_string + "xori x" + str(reg) + ", x" + str(reg) + "," + str(imm_low)

    return init_string

def generate_instruction(instruction, inst_type, free_regs, target=0, label="label"):

    # PROBLEM CASES: (use an additional parameter list to send special operands constraints)
    # JAL and JALR; THE IMM NEEDS TO BE CALCULATED CORRECTLY: calculated in top, but forwarded here as an additional argument

    instruction_asm = instruction
    operands = {}

    rd = rs1 = rs2 = -1
    regs_no_x0 = free_regs.copy()
    if(free_regs.count(0)>0):
        regs_no_x0.remove(0)
    rd = random.choice(regs_no_x0)
    if(inst_type == "R"):
        rs1 = random.choice(free_regs)
        rs2 = random.choice(free_regs)
        instruction_asm = instruction+" x"+str(rd)+", x"+str(rs1)+", x"+str(rs2)
    elif(inst_type == "I"):
        rs1 = random.choice(free_regs)
        if(instruction[0]=='l'):
            rs1 = random.choice(regs_no_x0)
            # Loads have immediates set to 0
            imm = twos_comp(int(tohex(0, 12), 16), 12)
            instruction_asm = instruction+" x"+str(rd)+", "+str(imm)+"(x"+str(rs1)+")"
        else:
            if(instruction=="slli" or instruction=="srli" or instruction=="srai"):
                imm = int(tohex(random.randint(0,2**5-1), 12), 16)
            elif(instruction=="jalr"):
                rs1 = random.choice(regs_no_x0)
                imm = target
            else:
                imm = twos_comp(int(tohex(random.randint(0,2**12), 12), 16), 12)
            instruction_asm = instruction+" x"+str(rd)+", x"+str(rs1)+", "+str(imm)
    elif(inst_type == "U"):
        imm = int(tohex(random.randint(0,2**20-1), 20), 16)
        instruction_asm = instruction+" x"+str(rd)+", "+str(imm)
    elif(inst_type == "B"):
        rd = -1
        rs1 = random.choice(regs_no_x0)
        rs2 = random.choice(regs_no_x0)
        while(rs1 == rs2):
            rs2 = random.choice(regs_no_x0)
        instruction_asm = instruction+" x"+str(rs1)+", x"+str(rs2)+", "+label
    elif(inst_type == "S"):
        rd = -1
        rs1 = random.choice(regs_no_x0)
        rs2 = random.choice(free_regs)
        # Stores have immediates set to 0
        imm = twos_comp(int(tohex(0, 12), 16), 12)
        instruction_asm = instruction+" x"+str(rs2)+", "+str(imm)+"(x"+str(rs1)+")"
    elif(inst_type == "J"):
        instruction_asm = instruction+" x"+str(rd)+", "+label

    if(free_regs.count(rd)>0 and rd>=0):
        free_regs.remove(rd)
    if(rd>=0):
        operands["rd"] = rd;
    if(free_regs.count(rs1)>0 and rs1>=0):
        free_regs.remove(rs1)
    if(rs1>=0):
        operands["rs1"] = rs1;
    if(free_regs.count(rs2)>0 and rs2>=0):
        free_regs.remove(rs2)
    if(rs2>=0):
        operands["rs2"] = rs2;

    return instruction_asm, free_regs, operands

def inst_type(instruction):

    if(instruction == "add" or instruction == "sub" or instruction == "xor" or instruction == "or" or instruction == "and" or
       instruction == "sll" or instruction == "srl" or instruction == "sra" or instruction == "slt" or instruction == "sltu"):
        return "R"
    elif(instruction == "addi" or instruction == "xori" or instruction == "ori" or instruction == "andi" or instruction == "slli" or
         instruction == "srli" or instruction == "srai" or instruction == "slti" or instruction == "sltiu" or instruction == "jalr" or
         instruction == "lw" or instruction == "lh" or instruction == "lb" or instruction == "lbu" or instruction == "lhu"):
        return "I"
    elif(instruction == "beq" or instruction == "bne" or instruction == "blt" or instruction == "bge" or instruction == "bltu" or instruction == "bgeu"):
        return "B"
    elif(instruction == "sw" or instruction == "sh" or instruction == "sb"):
        return "S"
    elif(instruction == "lui" or instruction == "auipc"):
        return "U"
    elif(instruction == "jal"):
        return "J"

def rand_inst(subset="no_jumps"):

    if(subset == "all"):
        instructions = ["add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu","addi", "xori", "ori", "andi", "slli", "srli", "srai", "slti", "sltiu", "beq", "bne", "blt", "bge", "bltu", "bgeu", "sw", "sh", "sb", "lw", "lh", "lb", "lhu", "lbu", "lui", "auipc", "jal", "jalr"]
    else:
        instructions = ["add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu","addi", "xori", "ori", "andi", "slli", "srli", "srai", "slti", "sltiu", "beq", "bne", "blt", "bge", "bltu", "bgeu", "sw", "sh", "sb", "lw", "lh", "lb", "lhu", "lbu", "lui","auipc"]
    return instructions[random.randint(0, len(instructions)-1)]

def generate_folder(path, folder_name):
    isExists = os.path.exists(path + "/" + folder_name)
    if not isExists:
        os.makedirs(path + "/" + folder_name)

    newpath = path + "/" + folder_name
    return newpath

#def generate_all_instructions(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, BRANCH_OUTCOME, PROCESSOR, random_templates:
#out_path = generate_folder(cwd, "asm/"+TARGET_INSTRUCTION)
#
#    all_regs = []
#    for reg in range(0, 32):
#        all_regs.append(reg)
#
#    for template in range(0, N_TEMPLATES):
#
#        template_f = open(out_path + "/" + TARGET_INSTRUCTION + "_template_" + str(template) + '.s', 'w')
#
#        target_segment = ["", "", ""]
#        free_regs = all_regs.copy()
#        if(random_templates == "random"):
#            regs_left = 9
#        else:
#            regs_left = 3
#
#        # Target instruction
#        case for jal and jalr
#        inst, free_regs, target_operands = generate_instruction(TARGET_INSTRUCTION, inst_type(TARGET_INSTRUCTION), free_regs)
#        target_segment[1] = inst
#        if(random_templates == "random"):
#            # Random instruction before
#            rand_instruction = rand_inst()
#            inst, free_regs, operands_pre = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs)
#            target_segment[0] = inst
#            # Random instruction after
#            rand_instruction = rand_inst()
#            inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs)
#            target_segment[2] = inst
#
#
#        # Initialize registers used the three target instructions
#        template_f.write("/*Initialize registers*/\n")
#        regs_to_init = list(set(all_regs) - set(free_regs))
#
#        init_all_registers(...)
#
#        # Add nops between initialization and targets
#        template_f.write("/* Add nops */\n")
#        for nop in range(0, N_NOPS):
#            template_f.write("addi x0, x0, 0\n")
#
#        # Add targets
#        template_f.write("/* Add target instructions */\n")
#        # if random == random then add random instructions before
#        # else just add the single instruction
#        if(random_templates == "random"):
#            for instruction in target_segment:
#                template_f.write(instruction+"\n")
#        else:
#            template_f.write(target_segment[1]+"\n")
#
#        # Add nops between targets and fault
#        template_f.write("/* Add nops */\n")
#        for nop in range(0, N_NOPS):
#            template_f.write("addi x0, x0, 0\n")
#
#        # Add fault
#        template_f.write("ebreak\n")
#
#        add_trailing_instructions(...)

def generate_arith_logic_shift_compare(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, random_templates, metadata_csv_f):

    out_path = generate_folder(cwd, "asm/"+TARGET_INSTRUCTION)

    all_regs = []
    for reg in range(0, 32):
        all_regs.append(reg)

    for template in range(0, N_TEMPLATES):

        n_branch_nops = random.randint(1,20)
        instruction_position = 0;

        template_f = open(out_path + "/" + TARGET_INSTRUCTION + "_template_" + str(template) + '.s', 'w')

        target_segment = ["", "", ""]
        free_regs = all_regs.copy()
        if(random_templates == "random"):
            regs_left = 9
        else:
            regs_left = 3

        # Target instruction
        inst, free_regs, target_operands = generate_instruction(TARGET_INSTRUCTION, inst_type(TARGET_INSTRUCTION), free_regs)
        target_segment[1] = inst
        if(random_templates == "random"):
            # Random instruction before
            rand_instruction = rand_inst()
            inst, free_regs, operands_pre = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs)
            target_segment[0] = inst
            # Random instruction after
            rand_instruction = rand_inst("all")
            if(rand_instruction == "jalr"):
                # 2*9 = the 18 instructions to initialize the 9 registers for the target instructions
                # N_NOPS = the nops between initialization and target instructions
                # 3 = the 3 target instructions (TO BE CHANGED IF WE HAVE MORE RAND AROUND TARGET)
                # N_NOPS = the nops between the target instructions and the fault
                # 1 = the fault instruction
                # n_branch_nops = the nops between the jump and the target address
                target = hex(4*(2*9+N_NOPS+3+N_NOPS+1+n_branch_nops))
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, target)
            else:
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs)
            target_segment[2] = inst

        # Initialize registers used the three target instructions
        template_f.write("/*Initialize registers*/\n")
        regs_to_init = list(set(all_regs) - set(free_regs))

        # Initialize registers in instructions surrounding the target
        if(random_templates == "random"):
            regs_left, regs_to_init, instruction_position = init_pre_post_regs(target_segment, operands_pre, operands_post, regs_left, regs_to_init, template_f, PROCESSOR, instruction_position)

        # Initialize all leftover registers
        reg_num = -1
        for reg_num, reg in enumerate(regs_to_init):
            template_f.write(init_reg(reg, "random", 0)+"\n")
            instruction_position = instruction_position + 2

        # Pad with nops if the number of registers to be initialized is less than 9
        for pad_nops in range(reg_num+1, regs_left):
            template_f.write("addi x0, x0, 0\n")
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 2

        # Add nops between initialization and targets
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 1

        # Add targets
        template_f.write("/* Add target instructions */\n")
        # if random == random then add random instructions before
        # else just add the single instruction
        if(random_templates == "random"):
            for target_id, instruction in enumerate(target_segment):
                template_f.write(instruction+"\n")
                if(target_id == 0):
                    instruction_position = instruction_position + 1
        else:
            template_f.write(target_segment[1]+"\n")

        metadata_csv_f.write(TARGET_INSTRUCTION+",-,"+str(template)+","+str(instruction_position)+"\n");

        # Add nops between targets and fault
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")

        # Add fault
        template_f.write("ebreak\n")

        # If instruction after target is branch, then add code in case of branch taken
        # Add random number of nops
        if(random_templates == "random" and 
           (target_segment[0].split()[0][0] == 'b' or target_segment[0].split()[0][0] == 'j' or
            target_segment[2].split()[0][0] == 'b' or target_segment[2].split()[0][0] == 'j')):

            for nop in range(0, n_branch_nops):
                template_f.write("addi x0, x0, 0\n")

            # Add instruction after jump in case of jump taken 
            if(target_segment[0].split()[0] == "jalr" and target_segment[2].split()[0] == "jalr"):
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")
            else:
                template_f.write("label: addi x0, x0, 0\n")
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS-1):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")

        template_f.close()

def generate_branch(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, random_templates, metadata_csv_f):

    if(PROCESSOR=="picorv32"):
        N_TEMPLATES = N_TEMPLATES*2

    out_path = generate_folder(cwd, "asm/"+TARGET_INSTRUCTION)

    all_regs = []
    for reg in range(0, 32):
        all_regs.append(reg)

    for template in range(0, N_TEMPLATES):

        # First half of the templates it's a branch taken, second half not taken
        if(template < N_TEMPLATES // 2):
            BRANCH_OUTCOME = "taken"
        else:
            BRANCH_OUTCOME = "not_taken"

        n_branch_nops =random.randint(1,200)
        n_branch_nops_post = random.randint(1,20)
        instruction_position = 0;

        template_f = open(out_path + "/" + TARGET_INSTRUCTION + "_template_" + str(template) + '.s', 'w')

        target_segment = ["", "", ""]
        free_regs = all_regs.copy()
        if(random_templates == "random"):
            regs_left = 9
        else:
            regs_left = 3

        # Target instruction
        inst, free_regs, target_operands = generate_instruction(TARGET_INSTRUCTION, inst_type(TARGET_INSTRUCTION), free_regs)
        target_segment[1] = inst
        if(random_templates == "random"):
            # Random instruction before
            rand_instruction = rand_inst()
            inst, free_regs, operands_pre = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, 0, "label2")
            target_segment[0] = inst
            # Random instruction after
            rand_instruction = rand_inst("all")
            if(rand_instruction == "jalr"):
                # 2*9 = the 18 instructions to initialize the 9 registers for the target instructions
                # N_NOPS = the nops between initialization and target instructions
                # 3 = the 3 target instructions (TO BE CHANGED IF WE HAVE MORE RAND AROUND TARGET)
                # N_NOPS = the nops between the target instructions and the fault
                # 1 = the fault instruction
                # n_branch_nops = the nops between the jump and the target address
                # 1 = the post instruction in case of jump taken
                target = hex(4*(2*9+N_NOPS+3+N_NOPS+1+n_branch_nops+1+N_NOPS+1+n_branch_nops_post))
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, target)
            else:
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, 0, "label2")
            target_segment[2] = inst

        # Initialize registers used the three target instructions
        template_f.write("/*Initialize registers*/\n")
        regs_to_init = list(set(all_regs) - set(free_regs))

        if(random_templates == "random"):
            regs_left, regs_to_init, instruction_position = init_pre_post_regs(target_segment, operands_pre, operands_post, regs_left, regs_to_init, template_f, PROCESSOR, instruction_position)

        reg_val1, reg_val2 = get_branch_reg_vals(TARGET_INSTRUCTION, BRANCH_OUTCOME);

        template_f.write(init_reg(target_operands["rs1"], "fixed", reg_val1)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left-1
        regs_to_init.remove(target_operands["rs1"])
        template_f.write(init_reg(target_operands["rs2"], "fixed", reg_val2)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left-1
        if(regs_to_init.count(target_operands["rs2"])>0):
            regs_to_init.remove(target_operands["rs2"])

        # Initialize all leftover registers
        reg_num = -1
        for reg_num, reg in enumerate(regs_to_init):
            template_f.write(init_reg(reg, "random", 0)+"\n")
            instruction_position = instruction_position + 2

        # Pad with nops if the number of registers to be initialized is less than 9
        for pad_nops in range(reg_num+1, regs_left):
            template_f.write("addi x0, x0, 0\n")
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 2

        # Add nops between initialization and targets
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 1

        # Add targets
        template_f.write("/* Add target instructions */\n")
        if(random_templates == "random"):
            for target_id, instruction in enumerate(target_segment):
                template_f.write(instruction+"\n")
                if(target_id == 0):
                    instruction_position = instruction_position + 1
        else:
            template_f.write(target_segment[1]+"\n")

        # Write the metadata
        metadata_csv_f.write(TARGET_INSTRUCTION+","+BRANCH_OUTCOME+","+str(template)+","+str(instruction_position)+"\n");

        # Add nops between targets and fault
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")

        # Add fault (to be replaced with faulting opcode)
        template_f.write("ebreak\n")

        # If target instruction is branch, then add code in case of branch taken
        # Add random number of nops
        for nop in range(0, n_branch_nops):
            template_f.write("addi x0, x0, 0\n")
        if(random_templates == "random"):
            # Add instruction after jump in case of jump taken 
            template_f.write("label: "+target_segment[2]+"\n")
        else:
            template_f.write("label: addi x0, x0, 0\n")
        # Add nops between targets and fault
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")

        # Add fault
        template_f.write("ebreak\n")

        # If instruction after target is branch, then add code in case of branch taken
        # Add random number of nops
        if(random_templates == "random" and 
           (target_segment[0].split()[0][0] == 'b' or target_segment[0].split()[0][0] == 'j' or
            target_segment[2].split()[0][0] == 'b' or target_segment[2].split()[0][0] == 'j')):

            for nop in range(0, n_branch_nops_post):
                template_f.write("addi x0, x0, 0\n")

            # Add instruction after jump in case of jump taken 
            if(target_segment[0].split()[0] == "jalr" and target_segment[2].split()[0] == "jalr"):
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")
            else:
                template_f.write("label2: addi x0, x0, 0\n")
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS-1):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")

        template_f.close()

def generate_store(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, random_templates, metadata_csv_f):

    out_path = generate_folder(cwd, "asm/"+TARGET_INSTRUCTION)

    all_regs = []
    for reg in range(0, 32):
        all_regs.append(reg)

    for template in range(0, N_TEMPLATES):

        n_branch_nops = random.randint(1,20)
        instruction_position = 0;

        template_f = open(out_path + "/" + TARGET_INSTRUCTION + "_template_" + str(template) + '.s', 'w')

        target_segment = ["", "", ""]
        free_regs = all_regs.copy()
        if(random_templates == "random"):
            regs_left = 9
        else:
            regs_left = 3

        # Target instruction
        inst, free_regs, target_operands = generate_instruction(TARGET_INSTRUCTION, inst_type(TARGET_INSTRUCTION), free_regs)
        target_segment[1] = inst
        if(random_templates == "random"):
            # Random instruction before
            rand_instruction = rand_inst()
            inst, free_regs, operands_pre = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs)
            target_segment[0] = inst
            # Random instruction after
            rand_instruction = rand_inst("all")
            if(rand_instruction == "jalr"):
                # 2*9 = the 18 instructions to initialize the 9 registers for the target instructions
                # N_NOPS = the nops between initialization and target instructions
                # 3 = the 3 target instructions (TO BE CHANGED IF WE HAVE MORE RAND AROUND TARGET)
                # N_NOPS = the nops between the target instructions and the fault
                # 1 = the fault instruction
                # n_branch_nops = the nops between the jump and the target address
                target = hex(4*(2*9+N_NOPS+3+N_NOPS+1+n_branch_nops))
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, target)
            else:
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs)
            target_segment[2] = inst

        # Initialize registers used the three target instructions
        template_f.write("/*Initialize registers*/\n")
        regs_to_init = list(set(all_regs) - set(free_regs))

        if(random_templates == "random"):
            regs_left, regs_to_init, instruction_position = init_pre_post_regs(target_segment, operands_pre, operands_post, regs_left, regs_to_init, template_f, PROCESSOR, instruction_position)

        # Set top 16 bits of address reg to 0, and low 2 bits to 0
        if(PROCESSOR == "riscy"):
            address = generate_random_value(bits=14, exclude_zero=0)
            address = "0000000000000000"+address+"00"
        else:
            address = generate_random_value(bits=5, exclude_zero=1)
            address = "00000000000000000"+address+"0000000000"
        template_f.write(init_reg(target_operands["rs1"], "fixed", address)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left - 1
        regs_to_init.remove(target_operands["rs1"])

        # Initialize all leftover registers
        reg_num = -1
        for reg_num, reg in enumerate(regs_to_init):
            template_f.write(init_reg(reg, "random", 0)+"\n")
            instruction_position = instruction_position + 2

        # Pad with nops if the number of registers to be initialized is less than 9
        for pad_nops in range(reg_num+1, regs_left):
            template_f.write("addi x0, x0, 0\n")
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 2

        # Add nops between initialization and targets
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 1

        # Add targets
        template_f.write("/* Add target instructions */\n")
        if(random_templates == "random"):
            for target_id, instruction in enumerate(target_segment):
                template_f.write(instruction+"\n")
                if(target_id == 0):
                    instruction_position = instruction_position + 1
        else:
            template_f.write(target_segment[1]+"\n")

        # Write the metadata
        metadata_csv_f.write(TARGET_INSTRUCTION+",-,"+str(template)+","+str(instruction_position)+"\n");

        # Add nops between targets and fault
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")

        # Add fault
        template_f.write("ebreak\n")

        # If instruction after target is branch, then add code in case of branch taken
        # Add random number of nops
        if(random_templates == "random" and 
           (target_segment[0].split()[0][0] == 'b' or target_segment[0].split()[0][0] == 'j' or
            target_segment[2].split()[0][0] == 'b' or target_segment[2].split()[0][0] == 'j')):

            for nop in range(0, n_branch_nops):
                template_f.write("addi x0, x0, 0\n")

            # Add instruction after jump in case of jump taken 
            if(target_segment[0].split()[0] == "jalr" and target_segment[2].split()[0] == "jalr"):
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")
            else:
                template_f.write("label: addi x0, x0, 0\n")
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS-1):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")

        template_f.close()

def generate_load(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, random_templates, metadata_csv_f):

    out_path = generate_folder(cwd, "asm/"+TARGET_INSTRUCTION)

    all_regs = []
    for reg in range(0, 32):
        all_regs.append(reg)

    for template in range(0, N_TEMPLATES):

        n_branch_nops = random.randint(1,20)
        instruction_position = 0;

        template_f = open(out_path + "/" + TARGET_INSTRUCTION + "_template_" + str(template) + '.s', 'w')

        target_segment = ["", "", ""]
        free_regs = all_regs.copy()
        if(random_templates == "random"):
            regs_left = 10
        else:
            regs_left = 4

        # Target instruction
        inst, free_regs, target_operands = generate_instruction(TARGET_INSTRUCTION, inst_type(TARGET_INSTRUCTION), free_regs)
        target_segment[1] = inst
        if(random_templates == "random"):
            # Random instruction before
            rand_instruction = rand_inst()
            inst, free_regs, operands_pre = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs)
            target_segment[0] = inst
            # Random instruction after
            rand_instruction = rand_inst("all")
            if(rand_instruction == "jalr"):
                # 2*10 = the 20 instructions to initialize the 10 registers for the target instructions
                # 1 = the store instruction
                # N_NOPS = the nops between initialization and target instructions
                # 3 = the 3 target instructions (TO BE CHANGED IF WE HAVE MORE RAND AROUND TARGET)
                # N_NOPS = the nops between the target instructions and the fault
                # 1 = the fault instruction
                # n_branch_nops = the nops between the jump and the target address
                target = hex(4*(2*10+N_NOPS+3+N_NOPS+1+n_branch_nops))
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, target)
            else:
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs)
            target_segment[2] = inst

        # Store, to init the memory where the load will go
        store, free_regs, store_operands = generate_instruction("sw", "S", free_regs)

        # Initialize registers used the three target instructions
        template_f.write("/*Initialize registers*/\n")
        regs_to_init = list(set(all_regs) - set(free_regs))
        # 2 reg for store, 2 for load, and 2x3 regs for random instructions around
        if(random_templates == "random"):
            regs_left, regs_to_init, instruction_position = init_pre_post_regs(target_segment, operands_pre, operands_post, regs_left, regs_to_init, template_f, PROCESSOR, instruction_position)

        # Set top 16 bits of address reg to 0, and low 2 bits to 0
        if(PROCESSOR == "riscy"):
            address = generate_random_value(bits=14, exclude_zero=0)
            address = "0000000000000000"+address+"00"
        else:
            address = generate_random_value(bits=5, exclude_zero=1)
            address = "00000000000000000"+address+"0000000000"
        # Init the load address register
        template_f.write(init_reg(target_operands["rs1"], "fixed", address)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left-1
        regs_to_init.remove(target_operands["rs1"])
        # Init the store address register
        template_f.write(init_reg(store_operands["rs1"], "fixed", address)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left-1
        if(regs_to_init.count(store_operands["rs1"])>0):
            regs_to_init.remove(store_operands["rs1"])

        # Initialize all leftover registers
        reg_num = -1
        for reg_num, reg in enumerate(regs_to_init):
            template_f.write(init_reg(reg, "random", 0)+"\n")
            instruction_position = instruction_position + 2

        # Pad with nops if the number of registers to be initialized is less than 9
        for pad_nops in range(reg_num+1, regs_left):
            template_f.write("addi x0, x0, 0\n")
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 2

        # Execute initialization store
        template_f.write("/* Add store */\n")
        template_f.write(store+"\n")
        instruction_position = instruction_position + 1

        # Add nops between initialization and targets
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 1

        # Add targets
        template_f.write("/* Add target instructions */\n")
        if(random_templates == "random"):
            for target_id, instruction in enumerate(target_segment):
                template_f.write(instruction+"\n")
                if(target_id == 0):
                    instruction_position = instruction_position + 1
        else:
            template_f.write(target_segment[1]+"\n")

        # Write the metadata
        metadata_csv_f.write(TARGET_INSTRUCTION+",-,"+str(template)+","+str(instruction_position)+"\n");

        # Add nops between targets and fault
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")

        # Add fault
        template_f.write("ebreak\n")

        # If instruction after target is branch, then add code in case of branch taken
        # Add random number of nops
        if(random_templates == "random" and 
           (target_segment[0].split()[0][0] == 'b' or target_segment[0].split()[0][0] == 'j' or
            target_segment[2].split()[0][0] == 'b' or target_segment[2].split()[0][0] == 'j')):

            for nop in range(0, n_branch_nops):
                template_f.write("addi x0, x0, 0\n")

            # Add instruction after jump in case of jump taken 
            if(target_segment[0].split()[0] == "jalr" and target_segment[2].split()[0] == "jalr"):
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")
            else:
                template_f.write("label: addi x0, x0, 0\n")
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS-1):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")

def generate_jump(cwd, TARGET_INSTRUCTION, N_TEMPLATES, N_NOPS, PROCESSOR, random_templates, metadata_csv_f):

    out_path = generate_folder(cwd, "asm/"+TARGET_INSTRUCTION)

    all_regs = []
    for reg in range(0, 32):
        all_regs.append(reg)

    for template in range(0, N_TEMPLATES):

        n_jump_nops =random.randint(1,200)
        n_branch_nops_post = random.randint(1,20)
        instruction_position = 0;

        template_f = open(out_path + "/" + TARGET_INSTRUCTION + "_template_" + str(template) + '.s', 'w')

        target_segment = ["", "", ""]
        free_regs = all_regs.copy()
        if(random_templates == "random"):
            regs_left = 9
        else:
            regs_left = 3

        # Target instruction
        if(TARGET_INSTRUCTION=="jalr"):
            # Calculate jump target offset
            if(random_templates == "random"):
                # 2*9 = the 18 instructions to initialize the 9 registers for the target instructions
                # N_NOPS = the nops between initialization and target instructions
                # 3 = the 3 target instructions (TO BE CHANGED IF WE HAVE MORE RAND AROUND TARGET)
                # N_NOPS = the nops between the target instructions and the fault
                # 1 = the fault instruction
                # n_jump_nops = the nops between the jump and the target address
                target = hex(4*(2*9+N_NOPS+3+N_NOPS+1+n_jump_nops))
            else:
                # 2*3 = the 9 instructions to initialize the 3 registers for the target instructions
                # N_NOPS = the nops between initialization and target instructions
                # 1 = the 1 target instructions (TO BE CHANGED IF WE HAVE MORE RAND AROUND TARGET)
                # N_NOPS = the nops between the target instructions and the fault
                # 1 = the fault instruction
                # n_jump_nops = the nops between the jump and the target address
                target = hex(4*(2*3+N_NOPS+1+N_NOPS+1+n_jump_nops))
            inst, free_regs, target_operands = generate_instruction(TARGET_INSTRUCTION, inst_type(TARGET_INSTRUCTION), free_regs, target)
        else:
            inst, free_regs, target_operands = generate_instruction(TARGET_INSTRUCTION, inst_type(TARGET_INSTRUCTION), free_regs)
        target_segment[1] = inst

        if(random_templates == "random"):
            # Random instruction before
            rand_instruction = rand_inst()
            inst, free_regs, operands_pre = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, 0, "label2")
            target_segment[0] = inst
            # Random instruction after
            rand_instruction = rand_inst("all")
            if(rand_instruction == "jalr"):
                # 2*9 = the 18 instructions to initialize the 9 registers for the target instructions
                # N_NOPS = the nops between initialization and target instructions
                # 3 = the 3 target instructions (TO BE CHANGED IF WE HAVE MORE RAND AROUND TARGET)
                # N_NOPS = the nops between the target instructions and the fault
                # 1 = the fault instruction
                # n_branch_nops = the nops between the jump and the target address
                # 1 = the post instruction in case of jump taken
                target = hex(4*(2*9+N_NOPS+3+N_NOPS+1+n_jump_nops+1+N_NOPS+1+n_branch_nops_post))
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, target)
            else:
                inst, free_regs, operands_post = generate_instruction(rand_instruction, inst_type(rand_instruction), free_regs, 0, "label2")
            target_segment[2] = inst

        # Initialize registers used the three target instructions
        template_f.write("/*Initialize registers*/\n")
        regs_to_init = list(set(all_regs) - set(free_regs))

        if(random_templates == "random"):
            regs_left, regs_to_init, instruction_position = init_pre_post_regs(target_segment, operands_pre, operands_post, regs_left, regs_to_init, template_f, PROCESSOR, instruction_position)

        if(TARGET_INSTRUCTION=="jalr"):
            if(PROCESSOR == "riscy"):
                code_offset = '{0:032b}'.format(0xffff8000)
            else:
                code_offset = '{0:032b}'.format(0x00000000)
            template_f.write(init_reg(target_operands["rs1"], "fixed", code_offset)+"\n")
            instruction_position = instruction_position + 2
            regs_left = regs_left-1
            regs_to_init.remove(target_operands["rs1"])

        # Initialize all leftover registers
        reg_num = -1
        for reg_num, reg in enumerate(regs_to_init):
            template_f.write(init_reg(reg, "random", 0)+"\n")
            instruction_position = instruction_position + 2

        # Pad with nops if the number of registers to be initialized is less than 9
        for pad_nops in range(reg_num+1, regs_left):
            template_f.write("addi x0, x0, 0\n")
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 2

        # Add nops between initialization and targets
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")
            instruction_position = instruction_position + 1

        # Add targets
        template_f.write("/* Add target instructions */\n")
        if(random_templates == "random"):
            for target_id, instruction in enumerate(target_segment):
                template_f.write(instruction+"\n")
                if(target_id == 0):
                    instruction_position = instruction_position + 1
        else:
            template_f.write(target_segment[1]+"\n")

        # Write the metadata
        metadata_csv_f.write(TARGET_INSTRUCTION+",-,"+str(template)+","+str(instruction_position)+"\n");

        # Add nops between targets and fault
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")

        # Add fault (to be replaced with faulting opcode)
        template_f.write("ebreak\n")

        # Add random number of nops
        for nop in range(0, n_jump_nops):
            template_f.write("addi x0, x0, 0\n")
        if(random_templates == "random"):
            # Add instruction after jump in case of jump taken 
            if(TARGET_INSTRUCTION=='jal'):
                template_f.write("label: "+target_segment[2]+"\n")
            else:
                template_f.write(target_segment[2]+"\n")
        else:
            if(TARGET_INSTRUCTION=='jal'):
                template_f.write("label: addi x0, x0, 0\n")
        # Add nops between targets and fault
        template_f.write("/* Add nops */\n")
        for nop in range(0, N_NOPS):
            template_f.write("addi x0, x0, 0\n")

        # Add fault
        template_f.write("ebreak\n")

        # If instruction after target is branch, then add code in case of branch taken
        # Add random number of nops
        if(random_templates == "random" and 
           (target_segment[0].split()[0][0] == 'b' or target_segment[0].split()[0][0] == 'j' or
            target_segment[2].split()[0][0] == 'b' or target_segment[2].split()[0][0] == 'j')):

            for nop in range(0, n_branch_nops_post):
                template_f.write("addi x0, x0, 0\n")

            # Add instruction after jump in case of jump taken 
            if(target_segment[0].split()[0] == "jalr" and target_segment[2].split()[0] == "jalr"):
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")
            else:
                template_f.write("label2: addi x0, x0, 0\n")
                template_f.write("/* Add nops */\n")
                for nop in range(0, N_NOPS-1):
                    template_f.write("addi x0, x0, 0\n")
                template_f.write("ebreak\n")

def get_branch_reg_vals(TARGET_INSTRUCTION, BRANCH_OUTCOME):

    if(TARGET_INSTRUCTION=="beq"):
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = reg_val2 = generate_random_value(bits=32, exclude_zero=0)
        else:
            reg_val1 = reg_val2 = generate_random_value(bits=32, exclude_zero=0)
            while (int(reg_val1, 2) == int(reg_val2, 2)):
                reg_val2 = generate_random_value(bits=32, exclude_zero=0)
    elif(TARGET_INSTRUCTION=="bne"):
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = reg_val2 = generate_random_value(bits=32, exclude_zero=0)
            while (int(reg_val1, 2) == int(reg_val2, 2)):
                reg_val2 = generate_random_value(bits=32, exclude_zero=0)
        else:
            reg_val1 = reg_val2 = generate_random_value(bits=32, exclude_zero=0)
    # Signed comparison
    elif(TARGET_INSTRUCTION=="blt"):
        smaller = larger = 0
        while (smaller==larger):
            smaller, larger = sorted(random.sample(range(-(2**31)+1, (2**31)-1), 2))
        if(BRANCH_OUTCOME=="taken"):
            # and with 0xffffffff because it's signed so two's compliment
            reg_val1 = '{0:032b}'.format(smaller & 0xffffffff)
            reg_val2 = '{0:032b}'.format(larger & 0xffffffff)
        else:
            reg_val1 = '{0:032b}'.format(larger & 0xffffffff)
            reg_val2 = '{0:032b}'.format(smaller & 0xffffffff)
    elif(TARGET_INSTRUCTION=="bltu"):
        smaller = larger = 0
        while (smaller==larger):
            smaller, larger = sorted(random.sample(range(0, (2**32)-1), 2))
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = '{0:032b}'.format(smaller)
            reg_val2 = '{0:032b}'.format(larger)
        else:
            reg_val1 = '{0:032b}'.format(larger)
            reg_val2 = '{0:032b}'.format(smaller)
    # Signed comparison
    elif(TARGET_INSTRUCTION=="bge"):
        smaller = larger = 0
        while (smaller==larger):
            smaller, larger = sorted(random.sample(range(-(2**31)+1, (2**31)-1), 2))
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = '{0:032b}'.format(larger & 0xffffffff)
            reg_val2 = '{0:032b}'.format(smaller & 0xffffffff)
        else:
            reg_val1 = '{0:032b}'.format(smaller & 0xffffffff)
            reg_val2 = '{0:032b}'.format(larger & 0xffffffff)
    elif(TARGET_INSTRUCTION=="bgeu"):
        smaller = larger = 0
        while (smaller==larger):
            smaller, larger = sorted(random.sample(range(0, (2**32)-1), 2))
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = '{0:032b}'.format(larger)
            reg_val2 = '{0:032b}'.format(smaller)
        else:
            reg_val1 = '{0:032b}'.format(smaller)
            reg_val2 = '{0:032b}'.format(larger)

    return reg_val1, reg_val2

def init_pre_post_regs(target_segment, operands_pre, operands_post, regs_left, regs_to_init, template_f, PROCESSOR, instruction_position):

    if(target_segment[0].split()[0][0] == 'b'):

        reg_val1, reg_val2 = get_branch_reg_vals(target_segment[0].split()[0], "not_taken");

        template_f.write(init_reg(operands_pre["rs1"], "fixed", reg_val1)+"\n")
        regs_left = regs_left-1
        instruction_position = instruction_position + 2
        regs_to_init.remove(operands_pre["rs1"])
        template_f.write(init_reg(operands_pre["rs2"], "fixed", reg_val2)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left-1
        if(regs_to_init.count(operands_pre["rs2"])>0):
            regs_to_init.remove(operands_pre["rs2"])

    elif(target_segment[0].split()[0] == "sw" or target_segment[0].split()[0] == "sh" or 
         target_segment[0].split()[0] == "sb" or target_segment[0].split()[0] == "lw" or 
         target_segment[0].split()[0] == "lh" or target_segment[0].split()[0] == "lb" or 
         target_segment[0].split()[0] == "lhu" or target_segment[0].split()[0] == "lbu"):

        # Set top 16 bits of address reg to 0, and low 2 bits to 0
        if(PROCESSOR == "riscy"):
            address = generate_random_value(bits=14, exclude_zero=0)
            address = "0000000000000000"+address+"00"
        else:
            address = generate_random_value(bits=5, exclude_zero=1)
            address = "00000000000000000"+address+"0000000000"
        template_f.write(init_reg(operands_pre["rs1"], "fixed", address)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left - 1
        regs_to_init.remove(operands_pre["rs1"])

    if(target_segment[2].split()[0][0] == 'b'):

        reg_val1, reg_val2 = get_branch_reg_vals(target_segment[2].split()[0], random.choice(["not_taken", "taken"]));

        template_f.write(init_reg(operands_post["rs1"], "fixed", reg_val1)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left-1
        regs_to_init.remove(operands_post["rs1"])
        template_f.write(init_reg(operands_post["rs2"], "fixed", reg_val2)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left-1
        if(regs_to_init.count(operands_post["rs2"])>0):
            regs_to_init.remove(operands_post["rs2"])

    elif(target_segment[2].split()[0] == "jalr"):

        if(PROCESSOR == "riscy"):
            code_offset = '{0:032b}'.format(0xffff8000)
        else:
            code_offset = '{0:032b}'.format(0x00000000)
        template_f.write(init_reg(operands_post["rs1"], "fixed", code_offset)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left-1
        regs_to_init.remove(operands_post["rs1"])

    elif(target_segment[2].split()[0] == "sw" or target_segment[2].split()[0] == "sh" or 
         target_segment[2].split()[0] == "sb" or target_segment[2].split()[0] == "lw" or 
         target_segment[2].split()[0] == "lh" or target_segment[2].split()[0] == "lb" or 
         target_segment[2].split()[0] == "lhu" or target_segment[2].split()[0] == "lbu"):

        # Set top 16 bits of address reg to 0, and low 2 bits to 0
        if(PROCESSOR == "riscy"):
            address = generate_random_value(bits=14, exclude_zero=0)
            address = "0000000000000000"+address+"00"
        else:
            address = generate_random_value(bits=5, exclude_zero=1)
            address = "00000000000000000"+address+"0000000000"

        template_f.write(init_reg(operands_post["rs1"], "fixed", address)+"\n")
        instruction_position = instruction_position + 2
        regs_left = regs_left - 1
        regs_to_init.remove(operands_post["rs1"])

    return regs_left, regs_to_init, instruction_position
