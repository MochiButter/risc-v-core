.text
.global _start
_start:
li x1, 0xdeadbeef
la x2, store_here

sw x1,  0(x2)

sh x1,  8(x2)
sh x1, 18(x2)

sb x1, 24(x2)
sb x1, 33(x2)
sb x1, 42(x2)
sb x1, 51(x2)

ebreak

.data
.align 8
store_here:
