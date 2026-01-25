.text
.global _start
_start:
addi x2, x0, 0x42
addi x1, x0, 0
sd x2, 48(x0)
ebreak
