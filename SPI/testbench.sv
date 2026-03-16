`timescale 1ns/1ps

module tb_spi_master;

  // Testbench signals
  reg clk;
  reg rst;
  reg newd;
  reg [7:0] din;
  wire sclk;
  wire cs;
  wire mosi;

  // Instantiate DUT
  spi_master dut (
    .clk(clk),
    .newd(newd),
    .rst(rst),
    .din(din),
    .sclk(sclk),
    .cs(cs),
    .mosi(mosi)
  );

  // System clock (100 MHz)
  initial clk = 0;
  always #5 clk = ~clk;

  // --- Task to send bytes synchronized to sclk ---
  task send_byte(input [7:0] data);
  begin
    din = data;

    // Wait for sclk rising edge (FSM samples newd here)
    @(posedge sclk);
    newd = 1;

    // FSM will detect newd on this posedge
    @(posedge sclk);
    newd = 0;

    // Wait until cs returns HIGH (end of transmit)
    wait(cs == 1'b1);

    // Extra settle time
    repeat(4) @(posedge clk);
  end
  endtask


  // Main stimulus
  initial begin
    // Optional waveform dump
    $dumpfile("spi_tb.vcd");
    $dumpvars(0, tb_spi_master);

    // Initialize
    newd = 0;
    din  = 0;
    rst  = 1;

    // Hold reset long enough for sclk to start toggling
    repeat (20) @(posedge clk);
    rst = 0;

    $display("TB: Reset deasserted");

    // Send transactions
    send_byte(8'hA5);
    send_byte(8'h3C);
    send_byte(8'hF0);

    $display("TB: All tests finished");
    #200;
    $finish;
  end

  // Monitor activity
  initial begin
    $monitor("T=%0t  | CS=%b | SCLK=%b | MOSI=%b | DIN=%02h | STATE=%s",
             $time, cs, sclk, mosi, din, dut.state.name());
  end

endmodule
