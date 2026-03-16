`timescale 1ns/1ps

module tb_i2c_master;

    // Testbench signals
    logic clk;
    logic rst_n;
    logic start;
    logic [6:0] addr;
    logic [7:0] data;
    logic busy;
    logic done;
    logic ack_error;
    wire sda;
    wire scl;

    // Instantiate the I2C master module
    i2c_master uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .addr(addr),
        .data(data),
        .busy(busy),
        .done(done),
        .ack_error(ack_error),
        .sda(sda),
        .scl(scl)
    );

    // Clock generation
    always #5 clk = ~clk;  // 100 MHz clock

    // Stimulus generation
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        start = 0;
        addr = 7'b1010101;  // Example address
        data = 8'hA5;       // Example data
        #10;

        // Release reset
        rst_n = 1;
        #10;

        // Start a transaction
        start = 1;
        #10;
        start = 0;
        
        // Wait for done signal
        wait(done == 1);
        $display("Transaction completed successfully.");

        // Check for ack_error
        if (ack_error)
            $display("ACK error occurred.");
        else
            $display("No ACK error.");

        // End simulation
        $finish;
    end

    // Monitor SDA and SCL activity
    initial begin
        $monitor("Time: %t | sda: %b | scl: %b | busy: %b | done: %b | ack_error: %b", 
                  $time, sda, scl, busy, done, ack_error);
    end

    // Dump waveform
    initial begin
        $dumpfile("tb_i2c_master.vcd");
        $dumpvars(0, tb_i2c_master);
    end

endmodule
