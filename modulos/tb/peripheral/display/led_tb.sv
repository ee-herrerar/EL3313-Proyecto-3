`timescale 1ns/1ps
module led_tb;
    logic clk_i = 0, rst_i = 1, write_enable_i = 0;
    logic [1:0] addr_i = 0;
    logic [31:0] wdata_i = 0, rdata_o;
    logic [15:0] led;
    led_perifico dut (.*);
    always #5 clk_i = ~clk_i;

    initial begin
        repeat (2) @(posedge clk_i);
        #1; assert (led == 16'b1) else $fatal(1, "LED reset state failed");
        rst_i = 0; write_enable_i = 1; wdata_i = 32'd1;
        @(posedge clk_i); #1; write_enable_i = 0;
        assert (rdata_o == 32'd1) else $fatal(1, "LED register mismatch");
        assert (led == 16'b10) else $fatal(1, "LED battle state mismatch");
        $display("led_tb: PASS");
        $finish;
    end
endmodule
