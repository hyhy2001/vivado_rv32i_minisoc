module simple_rom #(
  parameter integer WORDS = 4096,
  parameter MEMFILE = ""
) (
  input  [31:0] addr,
  output reg [31:0] rdata
);

  reg [31:0] mem[0:WORDS-1];
  reg [8*512-1:0] plusarg_file;

  initial begin
    if ($value$plusargs("romhex=%s", plusarg_file)) begin
      $readmemh(plusarg_file, mem);
    end else if (MEMFILE != "") begin
      $readmemh(MEMFILE, mem);
    end
  end

  always @* begin
    if (addr[31:2] < WORDS) rdata = mem[addr[31:2]];
    else                    rdata = 32'h00000013;
  end

endmodule

