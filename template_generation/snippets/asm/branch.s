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
bge x16, x4, label1
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
label1: bltu x26, x12, label2
add x2, x23, x11
label2: bltu x11, x3, label3
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
label3: blt x6, x8, label4
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
label4: beq x7, x22, label5
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
label5: bne x20, x21, label6
addi x0, x0, 0
addi x0, x0, 0
label6: addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
ebreak
