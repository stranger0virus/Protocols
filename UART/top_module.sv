module uart #(
  parameter CLK_FREQ = 50_000_000,
  parameter BAUD     = 115200
)(
  input  wire       clk,
  input  wire       rst,

  // TX
  input  wire [7:0] tx_data,
  input  wire       tx_start,
  output wire       tx,
  output wire       tx_busy,

  // RX
  input  wire       rx,
  output wire [7:0] rx_data,
  output wire       rx_ready
);

  wire baud_tick;

  uart_baud_gen #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD(BAUD)
  ) baud_inst (
    .clk(clk),
    .rst(rst),
    .baud_tick(baud_tick)
  );

  uart_tx tx_inst (
    .clk(clk),
    .rst(rst),
    .baud_tick(baud_tick),
    .data_in(tx_data),
    .tx_start(tx_start),
    .tx(tx),
    .tx_busy(tx_busy)
  );

  uart_rx rx_inst (
    .clk(clk),
    .rst(rst),
    .baud_tick(baud_tick),
    .rx(rx),
    .data_out(rx_data),
    .rx_ready(rx_ready)
  );

endmodule
