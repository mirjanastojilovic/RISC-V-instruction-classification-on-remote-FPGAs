#!/usr/bin/env python3
# coding: utf-8
# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.


import telegram_send
import sys

def parse_log (args = "vivado.log"):

    key_word = ("CRITICAL WARNING", "ERROR")
    return_val = 0 
    
    try:
        with open(args, 'r') as f:
            for line in f:
                for key in key_word:
                    if key in line:
                        print(line.strip())
                        return_val = -1
	
    except FileNotFoundError:
        print ("Log file not found")

    return (return_val)

if(len(sys.argv)!=2):
    print("Incorrect usage!")
    print("./telegram_bot log_file.txt")
    exit()

run_id = sys.argv[1].split('.')[0]

print("\n\n\n**************************************************************************************************************")
print("LAUNCHING TELEGRAM BOT ON FILE : "+sys.argv[1])
print("**************************************************************************************************************")
print("\nLOG SUMMARY:\n")


if(parse_log(sys.argv[1]) == -1):
    telegram_send.send(messages=["Finished "+run_id+" build with ERROR"])
else:
    telegram_send.send(messages=["Finished "+run_id+" build SUCCESSFULLY"])

