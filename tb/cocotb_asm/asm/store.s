# set x1 to deadbeef
li x1, 0xdeadbeef

sw x1, 36(x0)

sh x1, 40(x0)
sh x1, 46(x0)

sb x1, 48(x0)
sb x1, 53(x0)
sb x1, 58(x0)
sb x1, 63(x0)

ebreak
