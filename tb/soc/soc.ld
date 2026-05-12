OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
  rom (rxa) : ORIGIN = 0x80000000, LENGTH = 64K
  ram (wxa) : ORIGIN = 0x80000000 + 64K, LENGTH = 32K
}

SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) } >rom AT>rom
  .text : { *(.text*) } >rom AT>rom
  .data : { *(.data*) } >ram AT>rom
  .bss : {*(.bss*)} >ram AT>rom
  .stack : {
    . = ALIGN(0x10);
    _stack_top = .;
    . += 4K;
    _stack_bottom = .;
  } >ram AT>ram
  _end = .;
}
