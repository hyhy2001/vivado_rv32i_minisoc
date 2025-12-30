# Report: Minimal RV32I SoC (Verilog-only, simulated with Vivado xsim)

## 1) Goal

Design and simulate a minimal RISC-V RV32I SoC that can run:
- A simple assembly program (ROM image `rom.hex`)
- A simple bare-metal C program (build ELF -> convert to `rom.hex` -> simulate)

## 2) Scope

- ISA: RV32I only (no CSR/interrupts, no RV32M mul/div, no FPU).
- CPU micro-architecture: multi-cycle FSM (FETCH/DECODE/EXEC/MEM/WB).
- SoC blocks: ROM + RAM + a tiny MMIO map (UART TX, TOHOST).
- RTL/testbench language: Verilog-2001 (`.v`) only.

## 3) Memory map

| Region | Address | Description |
|---|---:|---|
| ROM | `0x0000_0000` | code + `.rodata` (instruction fetch + data load) |
| RAM | `0x1000_0000` | stack + `.data` + `.bss` |
| UART_TX | `0x2000_0000` | store a byte to print to the console |
| TOHOST | `0x2000_0004` | store a non-zero word to stop simulation |

## 4) SoC architecture

The SoC top does:
1) Connect the CPU instruction fetch to ROM.
2) Connect the CPU data port to RAM.
3) Decode MMIO:
   - `UART_TX`: store 1 byte -> printed by the testbench
   - `TOHOST`: store word != 0 -> testbench terminates

RTL files:
- SoC top: `rtl/minisoc_top.v`
- ROM: `rtl/simple_rom.v`
- RAM: `rtl/simple_ram.v`

Note: to run C, the CPU must be able to load constants/strings from ROM (`.rodata`). This SoC supports ROM data loads.

## 5) RV32I CPU (multi-cycle)

The CPU runs a simple FSM:
- RESET: initialize PC and registers.
- FETCH: fetch instruction at `PC`.
- DECODE: decode fields + immediates.
- EXEC: ALU/branch/jump/effective address.
- MEM: load/store transaction.
- WB: write back and update PC.

CPU RTL: `rtl/rv32i_core.v`

## 6) Simulation with Vivado 2025.2 (xsim)

Scripts:
- Portable, no project (recommended for copying/moving the folder): `vivado/run_xsim_noproject.tcl`
- Project-based (creates `vivado/vivado_proj/`): `vivado/run_xsim.tcl`

Run from inside `vivado_rv32i_minisoc/`:
- `vivado -mode batch -source vivado/run_xsim_noproject.tcl`
  or
- `vivado -mode batch -source vivado/run_xsim.tcl`

Testbench:
- `sim/tb_minisoc.v`

ROM loading:
- ROM uses plusarg `romhex` (set by the TCL scripts), so the simulator working directory does not matter.

Expected output:
- `Hello RV32I`
- `[sim] done, exit_code=0x00000001`

## 7) Running the bare-metal C demo

Vivado simulates RTL only; it does not include a RISC-V C toolchain. To rebuild `rom.hex` from C you need an external RISC-V bare-metal toolchain (e.g. xPack `riscv-none-elf-gcc`).

Software files:
- Startup: `software/start.S`
- Linker script: `software/link.ld`
- C demo: `software/main.c`
- Build script: `software/build.ps1`
- ELF -> hex converter: `software/elf2hex.py`

Example build command:
- `powershell -NoProfile -ExecutionPolicy Bypass -File software\\build.ps1 -Prefix riscv-none-elf -GccExe "<toolchain_bin>\\riscv-none-elf-gcc.exe"`

Then re-run the Vivado TCL simulation script.
