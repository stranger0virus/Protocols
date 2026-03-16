module uart_baud_gen #(
  parameter CLK_FREQ = 50_000_000,   // Hz
  parameter BAUD     = 115200
)(
  input  wire clk,
  input  wire rst,
  output logic  baud_tick      // 1-cycle pulse at baud rate
);

  localparam DIV = CLK_FREQ / BAUD;
  integer count = 0;

  always @(posedge clk) begin
    if (rst) begin
      count     <= 0;
      baud_tick <= 0;
    end else begin
      if (count >= DIV-1) begin
        count     <= 0;
        baud_tick <= 1;
      end else begin
        count     <= count + 1;
        baud_tick <= 0;
      end
    end
  end

endmodule

