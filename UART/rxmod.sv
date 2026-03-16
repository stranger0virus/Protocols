module uart_rx(
  input  wire       clk,
  input  wire       rst,
  input  wire       baud_tick,
  input  wire       rx,
  output logic  [7:0] data_out,
  output logic        rx_ready
);

  logic [3:0] bitpos = 0;
  logic [7:0] buffer;

typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
} rx_state_t;

rx_state_t state;

  always @(posedge clk) begin
    if (rst) begin
      state    <= IDLE;
      bitpos   <= 0;
      rx_ready <= 0;
    end else begin

      case (state)

        IDLE: begin
          rx_ready <= 0;
          if (rx == 0)       // start bit detected
            state <= START;
        end

        START: begin
          if (baud_tick) begin
            bitpos <= 0;
            state  <= DATA;
          end
        end

        DATA: begin
          if (baud_tick) begin
            buffer[bitpos] <= rx;
            bitpos <= bitpos + 1;
            if (bitpos == 7)
              state <= STOP;
          end
        end

        STOP: begin
          if (baud_tick) begin
            data_out <= buffer;
            rx_ready <= 1;
            state    <= IDLE;
          end
        end

      endcase

    end
  end
endmodule
