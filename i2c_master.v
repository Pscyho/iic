module i2c_master (
    input  wire clk,         // system clock (100 MHz)
    input  wire rst,
    input  wire start,
    input  wire [6:0] addr,
    input  wire [7:0] data_in,
    input  wire rw,              // 0 = write, 1 = read
    output reg  [7:0] data_out,
    output reg ack_error,
    output reg busy,
    inout  wire sda,
    inout  wire scl
);

    // open-drain drivers
    reg sda_out, sda_oe;
    reg scl_out, scl_oe;

    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;

    // clock divider for 100kHz SCL from 100MHz clk
    parameter DIVIDER = 500;
    reg [15:0] cnt;
    reg scl_clk;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            scl_clk <= 1;
        end else begin
            if (cnt == DIVIDER-1) begin
                cnt <= 0;
                scl_clk <= ~scl_clk;
            end else
                cnt <= cnt + 1;
        end
    end

    // FSM states
    reg [3:0] state;
    reg [3:0] bitcnt;
    reg [7:0] shifter;

    localparam IDLE=0, START=1, SEND_ADDR=2, ADDR_ACK=3,
               SEND_DATA=4, DATA_ACK=5, READ_DATA=6, READ_ACK=7,
               STOP=8;

    always @(posedge scl_clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            ack_error <= 0;
            sda_out <= 1;
            sda_oe <= 1;
            scl_out <= 1;
            scl_oe <= 0;
            data_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 0;
                    sda_oe <= 1; sda_out <= 1;
                    if (start) begin
                        busy <= 1;
                        state <= START;
                    end
                end

                START: begin
                    sda_oe <= 1; sda_out <= 0; // START condition
                    shifter <= {addr, rw};
                    bitcnt <= 7;
                    state <= SEND_ADDR;
                end

                SEND_ADDR: begin
                    sda_oe <= 1;
                    sda_out <= shifter[bitcnt];
                    if (bitcnt == 0) state <= ADDR_ACK;
                    else bitcnt <= bitcnt - 1;
                end

                ADDR_ACK: begin
                    sda_oe <= 0; // release for ACK
                    if (sda == 0) begin
                        ack_error <= 0;
                        if (rw == 0) begin
                            shifter <= data_in;
                            bitcnt <= 7;
                            state <= SEND_DATA;
                        end else begin
                            bitcnt <= 7;
                            state <= READ_DATA;
                        end
                    end else begin
                        ack_error <= 1;
                        state <= STOP;
                    end
                end

                SEND_DATA: begin
                    sda_oe <= 1;
                    sda_out <= shifter[bitcnt];
                    if (bitcnt == 0) state <= DATA_ACK;
                    else bitcnt <= bitcnt - 1;
                end

                DATA_ACK: begin
                    sda_oe <= 0; // release
                    if (sda == 0) ack_error <= 0;
                    else ack_error <= 1;
                    state <= STOP;
                end

                READ_DATA: begin
                    sda_oe <= 0; // slave drives
                    data_out[bitcnt] <= sda;
                    if (bitcnt == 0) state <= READ_ACK;
                    else bitcnt <= bitcnt - 1;
                end

                READ_ACK: begin
                    sda_oe <= 1; sda_out <= 1; // NACK for 1 byte
                    state <= STOP;
                end

                STOP: begin
                    sda_oe <= 1; sda_out <= 1; // STOP
                    busy <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
