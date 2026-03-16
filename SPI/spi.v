`timescale 1ns/1ps
module spi_master(clk, newd, rst, din, sclk, cs, mosi);
  
  input clk, newd, rst;
  input [7:0] din;
  output reg sclk, cs, mosi;
  
  typedef enum bit[1:0]{idle=2'b00, enable=2'b01, send=2'b10, comp=2'b11} state_type;
  state_type state = idle;
  
  int countc = 0;  // Used to generate sclk frequency
  int count = 0;   // Counter for shifting out bits
  
  // Generation of serial clock
  always @(posedge clk) begin
    if (rst == 1'b1) begin
      countc <= 0;
      sclk <= 1'b0;
    end else begin
      if (countc < 10)  // Reduced count for faster sclk toggling
        countc <= countc + 1;
      else begin
        countc <= 0;
        sclk <= ~sclk;  // Toggle sclk every 10 clock cycles
      end
    end
  end
  
  // State machine logic
  reg [7:0] temp;
  
  always @(posedge sclk) begin
    if (rst == 1'b1) begin
      cs <= 1'b1;
      mosi <= 1'b0;
      count <= 0;
    end else begin
      case(state)
        idle: begin
          if (newd == 1'b1) begin
            $display("SPI Master: Starting transmission with din=%0d", din);
            state <= send;
            temp <= din;
            cs <= 1'b0;  // Chip Select (active low)
          end else begin
            state <= idle;
            temp <= 8'h00;
          end
        end
        
        send: begin
          if (count <= 7) begin
            mosi <= temp[count];
            count <= count + 1;
          end else begin
            count <= 0;
            state <= comp;
            cs <= 1'b1;  // Deassert chip select (end of transmission)
            mosi <= 1'b0;
            $display("SPI Master: Data transmission complete");
          end
        end
        
        comp: begin
          state <= idle;
        end
        
        default: state <= idle;
      endcase
    end
  end
endmodule
