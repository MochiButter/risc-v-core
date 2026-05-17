.equ RTC_ADDR,   0x2000bff8
.equ TIMER_BASE, 0x20004000

.text
.global _start, trap_handler
_start:
li x1, RTC_ADDR
ld x2, 0(x1)
li x1, TIMER_BASE
li x3, 100
add x2, x2, x3
sd x2, 0(x1)
ebreak

trap_handler:

