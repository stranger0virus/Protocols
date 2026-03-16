`timescale 1ns/1ps

module gpio_tb;

    parameter WIDTH = 8;

    // DUT Signals
    logic               clk, rst;
    logic               wr_en, rd_en;
    logic [WIDTH-1:0]   wdata;
    logic [WIDTH-1:0]   dir_in;
    wire  [WIDTH-1:0]   gpio;
    logic [WIDTH-1:0]   rdata;

    // Internal testbench-driven version of GPIO (for input mode)
    logic [WIDTH-1:0]   gpio_drive;
    logic [WIDTH-1:0] temp;
    
	assign gpio = gpio_drive;   // drives DUT when dir_in = 0

    // Instantiate DUT
    gpio #(.WIDTH(WIDTH)) dut (
        .clk   (clk),
        .rst   (rst),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .wdata (wdata),
        .dir_in(dir_in),
        .gpio  (gpio),
        .rdata (rdata)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task: write to GPIO
    task gpio_write(input [WIDTH-1:0] data);
        begin
            @(posedge clk);
            wr_en = 1;
            wdata = data;
            @(posedge clk);
            wr_en = 0;
        end
    endtask

    // Task: read GPIO
    task gpio_read(output [WIDTH-1:0] data);
        begin
            @(posedge clk);
            rd_en = 1;
            @(posedge clk);
            rd_en = 0;
            data = rdata;
        end
    endtask

    // Self-checking macro
    task check(input [WIDTH-1:0] expected, input [WIDTH-1:0] received, string msg);
        if (expected === received)
            $display("PASS: %s | Expected=%b Received=%b", msg, expected, received);
        else
            $display("FAIL: %s | Expected=%b Received=%b", msg, expected, received);
    endtask


    initial begin
        // Init signals
        clk = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        wdata = 0;
        dir_in = 0;
        gpio_drive = 'z;

        #20 rst = 0;

        // -------------------------------
        // TEST 1: Write Output Pins
        // -------------------------------
        $display("\n--- TEST 1: Write Output Pins ---");

        dir_in = 8'hFF;   // ALL OUTPUT
        gpio_drive = 'z;  // nothing drives pin

        gpio_write(8'hA5);

        gpio_read(temp);

        check(8'hA5, temp, "Write/Read Output A5");


        // -------------------------------
        // TEST 2: Change output and re-read
        // -------------------------------
        $display("\n--- TEST 2: Change Output ---");

        gpio_write(8'h3C);
        gpio_read(temp);

        check(8'h3C, temp, "Write/Read Output 3C");


        // -------------------------------
        // TEST 3: Input Mode Reading
        // -------------------------------
        $display("\n--- TEST 3: Read Input Pins ---");

        dir_in = 8'h00;         // ALL INPUT
        gpio_drive = 8'hF0;     // Drive external signal

        gpio_read(temp);

        check(8'hF0, temp, "Read External Input F0");


        // -------------------------------
        // TEST 4: Mixed Direction Test
        // -------------------------------
        $display("\n--- TEST 4: Mixed Directions ---");

        dir_in = 8'b11110000;   // Upper nibble OUT, lower nibble IN
        gpio_drive = 8'h0F;     // External drives lower nibble

        gpio_write(8'hA0);      // Upper nibble becomes A, lower ignored
        gpio_read(temp);

        // Expected: upper nibble = A, lower nibble = driven 0x0F
        check(8'hAF, temp, "Mixed IO Direction Test");


        // Finish
        $display("\nGPIO Testbench Finished.\n");
        #20 $finish;
    end

endmodule
