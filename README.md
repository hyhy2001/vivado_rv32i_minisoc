RV32I Mini SoC (Vivado-first, Verilog-only)

`vivado_rv32i_minisoc/` is a self-contained copy of the project (safe to move/copy elsewhere).

Current status:
- RTL + testbench: Verilog-2001 (`.v`) only (no SystemVerilog).
- Primary simulation flow: Vivado xsim (tested with Vivado 2025.2).
- `rom.hex` is loaded via a plusarg `+romhex=...` (see `rtl/simple_rom.v`).

Full report: `REPORT.md`

## Layout
- RTL: `rtl/`
- Testbench: `sim/`
- Bare-metal software (C/ASM): `software/`
- Vivado xsim scripts: `vivado/`

## Run simulation with Vivado (recommended)

Run from inside `vivado_rv32i_minisoc/`:

- Portable (no Vivado project, relative paths only): `vivado -mode batch -source vivado/run_xsim_noproject.tcl`
- Project-based (creates `vivado/vivado_proj/`): `vivado -mode batch -source vivado/run_xsim.tcl`

GUI:
- Add RTL sources: `rtl/*.v`
- Add simulation sources: `sim/tb_minisoc.v`
- Simulation top: `tb_minisoc`

Expected output:
- `Hello RV32I`
- `[sim] done, exit_code=0x00000001`

## Demo program (rom.hex)

Two options:
1) Use the prebuilt `software/rom.hex` (no compiler needed).
2) Rebuild from C:
   - You need an external RISC-V bare-metal toolchain (Vivado does not ship `riscv-gcc`).
   - Example (pass an explicit compiler path if not in PATH):
     - `powershell -NoProfile -ExecutionPolicy Bypass -File software\\build.ps1 -Prefix riscv-none-elf -GccExe "<toolchain_bin>\\riscv-none-elf-gcc.exe"`
