module uart_tx(
  input  wire       clk,
  input  wire       rst,
  input  wire       baud_tick,
  input  wire [7:0] data_in,
  input  wire       tx_start,
  output logic      tx,
  output logic      tx_busy
);

  logic [3:0] bitpos = 0;
  logic [9:0] shiftreg;

  always @(posedge clk) begin
    if (rst) begin
      tx      <= 1'b1;   // idle is high
      tx_busy <= 0;
      bitpos  <= 0;
    end else begin
    
      if (!tx_busy && tx_start) begin
        // Load frame: 1 start, 8 data, 1 stop
        shiftreg <= {1'b1, data_in, 1'b0};
        tx_busy  <= 1;
        bitpos   <= 0;
      end

      else if (tx_busy && baud_tick) begin
        tx       <= shiftreg[0];
        shiftreg <= shiftreg >> 1;
        bitpos   <= bitpos + 1;

        if (bitpos == 9) begin
          tx_busy <= 0;
          tx      <= 1'b1;
        end
      end

    end
  end
endmodule
