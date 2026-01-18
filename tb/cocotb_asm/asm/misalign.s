.text
.global _start, trap_handler, misaligned
_start:
li x3, 0x400
la x1, trap_handler
csrrw x0, mtvec, x1
la x1, misaligned
jalr x2, x1, 3
la x1, misaligned
ld x2, 1(x1)
sd x1, 1(x1)
li x31, 0x2
ebreak

trap_handler:
csrrs x4, mcause, x0
sd x4, 0(x3)
addi x3, x3, 8
csrrs x4, mepc, x0
addi x4, x4, 4
csrrw x0, mepc, x4
mret

misaligned:
.align 8
li x31, 0x1
ebreak
