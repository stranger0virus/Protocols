/*
Wait until CTRL.start == 1
FSM <= START_COND

START_COND:
    Drive SDA: 1 -> 0 while SCL = 1
    FSM <= SEND_ADDRESS

SEND_ADDRESS:
    Load shift_reg = {addr[7:1], RW}
    for bit 7 downto 0:
        SDA = shift_reg[bit]
        toggle SCL high
    FSM <= ADDR_ACK

ADDR_ACK:
    Release SDA
    toggle SCL high
    read SDA -> ack
    if ack == 1: goto STOP_COND
    else: continue

if write:
    FSM <= WRITE_BYTE
else:
    FSM <= READ_BYTE

WRITE_BYTE:
    For each data byte:
        shift bits
        check ACK
    FSM <= STOP_COND

READ_BYTE:
    For each byte:
        shift in bits
        send ACK except last byte
    FSM <= STOP_COND

STOP_COND:
    SDA = 0 → 1 while SCL = 1
    FSM <= DONE
*/


`timescale 1ns/1ps

module i2c_master_simple #(
    parameter CLK_DIV = 50  // Adjust for SCL frequency
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,		// Begin transaction
    input  logic [6:0] addr,       	// 7-bit slave address
    input  logic [7:0] data,       	// Data byte to write
    output logic       busy,		
    output logic       done,		// Goes high on transaction doen (for one cycle)
    output logic       ack_error,	
    inout  wire        sda,			// Serial data line
    output logic       scl			// Serial clock line
);

    // ---------------------------
    // Open-drain SDA control
    // ---------------------------
    logic sda_drive;     // 1 = drive low, 0 = release
    assign sda = sda_drive ? 1'b0 : 1'bz;
    wire sda_in = sda;

    // ---------------------------
    // Simple SCL generation
    // ---------------------------
    logic [$clog2(CLK_DIV)-1:0] div;
    logic scl_int;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div <= 0;
            scl_int <= 1;
        end else begin
            if (div == CLK_DIV-1) begin
                div <= 0;
                scl_int <= ~scl_int;
            end else
                div <= div + 1;
        end
    end

    assign scl = scl_int;
    wire scl_rise = (scl_int == 1 && div == 0);
    wire scl_fall = (scl_int == 0 && div == 0);

    // ---------------------------
    // FSM states
    // ---------------------------
    typedef enum logic [3:0] {
        IDLE,
        START,
        SEND_ADDR,
        ADDR_ACK,
        SEND_DATA,
        DATA_ACK,
        STOP,
        DONE
    } state_t;

    state_t state, nstate;

    // ---------------------------
    // Shift register and bit counter
    // ---------------------------
    logic [7:0] shift;
    logic [2:0] bit_cnt;
    logic ack_bit;

    // ---------------------------
    // FSM state register
    // ---------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= nstate;
    end

    // ---------------------------
    // FSM next state and outputs
    // ---------------------------
    always_comb begin
        nstate = state;
        busy = 1;
        done = 0;
        sda_drive = 0;    // default: release
        ack_error = 0;

        case(state)
            IDLE: begin
                busy = 0;
                if (start) nstate = START;
            end

            START: begin
                sda_drive = 1;  // SDA goes low while SCL high
                if (scl_int)
                    nstate = SEND_ADDR;
            end

            SEND_ADDR: begin
                sda_drive = shift[7] ? 0 : 1;  // drive low if bit = 0
                if (scl_fall && bit_cnt == 0)
                    nstate = ADDR_ACK;
            end

            ADDR_ACK: begin
                sda_drive = 0; // release SDA
                if (scl_rise) begin
                    ack_bit = sda_in;
                    if (ack_bit)
                        ack_error = 1;
                    nstate = SEND_DATA;
                end
            end

            SEND_DATA: begin
                sda_drive = shift[7] ? 0 : 1;
                if (scl_fall && bit_cnt == 0)
                    nstate = DATA_ACK;
            end

            DATA_ACK: begin
                sda_drive = 0;
                if (scl_rise) begin
                    ack_bit = sda_in;
                    if (ack_bit) ack_error = 1;
                    nstate = STOP;
                end
            end

            STOP: begin
                sda_drive = 1; // SDA low first
                if (scl_int)
                    sda_drive = 0; // release SDA → STOP
                nstate = DONE;
            end

            DONE: begin
                done = 1;
                if (!start)
                    nstate = IDLE;
            end
        endcase
    end

    // ---------------------------
    // Bit counter and shift register
    // ---------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 3'd7;
            shift <= 0;
        end else begin
            case(state)
                START: begin
                    shift <= {addr, 1'b0}; // Address + write bit
                    bit_cnt <= 3'd7;
                end
                SEND_ADDR, SEND_DATA: 
				if (scl_rise) begin
                    shift <= {shift[6:0], 1'b0};
                    bit_cnt <= bit_cnt - 1;
                end
                ADDR_ACK: begin
                    shift <= data;
                    bit_cnt <= 3'd7;
                end
            endcase
        end
    end

endmodule
