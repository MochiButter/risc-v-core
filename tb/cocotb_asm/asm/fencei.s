.text
.global _start, after_fence, load_inst
_start:
la x1, load_inst
la x2, after_fence
lw x1, 0(x1)
sw x1, 0(x2)
fence.i
after_fence:
# overwrite this nop with load_inst
# will only execute the new inst
# after flushing the pipeline
nop
ebreak

.section .rodata
.align 8
load_inst:
addi x1, x0, 0x42
