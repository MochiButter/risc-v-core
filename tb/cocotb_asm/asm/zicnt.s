.text
.global _start
_start:
csrw mcountinhibit, 0b100
csrw minstret, 16
csrw mcycle, 16
nop
nop
nop
nop
nop
csrw mcountinhibit, 0b001
csrrwi x1, minstret, 16
csrrwi x2, mcycle, 16
nop
nop
nop
nop
nop
csrr x3, minstret
csrr x4, mcycle
ebreak
