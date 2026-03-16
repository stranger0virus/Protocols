`timescale 1ns/1ps

module tb_uart;

  // Clock for UART (50 MHz)
  reg clk;
  reg rst;

  // UART interface signals
  reg  [7:0] tx_data;
  reg        tx_start;
  wire       tx_busy;

  wire       tx_line;  // UART TX output
  wire [7:0] rx_data;
  wire       rx_ready;

  // Loopback: TX → RX
  wire rx_line = tx_line;

  // Instantiate UART
  uart #(
    .CLK_FREQ(50_000_000),
    .BAUD(115200)
  ) dut (
    .clk(clk),
    .rst(rst),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx(tx_line),
    .tx_busy(tx_busy),
    .rx(rx_line),
    .rx_data(rx_data),
    .rx_ready(rx_ready)
  );

  // Clock generation (50 MHz = 20ns period)
  always #10 clk = ~clk;


  // ---------------------------
  // Task: send one byte
  // ---------------------------
  task uart_send(input [7:0] uart_tx_data);
  begin
    @(posedge clk);
    tx_data  = uart_tx_data;
    tx_start = 1;

    @(posedge clk);
    tx_start = 0;

    // Wait until transmission done
    wait (tx_busy == 1);
    wait (tx_busy == 0);
  end
  endtask

  integer i;
  reg [7:0] test_bytes [0:7];   // array of bytes for testing

  initial begin

    // Set up test bytes
    test_bytes[0] = 8'hA5;
    test_bytes[1] = 8'h3C;
    test_bytes[2] = 8'h5A;
    test_bytes[3] = 8'hF0;
    test_bytes[4] = 8'h00;
    test_bytes[5] = 8'hFF;
    test_bytes[6] = 8'hB6;
    test_bytes[7] = 8'h7E;

    // Initialize signals
    clk      = 0;
    rst      = 1;
    tx_data  = 0;
    tx_start = 0;

    // Waveform dump
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, tb_uart);

    // Reset
    repeat(20) @(posedge clk);
    rst = 0;

    $display("\nUART Testbench: Starting loopback test...\n");

    // Run through all test bytes
    for (i = 0; i < 8; i = i + 1) begin
      uart_send(test_bytes[i]);

      // Wait until RX receives a byte
      wait (rx_ready == 1);

      if (rx_data !== test_bytes[i])
        $display("ERROR: Expected %02h but got %02h at time %0t",
                  test_bytes[i], rx_data, $time);
      else
        $display("PASS: Received %02h correctly at time %0t",
                  rx_data, $time);

      @(posedge clk); // one cycle delay
    end

    $display("\nUART Loopback Test Complete.\n");
    #1000 $finish;
  end

endmodule

