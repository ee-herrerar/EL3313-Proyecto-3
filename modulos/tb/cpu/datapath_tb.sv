`timescale 1ns/1ps
module datapath_tb;
    logic clk = 0, rst = 1, RegWrite = 0, ALUSrc = 0, MemWrite = 0;
    logic [1:0] ResultSrc = 0, PCSrc = 0;
    logic [3:0] ALUControl = 0, ImmSrc = 0;
    logic [31:0] PC, Instr; logic zero, less;
    logic [31:0] ProgInstr_i = 32'h00000013, DataReadData_i = 0;
    logic [31:0] DataAddress_o, DataWriteData_o;
    logic [2:0] DataFunct3_o;
    logic DataWriteEnable_o;
    datapath #(.EXTERNAL_MEMORY(1'b1)) dut (.*);
    always #5 clk = ~clk;
    initial begin
        // .* conecta por nombre cada señal que comparte nombre con un puerto.
        repeat (2) @(posedge clk); #1; assert (PC == 0) else $fatal(1, "datapath reset failed");
        rst = 0;
        repeat (2) @(posedge clk); #1;
        assert (PC == 4) else $fatal(1, "datapath PC increment failed");
        $display("datapath_tb: PASS"); $finish;
    end
endmodule
