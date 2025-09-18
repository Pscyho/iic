`timescale 1ns/1ps
module i2c_testbench;

    reg clk, rst, start, rw;
    reg [6:0] addr;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire ack_error, busy;
    wire sda, scl;

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
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1; start = 0; rw = 0; addr = 7'b1010001; data_in = 8'hA5;
        #20 rst = 0;
        #20 start = 1;
        #10 start = 0;
        #500 $stop;
    end

    initial begin
        $dumpfile("i2c.vcd");
        $dumpvars(0, i2c_testbench);
    end
endmodule
