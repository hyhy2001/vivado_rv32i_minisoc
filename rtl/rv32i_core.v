module rv32i_core (
  input         clk,
  input         rst_n,

  output [31:0] imem_addr,
  input  [31:0] imem_rdata,

  output reg        dmem_valid,
  output reg        dmem_we,
  output reg [31:0] dmem_addr,
  output reg [31:0] dmem_wdata,
  output reg [3:0]  dmem_wstrb,
  input      [31:0] dmem_rdata,

  output reg        halted
);

  localparam [2:0] ST_RESET  = 3'd0;
  localparam [2:0] ST_FETCH  = 3'd1;
  localparam [2:0] ST_DECODE = 3'd2;
  localparam [2:0] ST_EXEC   = 3'd3;
  localparam [2:0] ST_MEM    = 3'd4;
  localparam [2:0] ST_WB     = 3'd5;

  reg [2:0] state;

  reg [31:0] pc;
  reg [31:0] instr;
  reg [31:0] pc_plus4;

  reg [31:0] regs[0:31];

  reg [6:0]  opcode;
  reg [2:0]  funct3;
  reg [6:0]  funct7;
  reg [4:0]  rd, rs1, rs2;

  reg [31:0] rs1_val, rs2_val;
  reg [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

  reg [31:0] alu_res;
  reg [31:0] wb_data;
  reg        wb_en;
  reg [4:0]  wb_rd;

  reg [4:0]  shamt;
  reg        branch_take;

  reg [31:0] eff_addr_load;
  reg [1:0]  eff_addr_load_lsb;
  reg [31:0] eff_addr_store;
  reg [1:0]  eff_addr_store_lsb;

  reg [31:0] load_shifted;
  reg [31:0] load_wb_data;

  reg        mem_is_load;
  reg [31:0] mem_addr;
  reg [31:0] mem_store_wdata;
  reg [3:0]  mem_store_wstrb;
  reg [2:0]  mem_funct3;
  reg [1:0]  mem_addr_lsb;
  reg [31:0] mem_load_word;

  integer i;

  function [31:0] signext;
    input [31:0] x;
    input integer bits;
    reg [31:0] mask;
    begin
      mask = 32'h1 << (bits - 1);
      signext = (x ^ mask) - mask;
    end
  endfunction

  always @* begin
    opcode = instr[6:0];
    rd     = instr[11:7];
    funct3 = instr[14:12];
    rs1    = instr[19:15];
    rs2    = instr[24:20];
    funct7 = instr[31:25];

    imm_i = signext({20'b0, instr[31:20]}, 12);
    imm_s = signext({20'b0, instr[31:25], instr[11:7]}, 12);
    imm_b = signext({19'b0, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}, 13);
    imm_u = {instr[31:12], 12'b0};
    imm_j = signext({11'b0, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}, 21);
  end

  always @* begin
    rs1_val = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    rs2_val = (rs2 == 5'd0) ? 32'b0 : regs[rs2];
  end

  always @* begin
    shamt = instr[24:20];

    eff_addr_load = rs1_val + imm_i;
    eff_addr_load_lsb = rs1_val[1:0] + imm_i[1:0];
    eff_addr_store = rs1_val + imm_s;
    eff_addr_store_lsb = rs1_val[1:0] + imm_s[1:0];

    branch_take = 1'b0;
    if (opcode == 7'b1100011) begin
      case (funct3)
        3'b000: branch_take = (rs1_val == rs2_val); // BEQ
        3'b001: branch_take = (rs1_val != rs2_val); // BNE
        3'b100: branch_take = ($signed(rs1_val) <  $signed(rs2_val)); // BLT
        3'b101: branch_take = ($signed(rs1_val) >= $signed(rs2_val)); // BGE
        3'b110: branch_take = (rs1_val <  rs2_val); // BLTU
        3'b111: branch_take = (rs1_val >= rs2_val); // BGEU
        default: branch_take = 1'b0;
      endcase
    end

    load_shifted = mem_load_word >> (mem_addr_lsb * 8);
    load_wb_data = 32'b0;
    case (mem_funct3)
      3'b000: load_wb_data = signext({24'b0, load_shifted[7:0]}, 8);   // LB
      3'b001: load_wb_data = signext({16'b0, load_shifted[15:0]}, 16); // LH
      3'b010: load_wb_data = load_shifted;                              // LW
      3'b100: load_wb_data = {24'b0, load_shifted[7:0]};                // LBU
      3'b101: load_wb_data = {16'b0, load_shifted[15:0]};               // LHU
      default: load_wb_data = 32'b0;
    endcase
  end

  assign imem_addr = pc;

  always @* begin
    dmem_valid = 1'b0;
    dmem_we    = 1'b0;
    dmem_addr  = 32'b0;
    dmem_wdata = 32'b0;
    dmem_wstrb = 4'b0000;

    if (state == ST_MEM) begin
      dmem_valid = 1'b1;
      dmem_we    = !mem_is_load;
      dmem_addr  = mem_addr;
      dmem_wdata = mem_store_wdata;
      dmem_wstrb = mem_store_wstrb;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state   <= ST_RESET;
      pc      <= 32'b0;
      instr   <= 32'h00000013;
      pc_plus4 <= 32'b0;
      halted  <= 1'b0;

      wb_en   <= 1'b0;
      wb_rd   <= 5'd0;
      wb_data <= 32'b0;

      mem_is_load <= 1'b1;
      mem_addr <= 32'b0;
      mem_store_wdata <= 32'b0;
      mem_store_wstrb <= 4'b0000;
      mem_funct3 <= 3'b000;
      mem_addr_lsb <= 2'b00;
      mem_load_word <= 32'b0;

      for (i = 0; i < 32; i = i + 1) regs[i] <= 32'b0;
    end else begin
      regs[0] <= 32'b0;

      if (!halted) begin
        wb_en <= 1'b0;

        case (state)
          ST_RESET: begin
            pc <= 32'b0;
            state <= ST_FETCH;
          end

          ST_FETCH: begin
            instr <= imem_rdata;
            pc_plus4 <= pc + 32'd4;
            state <= ST_DECODE;
          end

          ST_DECODE: begin
            state <= ST_EXEC;
          end

          ST_EXEC: begin
            wb_rd <= rd;
            case (opcode)
              7'b0110111: begin // LUI
                wb_en   <= (rd != 5'd0);
                wb_data <= imm_u;
                state   <= ST_WB;
              end
              7'b0010111: begin // AUIPC
                wb_en   <= (rd != 5'd0);
                wb_data <= pc + imm_u;
                state   <= ST_WB;
              end
              7'b1101111: begin // JAL
                if (rd != 5'd0) regs[rd] <= pc_plus4;
                pc <= pc + imm_j;
                state <= ST_FETCH;
              end
              7'b1100111: begin // JALR
                if (rd != 5'd0) regs[rd] <= pc_plus4;
                pc <= (rs1_val + imm_i) & 32'hFFFF_FFFE;
                state <= ST_FETCH;
              end
              7'b1100011: begin // BRANCH
                pc <= branch_take ? (pc + imm_b) : pc_plus4;
                state <= ST_FETCH;
              end
              7'b0000011: begin // LOAD
                mem_is_load <= 1'b1;
                mem_addr  <= eff_addr_load;
                mem_store_wstrb <= 4'b0000;
                mem_funct3 <= funct3;
                mem_addr_lsb <= eff_addr_load_lsb;
                state <= ST_MEM;
              end
              7'b0100011: begin // STORE
                mem_is_load <= 1'b0;
                mem_addr  <= eff_addr_store;
                mem_store_wdata <= rs2_val;
                case (funct3)
                  3'b000: mem_store_wstrb <= (4'b0001 << eff_addr_store_lsb); // SB
                  3'b001: mem_store_wstrb <= eff_addr_store_lsb[1] ? 4'b1100 : 4'b0011; // SH
                  3'b010: mem_store_wstrb <= 4'b1111; // SW
                  default: mem_store_wstrb <= 4'b0000;
                endcase
                state <= ST_MEM;
              end
              7'b0010011: begin // OP-IMM
                case (funct3)
                  3'b000: alu_res = rs1_val + imm_i; // ADDI
                  3'b010: alu_res = ($signed(rs1_val) < $signed(imm_i)) ? 32'd1 : 32'd0; // SLTI
                  3'b011: alu_res = (rs1_val < imm_i) ? 32'd1 : 32'd0; // SLTIU
                  3'b100: alu_res = rs1_val ^ imm_i; // XORI
                  3'b110: alu_res = rs1_val | imm_i; // ORI
                  3'b111: alu_res = rs1_val & imm_i; // ANDI
                  3'b001: alu_res = rs1_val << shamt; // SLLI
                  3'b101: begin
                    if (funct7 == 7'b0100000) alu_res = $signed(rs1_val) >>> shamt; // SRAI
                    else                      alu_res = rs1_val >> shamt;          // SRLI
                  end
                  default: alu_res = 32'b0;
                endcase
                wb_en   <= (rd != 5'd0);
                wb_data <= alu_res;
                state   <= ST_WB;
              end
              7'b0110011: begin // OP
                case (funct3)
                  3'b000: alu_res = (funct7 == 7'b0100000) ? (rs1_val - rs2_val) : (rs1_val + rs2_val); // SUB/ADD
                  3'b001: alu_res = rs1_val << rs2_val[4:0]; // SLL
                  3'b010: alu_res = ($signed(rs1_val) < $signed(rs2_val)) ? 32'd1 : 32'd0; // SLT
                  3'b011: alu_res = (rs1_val < rs2_val) ? 32'd1 : 32'd0; // SLTU
                  3'b100: alu_res = rs1_val ^ rs2_val; // XOR
                  3'b101: alu_res = (funct7 == 7'b0100000) ? ($signed(rs1_val) >>> rs2_val[4:0]) : (rs1_val >> rs2_val[4:0]); // SRA/SRL
                  3'b110: alu_res = rs1_val | rs2_val; // OR
                  3'b111: alu_res = rs1_val & rs2_val; // AND
                  default: alu_res = 32'b0;
                endcase
                wb_en   <= (rd != 5'd0);
                wb_data <= alu_res;
                state   <= ST_WB;
              end
              7'b1110011: begin
                halted <= 1'b1;
                state  <= ST_FETCH;
              end
              default: begin
                halted <= 1'b1;
                state  <= ST_FETCH;
              end
            endcase
          end

          ST_MEM: begin
            if (mem_is_load) begin
              mem_load_word <= dmem_rdata;
              state <= ST_WB;
            end else begin
              pc <= pc_plus4;
              state <= ST_FETCH;
            end
          end

          ST_WB: begin
            if (opcode == 7'b0000011) begin
              if (wb_rd != 5'd0) regs[wb_rd] <= load_wb_data;
            end else if (wb_en && (wb_rd != 5'd0)) begin
              regs[wb_rd] <= wb_data;
            end
            pc <= pc_plus4;
            state <= ST_FETCH;
          end

          default: begin
            state <= ST_FETCH;
          end
        endcase
      end
    end
  end

endmodule

