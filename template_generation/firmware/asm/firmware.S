.section .init
.global main

/* set stack pointer */

/* call main */
addi a0,zero,25
addi a1,zero,16
sub  a2, a0, a1
addi s3, zero, 256
sw   a2, 0(s3)
addi a0,a0,25
addi a1,a1,16
lw   s5, 0(s3)
addi a0,a0,25
addi a1,a1,16

/* break */
ebreak
