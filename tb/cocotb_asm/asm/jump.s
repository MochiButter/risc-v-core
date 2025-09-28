start:
# set all relevant regs to 0
addi x6, x0, 0x0
addi x7, x0, 0x0
addi x8, x0, 0x0
addi x9, x0, 0x0
addi x10, x0, 0x0
addi x11, x0, 0x0
# go down 2 words
jal x1, target
addi x6, x0, 0x01
target:
# these two should run
addi x7, x0, 0x02
addi x8, x0, 0x04
# go down 3 words
jalr x2, x0, 0x34
addi x9, x0, 0x08
addi x10, x0, 0x16
# this should run
addi x11, x0, 0x32
# regs 7, 8, and 11 should be non-zero
ebreak
