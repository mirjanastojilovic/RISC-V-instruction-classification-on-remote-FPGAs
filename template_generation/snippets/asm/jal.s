lw x1, 340(x0)
lw x2, 344(x0)
lw x3, 348(x0)
lw x4, 352(x0)
lw x5, 356(x0)
lw x6, 360(x0)
lw x7, 364(x0)
lw x8, 368(x0)
lw x9, 372(x0)
lw x10, 376(x0)
lw x11, 380(x0)
lw x12, 384(x0)
lw x13, 388(x0)
lw x14, 392(x0)
lw x15, 396(x0)
lw x16, 400(x0)
lw x17, 404(x0)
lw x18, 408(x0)
lw x19, 412(x0)
lw x20, 416(x0)
lw x21, 420(x0)
lw x22, 424(x0)
lw x23, 428(x0)
lw x24, 432(x0)
lw x25, 436(x0)
lw x26, 440(x0)
lw x27, 444(x0)
lw x28, 448(x0)
lw x29, 452(x0)
lw x30, 456(x0)
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
label1: jal x17, label4
label2: and x16, x10, x26
or x16, x26, x26
label3: jal x27, label5
label4: jal x18, label6
label5: jal x18, label7
label6: add x15, x28, x5
jal x8, label2
label7: xor x9, x27, x28
label8: srl x24, x4, x30
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
ebreak

