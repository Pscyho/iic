module i2c_slave (
    input  wire clk,
    input  wire rst,
    input  wire [6:0] own_addr,
    inout  wire sda,
    input  wire scl,
    output reg [7:0] data_out
);
    reg [3:0] bitcnt;
    reg [7:0] shifter;
    reg sda_out;
    reg sda_dir;
    reg addr_phase;
    reg addr_match;

    assign sda = (sda_dir) ? sda_out : 1'bz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bitcnt <= 0;
            addr_phase <= 1;
            addr_match <= 0;
            sda_dir <= 0;
            data_out <= 0;
        end else begin
            if (scl) begin
                if (addr_phase) begin
                    shifter[bitcnt] <= sda;
                    if (bitcnt == 7) begin
                        if (shifter[7:1] == own_addr) addr_match <= 1;
                        else addr_match <= 0;
                        addr_phase <= 0;
                        bitcnt <= 0;
                        // Drive ACK if match
                        if (addr_match) begin
                            sda_dir <= 1;
                            sda_out <= 0;
                        end
                    end else bitcnt <= bitcnt + 1;
                end else begin
                    shifter[bitcnt] <= sda;
                    if (bitcnt == 7) begin
                        data_out <= shifter;
                        bitcnt <= 0;
                        // Drive ACK
                        if (addr_match) begin
                            sda_dir <= 1;
                            sda_out <= 0;
                        end
                    end else bitcnt <= bitcnt + 1;
                end
            end else begin
                sda_dir <= 0; // release when clock low
            end
        end
    end
endmodule
