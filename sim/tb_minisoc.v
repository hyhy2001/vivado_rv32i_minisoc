`timescale 1ns/1ps

module tb_minisoc;
  reg clk;
  reg rst_n;

  wire        uart_tx_valid;
  wire [7:0]  uart_tx_data;
  wire        sim_done;
  wire [31:0] sim_exit_code;

  // Build a packed "string" buffer so we can print a full line with 1 $display
  // (avoids interleaving with xsim INFO messages).
  localparam integer UART_MAX = 256;
  reg [8*UART_MAX-1:0] uart_line;
  integer uart_len;
  integer max_cycles;
  integer j;
  integer k;
  reg [7:0] c;

  minisoc_top #(
    .ROM_WORDS(4096),
    .RAM_WORDS(4096),
    .ROM_MEMFILE("../software/rom.hex")
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data(uart_tx_data),
    .sim_done(sim_done),
    .sim_exit_code(sim_exit_code)
  );

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    uart_line = {8*UART_MAX{1'b0}};
    uart_len = 0;
  end

  always #5 clk = ~clk;

  initial begin
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

  task clear_uart_line;
    begin
      uart_line = {8*UART_MAX{1'b0}};
      uart_len = 0;
    end
  endtask

  task flush_uart_line;
    begin
      for (k = 0; k < uart_len; k = k + 1) begin
        $write("%c", uart_line[8*(UART_MAX-1-k) +: 8]);
      end
      $write("\n");
      clear_uart_line();
    end
  endtask

  always @(posedge clk) begin
    if (uart_tx_valid) begin
      c = uart_tx_data;
      if (c == 8'h0A) begin
        flush_uart_line();
      end else if (c == 8'h0D) begin
        // ignore CR
      end else begin
        if (uart_len < (UART_MAX-1)) begin
          uart_line[8*(UART_MAX-1-uart_len) +: 8] = c;
          uart_len = uart_len + 1;
        end
      end
    end

    if (sim_done) begin
      if (uart_len != 0) flush_uart_line();
      $display("\n[sim] done, exit_code=0x%08x", sim_exit_code);
      $finish;
    end
  end

  initial begin
    max_cycles = 200000;
    for (j = 0; j < max_cycles; j = j + 1) @(posedge clk);
    $display("\n[sim] timeout after %0d cycles", max_cycles);
    $finish;
  end
endmodule
