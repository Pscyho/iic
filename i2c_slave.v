module i2c_slave (
    input  wire rst,
    input  wire [6:0] own_addr,
    inout  wire sda,
    input  wire scl,
    output reg [7:0] data_out
);

    reg [3:0] bitcnt;
    reg [7:0] shifter;
    reg sda_out, sda_oe;
    reg addr_phase;
    reg addr_match;
    reg rw_bit;
    reg [7:0] mem;

    assign sda = sda_oe ? sda_out : 1'bz;

    always @(posedge scl or posedge rst) begin
        if (rst) begin
            bitcnt <= 0;
            addr_phase <= 1;
            addr_match <= 0;
            sda_oe <= 0;
            data_out <= 0;
            mem <= 8'h55;
        end else begin
            if (addr_phase) begin
                shifter[bitcnt] <= sda;
                if (bitcnt == 7) begin
                    if (shifter[7:1] == own_addr) addr_match <= 1;
                    else addr_match <= 0;
                    rw_bit <= shifter[0];
                    addr_phase <= 0;
                    bitcnt <= 0;
                    if (addr_match) begin
                        sda_oe <= 1; sda_out <= 0; // ACK
                    end
                end else bitcnt <= bitcnt + 1;
            end else begin
                if (rw_bit == 0) begin
                    // write
                    shifter[bitcnt] <= sda;
                    if (bitcnt == 7) begin
                        data_out <= shifter;
                        mem <= shifter;
                        bitcnt <= 0;
                        if (addr_match) begin
                            sda_oe <= 1; sda_out <= 0; // ACK
                        end
                    end else bitcnt <= bitcnt + 1;
                end else begin
                    // read
                    sda_oe <= 1; sda_out <= mem[bitcnt];
                    if (bitcnt == 0) bitcnt <= 7;
                    else bitcnt <= bitcnt - 1;
                end
            end
        end
    end

    always @(negedge scl) begin
        sda_oe <= 0;
    end
endmodule
