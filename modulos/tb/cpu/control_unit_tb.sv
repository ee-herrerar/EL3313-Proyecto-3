module control_unit_tb;
    logic [6:0] op, funct7; logic [2:0] funct3; logic zero, less;
    logic RegWrite, ALUSrc, MemWrite; logic [1:0] ResultSrc, PCSrc; logic [3:0] ImmSrc, ALUControl;
    control_unit dut (.*);
    initial begin
        zero = 0; less = 0; funct7 = 0; funct3 = 0;
        op = 7'b1100011; #1; assert (PCSrc == 0) else $fatal(1, "BEQ false branch failed");
        zero = 1; #1; assert (PCSrc == 1) else $fatal(1, "BEQ true branch failed");
        op = 7'b1100111; #1; assert (PCSrc == 2) else $fatal(1, "JALR select failed");
        $display("control_unit_tb: PASS"); $finish;
    end
endmodule
