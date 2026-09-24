`timescale 1ns/1ps
module pc_tb;
    logic clk = 0, rst = 1; logic [31:0] PCnext = 0, PC;
    pc dut (.*);
    always #5 clk = ~clk;
    initial begin
        @(posedge clk); #1; assert (PC == 0) else $fatal(1, "PC reset failed");
        rst = 0; PCnext = 32'h100; @(posedge clk); #1;
        assert (PC == 32'h100) else $fatal(1, "PC update failed");
        $display("pc_tb: PASS"); $finish;
    end
endmodule
