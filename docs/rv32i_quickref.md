# RV32I quick reference

RV32I is the base 32-bit integer instruction set of RISC-V (no mul/div, no CSR/interrupts, no FPU).

## Instruction formats (encoding)

- **R-type**: `funct7 | rs2 | rs1 | funct3 | rd | opcode`
- **I-type**: `imm[11:0] | rs1 | funct3 | rd | opcode`
- **S-type**: `imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode`
- **B-type**: `imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode` (PC-relative, 2-byte aligned)
- **U-type**: `imm[31:12] | rd | opcode`
- **J-type**: `imm[20|10:1|11|19:12] | rd | opcode` (PC-relative, 2-byte aligned)

## Main instruction groups

- **Integer arithmetic/logical**
  - OP (register): `ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND`
  - OP-IMM: `ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI`
- **Load / Store**
  - Loads: `LB, LH, LW, LBU, LHU`
  - Stores: `SB, SH, SW`
- **Control flow**
  - Branch: `BEQ, BNE, BLT, BGE, BLTU, BGEU`
  - Jump: `JAL, JALR`
- **Upper immediates**
  - `LUI, AUIPC`
- **System**
  - `ECALL, EBREAK` (often used for traps/monitors in larger systems)

## Notes for bare-metal C on RV32I

- Compile flags: `-march=rv32i -mabi=ilp32`.
- Avoid code that requires RV32M (mul/div) if your core implements RV32I only.
- A bare-metal program needs startup (`_start`), a linker script, a stack pointer, `.bss` clear, and (optionally) `.data` copy.

