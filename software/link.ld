OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
  RAM (rwx) : ORIGIN = 0x10000000, LENGTH = 16K
}

SECTIONS
{
  .text : ALIGN(4)
  {
    KEEP(*(.text.start))
    *(.text*)
    *(.rodata*)
  } > ROM

  .data : ALIGN(4)
  {
    __data_start = .;
    *(.data*)
    __data_end = .;
  } > RAM AT > ROM

  __data_load_start = LOADADDR(.data);

  .bss : ALIGN(4)
  {
    __bss_start = .;
    *(.bss*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  . = ALIGN(16);
  __stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
