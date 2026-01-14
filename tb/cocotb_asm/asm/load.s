.text
.global _start

_start:
  la x1, var
  lw x2, 0(x1)
  lb x3, 0(x1)
  lb x4, 3(x1)
  lh x5, 0(x1)
  lh x6, 2(x1)
  lbu x7, 3(x1)
  lhu x8, 2(x1)
  ebreak

.section .rodata
  .align 8
  var: .word 0x87654321
