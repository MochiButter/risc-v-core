.text
.global _start
_start:
la x3, trap_handler
la x4, illegal
csrrw x0, mtvec, x3

main:
li x5, 0xdead
.global illegal
illegal:
.word 0x87654321
li x6, 0xbeef
ebreak

.global trap_handler
trap_handler:
csrrc x7, mepc, x0
csrrc x8, mcause, x0
csrrc x9, mtval, x0
addi x10, x7, 4
csrrw x0, mepc, x10
mret
