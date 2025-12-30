# Bao cao: SoC RV32I toi thieu (Verilog-only, mo phong bang Vivado xsim)

## 1) Muc tieu

Thiet ke va mo phong 1 SoC toi thieu dua tren RISC-V RV32I co kha nang chay:
- Chuong trinh Assembly don gian (ROM `rom.hex`)
- Chuong trinh C bare-metal don gian (build ELF -> chuyen sang `rom.hex` -> mo phong)

## 2) Pham vi

- ISA: RV32I (khong CSR/interrupt, khong RV32M mul/div, khong FPU).
- CPU: multi-cycle FSM (FETCH/DECODE/EXEC/MEM/WB).
- SoC: ROM + RAM + MMIO (UART TX, TOHOST).
- RTL/testbench: Verilog (.v), khong dung SystemVerilog.

## 3) Memory map

| Vung | Dia chi | Mo ta |
|---|---:|---|
| ROM | `0x0000_0000` | code + `.rodata` (fetch + data-load) |
| RAM | `0x1000_0000` | stack + `.data` + `.bss` |
| UART_TX | `0x2000_0000` | ghi byte -> testbench in ra console |
| TOHOST | `0x2000_0004` | ghi word != 0 -> ket thuc mo phong |

## 4) Kien truc SoC

SoC top lam 3 viec:
1) Ket noi CPU voi ROM (instruction fetch).
2) Ket noi CPU voi RAM (data load/store).
3) Address decode cho MMIO:
   - UART TX: store 1 byte -> in ra console
   - TOHOST: store word != 0 -> stop simulation

File:
- SoC top: `rtl/minisoc_top.v`
- ROM: `rtl/simple_rom.v`
- RAM: `rtl/simple_ram.v`

Luu y: de chay C, data-load can doc duoc ROM (de doc `.rodata` nhu string hang). SoC da co duong doc ROM cho data-load.

## 5) CPU RV32I (multi-cycle)

CPU dung FSM:
- RESET: PC=0, init.
- FETCH: doc `instr` tai `pc`.
- DECODE: tach opcode/rs/rd/immediate.
- EXEC: tinh ALU/branch/jump/effective address.
- MEM: thuc hien load/store.
- WB: ghi ket qua ve thanh ghi va cap nhat PC.

File CPU: `rtl/rv32i_core.v`

## 6) Mo phong bang Vivado 2025.2 (xsim)

Script batch:
- `vivado/run_xsim_noproject.tcl` (portable, khong tao project)
- `vivado/run_xsim.tcl` (tao project trong `vivado/vivado_proj/`)

Chay:
- (dung tu trong thu muc `vivado_rv32i_minisoc/`):
  - `vivado -mode batch -source vivado/run_xsim_noproject.tcl`
  - hoac `vivado -mode batch -source vivado/run_xsim.tcl`

Testbench:
- `sim/tb_minisoc.v`

ROM file:
- Testbench/ROM doc `rom.hex` qua plusarg `romhex` (duoc set trong TCL), nen khong phu thuoc working directory.

Ket qua mong doi:
- Hien thi `Hello RV32I`
- Ket thuc: `[sim] done, exit_code=0x00000001`

## 7) Chay chuong trinh C bare-metal

Vivado chi mo phong RTL; de build C can toolchain RISC-V ben ngoai (vd xPack `riscv-none-elf-gcc`).

File:
- Startup: `software/start.S`
- Linker: `software/link.ld`
- C demo: `software/main.c`
- Build: `software/build.ps1`
- ELF -> hex: `software/elf2hex.py`

Build (vi du):
- `powershell -NoProfile -ExecutionPolicy Bypass -File software\\build.ps1 -Prefix riscv-none-elf -GccExe "<toolchain_bin>\\riscv-none-elf-gcc.exe"`

Sau do chay lai TCL mo phong.
