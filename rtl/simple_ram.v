module simple_ram #(
  parameter integer WORDS = 4096
) (
  input         clk,
  input         we,
  input  [3:0]  wstrb,
  input  [31:0] addr,
  input  [31:0] wdata,
  output reg [31:0] rdata
);

  reg [31:0] mem[0:WORDS-1];
  wire [31:0] word_addr = addr[31:2];

  always @* begin
    if (word_addr < WORDS) rdata = mem[word_addr];
    else                   rdata = 32'b0;
  end

  always @(posedge clk) begin
    if (we) begin
      if (word_addr < WORDS) begin
        if (wstrb[0]) mem[word_addr][7:0]   <= wdata[7:0];
        if (wstrb[1]) mem[word_addr][15:8]  <= wdata[15:8];
        if (wstrb[2]) mem[word_addr][23:16] <= wdata[23:16];
        if (wstrb[3]) mem[word_addr][31:24] <= wdata[31:24];
      end
    end
  end

endmodule

