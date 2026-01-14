.text
.global _start
_start:
li x1, 0x100000000
li x2, 0xdeadbeef
li x3, 0x200000001
li x4, 0x1
addw x5, x1, x2
subw x6, x3, x1
subw x7, x1, x4
sd x3, 0x60(x0)
ld x8, 0x60(x0)
sd x8, 0x68(x0)
ebreak
