.text
.global _start
_start:
# set x1 to deadbeef
li x1, 0xdeadbeef

sw x1, 48(x0)

sh x1, 56(x0)
sh x1, 66(x0)

sb x1, 72(x0)
sb x1, 81(x0)
sb x1, 90(x0)
sb x1, 99(x0)

ebreak
