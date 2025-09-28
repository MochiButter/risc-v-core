# assumes tb sets datamem to something
li x1, 0x30
lw x2, 0(x1)
lb x3, 0(x1)
lb x4, 3(x1)
lh x5, 0(x1)
lh x6, 2(x1)
lbu x7, 3(x1)
lhu x8, 2(x1)
ebreak
