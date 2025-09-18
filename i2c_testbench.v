`timescale 1ns/1ps
module i2c_testbench;

    reg clk, rst, start, rw;
    reg [6:0] addr;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire ack_error, busy;
    wire sda, scl;

    // Pull-ups
    pullup(sda);
    pullup(scl);

    i2c_master uut_master (
        .clk(clk), .rst(rst), .start(start),
        .addr(addr), .data_in(data_in), .rw(rw),
        .data_out(data_out), .ack_error(ack_error),
        .busy(busy), .sda(sda), .scl(scl)
    );

    i2c_slave uut_slave (
        .clk(clk), .rst(rst), .own_addr(7'b1010001),
        .sda(sda), .scl(scl),
        .data_out()
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz system clock
    end

    initial begin
        // Reset
        rst = 1; start = 0; rw = 0; addr = 7'b1010001; data_in = 8'hA5;
        #100 rst = 0;

        // Write transaction
        #200 start = 1; rw = 0; data_in = 8'h3C;
        #20 start = 0;
        wait(!busy);

        // Read transaction
        #500 start = 1; rw = 1;
        #20 start = 0;
        wait(!busy);

        #2000 $stop;
    end
endmodule
