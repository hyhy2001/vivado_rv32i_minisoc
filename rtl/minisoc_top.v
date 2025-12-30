module minisoc_top #(
  parameter integer ROM_WORDS = 4096,
  parameter integer RAM_WORDS = 4096,
  parameter ROM_MEMFILE = ""
) (
  input clk,
  input rst_n,

  output reg        uart_tx_valid,
  output reg [7:0]  uart_tx_data,
  output reg        sim_done,
  output reg [31:0] sim_exit_code
);

  localparam [31:0] ROM_BASE  = 32'h0000_0000;
  localparam [31:0] RAM_BASE  = 32'h1000_0000;
  localparam [31:0] UART_BASE = 32'h2000_0000;
  localparam [31:0] TOHOST    = 32'h2000_0004;
  localparam [31:0] ROM_SIZE_BYTES = ROM_WORDS * 4;

  wire [31:0] imem_addr;
  wire [31:0] imem_rdata;

  wire        dmem_valid;
  wire        dmem_we;
  wire [31:0] dmem_addr;
  wire [31:0] dmem_wdata;
  wire [3:0]  dmem_wstrb;
  reg  [31:0] dmem_rdata;

  wire cpu_halted;

  rv32i_core u_cpu (
    .clk(clk),
    .rst_n(rst_n),
    .imem_addr(imem_addr),
    .imem_rdata(imem_rdata),
    .dmem_valid(dmem_valid),
    .dmem_we(dmem_we),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_wstrb(dmem_wstrb),
    .dmem_rdata(dmem_rdata),
    .halted(cpu_halted)
  );

  simple_rom #(
    .WORDS(ROM_WORDS),
    .MEMFILE(ROM_MEMFILE)
  ) u_rom (
    .addr(imem_addr - ROM_BASE),
    .rdata(imem_rdata)
  );

  wire [31:0] drom_rdata;
  simple_rom #(
    .WORDS(ROM_WORDS),
    .MEMFILE(ROM_MEMFILE)
  ) u_drom (
    .addr(dmem_addr - ROM_BASE),
    .rdata(drom_rdata)
  );

  reg ram_we;
  wire [31:0] ram_rdata;
  simple_ram #(
    .WORDS(RAM_WORDS)
  ) u_ram (
    .clk(clk),
    .we(ram_we),
    .wstrb(dmem_wstrb),
    .addr(dmem_addr - RAM_BASE),
    .wdata(dmem_wdata),
    .rdata(ram_rdata)
  );

  reg rom_sel;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      uart_tx_valid <= 1'b0;
      uart_tx_data  <= 8'b0;
      sim_done      <= 1'b0;
      sim_exit_code <= 32'b0;
    end else begin
      uart_tx_valid <= 1'b0;

      if (dmem_valid && dmem_we) begin
        if (dmem_addr == UART_BASE) begin
          uart_tx_valid <= 1'b1;
          uart_tx_data  <= dmem_wdata[7:0];
        end
        if (dmem_addr == TOHOST) begin
          if (dmem_wdata != 32'b0) begin
            sim_done      <= 1'b1;
            sim_exit_code <= dmem_wdata;
          end
        end
      end
    end
  end

  always @* begin
    rom_sel = (dmem_addr < ROM_SIZE_BYTES);

    ram_we = 1'b0;
    dmem_rdata = 32'b0;

    if (dmem_valid) begin
      if (dmem_addr[31:16] == RAM_BASE[31:16]) begin
        dmem_rdata = ram_rdata;
        ram_we = dmem_we && (dmem_wstrb != 4'b0000);
      end else if (rom_sel && !dmem_we) begin
        dmem_rdata = drom_rdata;
      end else if (dmem_addr == UART_BASE) begin
        dmem_rdata = 32'b0;
      end else if (dmem_addr == TOHOST) begin
        dmem_rdata = sim_exit_code;
      end else begin
        dmem_rdata = 32'b0;
      end
    end
  end

endmodule
