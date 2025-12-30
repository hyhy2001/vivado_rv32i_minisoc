Mini SoC RV32I (Vivado-first, Verilog-only)

Thu muc `vivado_rv32i_minisoc/` la ban copy doc lap (self-contained), khong dung chung file voi `rv32i_minisoc/`.

Trang nay cap nhat theo hien trang:
- RTL + testbench: Verilog (.v), khong dung SystemVerilog (.sv).
- Mo phong chinh: Vivado xsim (Vivado 2025.2).
- `rom.hex` duoc nap qua plusarg `+romhex=...` (xem `vivado_rv32i_minisoc/rtl/simple_rom.v`).

Bao cao chi tiet: `vivado_rv32i_minisoc/REPORT.md`

## Thu muc
- RTL: `vivado_rv32i_minisoc/rtl`
- Testbench: `vivado_rv32i_minisoc/sim`
- Phan mem bare-metal (C/ASM): `vivado_rv32i_minisoc/software`
- Vivado xsim flow: `vivado_rv32i_minisoc/vivado`

## Chay mo phong bang Vivado (khuyen dung)

Dung tu trong thu muc `vivado_rv32i_minisoc/`:

Batch:
- Khong tao project (portable): `vivado -mode batch -source vivado/run_xsim_noproject.tcl`
- Co tao project (luu vao `vivado/vivado_proj/`): `vivado -mode batch -source vivado/run_xsim.tcl`

GUI:
- Add RTL sources: `rtl/*.v`
- Add simulation sources: `sim/tb_minisoc.v`
- Simulation top: `tb_minisoc`

## Chuong trinh demo (rom.hex)

Co 2 cach:
1) Dung san `rom.hex` (khong can build C): `software/rom.hex`
2) Build lai tu C:
   - Can RISC-V GNU toolchain (vd xPack `riscv-none-elf-gcc`) -> Vivado khong kem compiler RISC-V.
   - Build (truyen duong dan gcc neu PowerShell khong thay trong PATH):
     - `powershell -NoProfile -ExecutionPolicy Bypass -File software\\build.ps1 -Prefix riscv-none-elf -GccExe "<toolchain_bin>\\riscv-none-elf-gcc.exe"`
