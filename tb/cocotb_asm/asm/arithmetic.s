li x1, 0
li x2, 0
li x3, 0
li x4, 0
li x5, 0
li x6, 0
li x7, 0
li x8, 0
li x9, 0
li x10, 0
# sltu should set this to 0
li x11, 0xff
li x12, 0

li x21, 0x64
li x22, 0x32
lui x23, 0xcba00
lui x24, 0xfed00
li x25, 0x4
li x26, 0x3
lui x27, 0xbeef0

add x1, x21, x22 # 0x96
sub x2, x22, x21 # 0xffffffce
xor x3, x21, x22 # 0x56
or x4, x21, x22  # 0x76
and x5, x21, x22 # 0x20
sll x6, x23, x25 # 0xba000000
srl x7, x27, x26 # 0x17dde000
sra x8, x27, x26 # 0xf7dde000
slt x9, x23, x21 # 0x1
slt x10, x22, x21 # 0x1
sltu x11, x23, x21 # 0x0
sltu x12, x22, x21 # 0x1
ebreak
