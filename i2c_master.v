module i2c_master (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [6:0] addr,
    input  wire [7:0] data_in,
    input  wire rw,              // 0 = write, 1 = read
    output reg  [7:0] data_out,
    output reg ack_error,
    output reg busy,
    inout  wire sda,
    output reg scl
);

    reg [3:0] state;
    reg [3:0] bitcnt;
    reg [7:0] shifter;
    reg sda_out;
    reg sda_dir; // 1 = drive, 0 = release (high-Z)

    assign sda = (sda_dir) ? sda_out : 1'bz;

    localparam IDLE=0, START=1, SEND_ADDR=2, ADDR_ACK=3,
               SEND_DATA=4, DATA_ACK=5, STOP=6;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            scl <= 1;
            sda_out <= 1;
            sda_dir <= 1;
            ack_error <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 0;
                    if (start) begin
                        busy <= 1;
                        state <= START;
                    end
                end

                START: begin
                    sda_dir <= 1;
                    sda_out <= 0; // START condition
                    shifter <= {addr, rw};
                    bitcnt <= 7;
                    state <= SEND_ADDR;
                end

                SEND_ADDR: begin
                    scl <= 0;
                    sda_dir <= 1;
                    sda_out <= shifter[bitcnt];
                    if (bitcnt == 0) state <= ADDR_ACK;
                    else bitcnt <= bitcnt - 1;
                    scl <= 1;
                end

                ADDR_ACK: begin
                    sda_dir <= 0; // release SDA for ACK
                    scl <= 1;
                    if (sda == 0) begin
                        ack_error <= 0;
                        shifter <= data_in;
                        bitcnt <= 7;
                        state <= SEND_DATA;
                    end else begin
                        ack_error <= 1;
                        state <= STOP;
                    end
                end

                SEND_DATA: begin
                    scl <= 0;
                    sda_dir <= 1;
                    sda_out <= shifter[bitcnt];
                    if (bitcnt == 0) state <= DATA_ACK;
                    else bitcnt <= bitcnt - 1;
                    scl <= 1;
                end

                DATA_ACK: begin
                    sda_dir <= 0; // release SDA for ACK
                    scl <= 1;
                    if (sda == 0) ack_error <= 0;
                    else ack_error <= 1;
                    state <= STOP;
                end

                STOP: begin
                    scl <= 1;
                    sda_dir <= 1;
                    sda_out <= 0;
                    sda_out <= 1; // STOP condition
                    busy <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
