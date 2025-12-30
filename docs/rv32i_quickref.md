# RV32I quick reference (tóm tắt)

RV32I là tập lệnh cơ sở 32-bit của RISC-V (không gồm nhân/chia, CSR, interrupt, FPU…).

## Các dạng lệnh (encoding)

- **R-type**: `funct7 | rs2 | rs1 | funct3 | rd | opcode`
- **I-type**: `imm[11:0] | rs1 | funct3 | rd | opcode`
- **S-type**: `imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode`
- **B-type**: `imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode` (offset bội số 2)
- **U-type**: `imm[31:12] | rd | opcode`
- **J-type**: `imm[20|10:1|11|19:12] | rd | opcode` (offset bội số 2)

## Nhóm lệnh chính

- **Integer arithmetic/logical (OP/OP-IMM)**:
  - `ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND`
  - `ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI`
- **Load/Store**:
  - Load: `LB, LH, LW, LBU, LHU`
  - Store: `SB, SH, SW`
- **Control flow**:
  - Branch: `BEQ, BNE, BLT, BGE, BLTU, BGEU`
  - Jump: `JAL, JALR`
- **Upper immediates**:
  - `LUI, AUIPC`
- **System**:
  - `ECALL, EBREAK` (thuộc nhóm SYSTEM; thường dùng cho trap/monitor)

## Lưu ý khi chạy C bare-metal

- Dùng `-march=rv32i -mabi=ilp32`.
- Tránh thư viện cần `M` (mul/div) nếu core chỉ có RV32I.
- Cần startup (`_start`), linker script, stack, clear `.bss`, (tuỳ chọn) copy `.data`.

