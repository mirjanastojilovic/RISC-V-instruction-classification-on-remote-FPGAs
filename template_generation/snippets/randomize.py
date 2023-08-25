# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

import random
import os
import sys
import binascii

def get_branch_reg_vals(TARGET_INSTRUCTION, BRANCH_OUTCOME):

    if(TARGET_INSTRUCTION=="beq"):
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = reg_val2 = binascii.hexlify(os.urandom(4)).decode() 
        else:
            reg_val1 = reg_val2 = binascii.hexlify(os.urandom(4)).decode()
            while (int(reg_val1, 2) == int(reg_val2, 2)):
                reg_val2 = binascii.hexlify(os.urandom(4)).decode()
    elif(TARGET_INSTRUCTION=="bne"):
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = reg_val2 = binascii.hexlify(os.urandom(4)).decode()
            while (int(reg_val1, 2) == int(reg_val2, 2)):
                reg_val2 = binascii.hexlify(os.urandom(4)).decode()
        else:
            reg_val1 = reg_val2 = binascii.hexlify(os.urandom(4)).decode()
    # Signed comparison
    elif(TARGET_INSTRUCTION=="blt"):
        smaller = larger = 0
        while (smaller==larger):
            smaller, larger = sorted(random.sample(range(-(2**31)+1, (2**31)-1), 2))
        if(BRANCH_OUTCOME=="taken"):
            # and with 0xffffffff because it's signed so two's compliment
            reg_val1 = '{0:08X}'.format(smaller & 0xffffffff)
            reg_val2 = '{0:08X}'.format(larger & 0xffffffff)
        else:
            reg_val1 = '{0:08X}'.format(larger & 0xffffffff)
            reg_val2 = '{0:08X}'.format(smaller & 0xffffffff)
    elif(TARGET_INSTRUCTION=="bltu"):
        smaller = larger = 0
        while (smaller==larger):
            smaller, larger = sorted(random.sample(range(0, (2**32)-1), 2))
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = '{0:08X}'.format(smaller)
            reg_val2 = '{0:08X}'.format(larger)
        else:
            reg_val1 = '{0:08X}'.format(larger)
            reg_val2 = '{0:08X}'.format(smaller)
    # Signed comparison
    elif(TARGET_INSTRUCTION=="bge"):
        smaller = larger = 0
        while (smaller==larger):
            smaller, larger = sorted(random.sample(range(-(2**31)+1, (2**31)-1), 2))
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = '{0:08X}'.format(larger & 0xffffffff)
            reg_val2 = '{0:08X}'.format(smaller & 0xffffffff)
        else:
            reg_val1 = '{0:08X}'.format(smaller & 0xffffffff)
            reg_val2 = '{0:08X}'.format(larger & 0xffffffff)
    elif(TARGET_INSTRUCTION=="bgeu"):
        smaller = larger = 0
        while (smaller==larger):
            smaller, larger = sorted(random.sample(range(0, (2**32)-1), 2))
        if(BRANCH_OUTCOME=="taken"):
            reg_val1 = '{0:08X}'.format(larger)
            reg_val2 = '{0:08X}'.format(smaller)
        else:
            reg_val1 = '{0:08X}'.format(smaller)
            reg_val2 = '{0:08X}'.format(larger)

    return reg_val1, reg_val2

templates = ['arith', 'logic', 'cmp', 'shift', 'load', 'store', 'branch', 'jal']
branch_special = [3, 4, 6, 7, 8, 11, 12, 16, 20, 21, 22, 26] 
load_special = [2, 12, 16, 20, 28]
store_special = [10, 12, 20, 24, 25]

if(len(sys.argv) < 2):
    print("Usage: python3 generate_templates.py <number of templates>")
    exit()

N_TEMPLATES = int(sys.argv[1])

all_regs = []
for reg in range(1, 31):
    all_regs.append(reg)

# Create output file
path = "templates"
if(not os.path.exists(path)):
    os.makedirs(path)

metadata_f = open('templates/metadata_in_order.csv', 'w')
metadata_f.write('instruction,info,template_id,asm_line,hex\n')

for instruction in templates:
    # Load the base template file
    with open('out_temp/'+instruction+'.txt', 'r') as file:
        base_template = file.read()

    # Create output file
    path = "templates/"+instruction
    if(not os.path.exists(path)):
        os.makedirs(path)

    for template_id in range(0, N_TEMPLATES):

        metadata_f.write(instruction+',-,'+str(template_id)+',0,0xffffffff\n')

        # Copy original hex file
        template_new = (base_template + '.')[:-1]

        regs = all_regs.copy()

        # Remove special registers from initialization
        if(instruction == 'branch'):
            for reg in branch_special:
                regs.remove(reg)
        if(instruction == 'load'):
            for reg in load_special:
                regs.remove(reg)
        if(instruction == 'store'):
            for reg in store_special:
                regs.remove(reg)

        # Randomize each register
        for i in regs:
            # Find location to replace with random value
            strHex = "FFFF%0.4X" % i
            # Generate random value
            random_val = binascii.hexlify(os.urandom(4)).decode()
            # Replace
            template_new = template_new.replace(strHex, random_val)

        # Initialize the remaining registers
        if(instruction == 'load'):
            for reg in load_special:
                strHex = "FFFF%0.4X" % reg
                rand_addr = random.randrange(115,150)
                random_val = "%0.8X" % (rand_addr*4)
                template_new = template_new.replace(strHex, random_val)
                # Also initialize the chosen memory region
                dest = (31 + rand_addr - 115)
                strHex = "FFFF%0.4X" % dest
                random_val = binascii.hexlify(os.urandom(4)).decode()
                template_new = template_new.replace(strHex, random_val)
        if(instruction == 'store'):
            for reg in store_special:
                strHex = "FFFF%0.4X" % reg
                rand_addr = random.randrange(115,150)
                random_val = "%0.8X" % (rand_addr*4)
                template_new = template_new.replace(strHex, random_val)
        if(instruction == 'branch'):
            x16, x4 = get_branch_reg_vals("bge", "taken")
            # Find location to replace with value
            strHex = "FFFF%0.4X" % 16
            template_new = template_new.replace(strHex, x16)
            strHex = "FFFF%0.4X" % 4
            template_new = template_new.replace(strHex, x4)

            x26, x12 = get_branch_reg_vals("bltu", "not_taken")
            # Find location to replace with value
            strHex = "FFFF%0.4X" % 26
            template_new = template_new.replace(strHex, x26)
            strHex = "FFFF%0.4X" % 12
            template_new = template_new.replace(strHex, x12)

            x11, x3 = get_branch_reg_vals("bltu", "taken")
            # Find location to replace with value
            strHex = "FFFF%0.4X" % 11
            template_new = template_new.replace(strHex, x11)
            strHex = "FFFF%0.4X" % 3
            template_new = template_new.replace(strHex, x3)

            x6, x8 = get_branch_reg_vals("blt", "taken")
            # Find location to replace with value
            strHex = "FFFF%0.4X" % 6
            template_new = template_new.replace(strHex, x6)
            strHex = "FFFF%0.4X" % 8
            template_new = template_new.replace(strHex, x8)

            x7, x22 = get_branch_reg_vals("beq", "taken")
            # Find location to replace with value
            strHex = "FFFF%0.4X" % 7
            template_new = template_new.replace(strHex, x7)
            strHex = "FFFF%0.4X" % 22
            template_new = template_new.replace(strHex, x22)

            x20, x21 = get_branch_reg_vals("bne", "not_taken")
            # Find location to replace with value
            strHex = "FFFF%0.4X" % 20
            template_new = template_new.replace(strHex, x20)
            strHex = "FFFF%0.4X" % 21
            template_new = template_new.replace(strHex, x21)

        template_f = open(path+"/"+instruction+"_template_"+str(template_id)+".txt", 'w')
        template_f.write(template_new)
        template_f.close()

