csrrwi x1, mtvec, 0b10111
csrrs  x2, mtvec, x0
csrrwi x3, mscratch, 0b10101
csrrwi x3, mscratch, 0b01010
nop
nop
li x5, 0x30
csrrw x0, mtvec, x5
ecall
ebreak
nop
nop
csrrs x4, mcause, x0
csrrs x5, mepc, x0
addi x6, x5, 4
csrrw x31, mepc, x6
mret
