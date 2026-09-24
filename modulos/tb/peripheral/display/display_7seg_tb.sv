`timescale 1ns/1ps
module display_7seg_tb;
    logic clk_i = 0, rst_i = 1, write_enable_i = 0;
    logic [1:0] addr_i = 0;
    logic [31:0] wdata_i = 0, rdata_o;
    logic [3:0] an;
    logic dp;
    logic [6:0] seg;
    display_7seg dut (.*);
    always #5 clk_i = ~clk_i;

    initial begin
        repeat (2) @(posedge clk_i);
        #1; assert (rdata_o == 0) else $fatal(1, "display reset failed");
        rst_i = 0; write_enable_i = 1; wdata_i = 32'h0000_4321;
        @(posedge clk_i); #1;
        write_enable_i = 0;
        #1; assert (rdata_o == 32'h0000_4321) else $fatal(1, "display register mismatch");
        addr_i = 2'b01; #1; assert (rdata_o == 0) else $fatal(1, "display invalid address");
        $display("display_7seg_tb: PASS");
        $finish;
    end
endmodule
