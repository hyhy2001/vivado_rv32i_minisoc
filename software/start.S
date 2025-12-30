  .section .text.start
  .globl _start
_start:
  la sp, __stack_top

  // copy .data from ROM (LMA) to RAM (VMA)
  la t0, __data_load_start
  la t1, __data_start
  la t2, __data_end
0:
  bgeu t1, t2, 1f
  lw t3, 0(t0)
  sw t3, 0(t1)
  addi t0, t0, 4
  addi t1, t1, 4
  j 0b
1:

  // zero BSS
  la t0, __bss_start
  la t1, __bss_end
2:
  bgeu t0, t1, 3f
  sw zero, 0(t0)
  addi t0, t0, 4
  j 2b
3:
  call main

  // write exit code to tohost and spin
  lui t0, 0x20000
  sw a0, 4(t0)
4:
  j 4b
