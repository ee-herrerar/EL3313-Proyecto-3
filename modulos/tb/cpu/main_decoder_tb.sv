module main_decoder_tb;
    logic [6:0] op; logic [2:0] funct3; logic Jump, RegWrite, MemWrite, ALUSrc, Branch, BranchNE, BranchGE, BranchLT; logic [1:0] ResultSrc, ALUOp; logic [3:0] ImmSrc;
    main_decoder dut (.*);
    initial begin
        op = 7'b0110011; funct3 = 0; #1; assert (RegWrite && !MemWrite && !ALUSrc) else $fatal(1, "R-type decode failed");
        op = 7'b0100011; #1; assert (MemWrite && ALUSrc && ImmSrc == 4'b0001) else $fatal(1, "store decode failed");
        op = 7'b1101111; #1; assert (Jump && RegWrite && ImmSrc == 4'b0011) else $fatal(1, "JAL decode failed");
        $display("main_decoder_tb: PASS"); $finish;
    end
endmodule
