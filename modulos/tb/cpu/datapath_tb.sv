`timescale 1ns/1ps
module datapath_tb;
    logic clk = 0, rst = 1, RegWrite = 0, ALUSrc = 0, MemWrite = 0;
    logic [1:0] ResultSrc = 0, PCSrc = 0;
    logic [3:0] ALUControl = 0, ImmSrc = 0;
    logic [31:0] PC, Instr; logic zero, less;
    datapath dut (.*);
    always #5 clk = ~clk;
    initial begin
        dut.u_imem.mem[0] = 32'h00000013;
        repeat (2) @(posedge clk); #1; assert (PC == 0) else $fatal(1, "datapath reset failed");
        rst = 0; @(posedge clk); #1; assert (PC == 4) else $fatal(1, "datapath PC increment failed");
        $display("datapath_tb: PASS"); $finish;
    end
endmodule
