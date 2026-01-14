.text
.global _start
_start:
li x3, 0
li x4, 0
li x5, 0
li x6, 0
li x1, 42
li x2, -42
blt x2, x1, lessthan
li x3, 0x1
lessthan:
li x4, 0x2
bltu x2, x1, lessthanu
li x5, 0x3
lessthanu:
li x6, 0x4
ebreak
