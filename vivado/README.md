Vivado 2025.2 (xsim) - simulate RV32I mini SoC

This folder belongs to the standalone project root: `vivado_rv32i_minisoc/`.

## Batch run (recommended)

From inside `vivado_rv32i_minisoc/`:

Portable (no Vivado project, relative paths only):
- `vivado -mode batch -source vivado/run_xsim_noproject.tcl`

Project-based (creates `vivado/vivado_proj/`):
- `vivado -mode batch -source vivado/run_xsim.tcl`

Optional: choose a different part (mainly for project creation):

`vivado -mode batch -source vivado/run_xsim.tcl -tclargs xc7a35tcsg324-1`

The Vivado project will be created at `vivado/vivado_proj/`.

## GUI run

1) Create Project (RTL Project)
2) Add Sources:
   - add all files in `rtl/*.v`
3) Add Simulation Sources:
   - add `sim/tb_minisoc.v`
4) Set simulation top: `tb_minisoc`
5) Run Behavioral Simulation

## ROM file (rom.hex)

ROM is loaded via plusarg `romhex` (see `rtl/simple_rom.v`), so xsim working directory does not matter.
