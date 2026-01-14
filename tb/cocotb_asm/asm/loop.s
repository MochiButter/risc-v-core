.text
.global _start
_start:
addi x1, x0, 0x42
addi x2, x0, 0x64
li x3, 0xdeadbeef
loop:
blt x2, x1, target
addi x1, x1, 0x10
jal x0, loop
target:
sw x3, 0x38(x0)
ebreak
