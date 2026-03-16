`timescale 1ns/1ps
module gpio #(
    parameter WIDTH = 8
)(
    input  logic              clk,
    input  logic              rst,

    // CPU interface
    input  logic              wr_en,
    input  logic              rd_en,
    input  logic  [WIDTH-1:0] wdata,
    input  logic  [WIDTH-1:0] dir_in,   // direction written by CPU

    // GPIO pins
    inout  wire   [WIDTH-1:0] gpio,

    // Output back to CPU
    output logic [WIDTH-1:0] rdata
);

    logic [WIDTH-1:0] gpio_out;
    logic [WIDTH-1:0] dir;       // direction register

    // Update registers
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            gpio_out <= '0;
            dir      <= '0;      // default all pins = input
        end
        else begin
            if (wr_en)
                gpio_out <= wdata;

            // separate write for direction (optional)
            dir <= dir_in;
        end
    end

    // Tri-state
    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin
            assign gpio[i] = dir[i] ? gpio_out[i] : 1'bz;
        end
    endgenerate

    // Read input pins
    always_ff @(posedge clk) begin
        if (rd_en)
            rdata <= gpio;
    end

endmodule

