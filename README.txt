I2C Master-Slave Simulation (FSM Preserved, ACK Fixed)
======================================================

Files:
- i2c_master.v : Master FSM with proper ACK handling
- i2c_slave.v  : Slave FSM with ACK drive when address matches
- i2c_testbench.v : Simulation with matching addresses

Key Fixes:
- Master releases SDA (high-Z) during ACK cycles (ADDR_ACK, DATA_ACK).
- Slave pulls SDA low (0) only when address matches and during ACK cycles.
- Testbench ensures master and slave address = 7'b1010001.

Run (Icarus Verilog):
---------------------
$ iverilog -o i2c_sim i2c_master.v i2c_slave.v i2c_testbench.v
$ vvp i2c_sim
$ gtkwave i2c.vcd

Expected:
- ACK detected (sda low during ACK).
- ack_error should remain 0 if address matches.
