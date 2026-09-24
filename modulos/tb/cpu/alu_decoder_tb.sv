module alu_decoder_tb;
    logic [1:0] ALUOp; logic [2:0] funct3; logic [6:0] funct7; logic [3:0] ALUControl;
    alu_decoder dut (.*);
    initial begin
        ALUOp = 2'b00; funct3 = 0; funct7 = 0; #1; assert (ALUControl == 0) else $fatal(1, "load/store decode failed");
        ALUOp = 2'b10; funct3 = 3'b111; #1; assert (ALUControl == 4'b0010) else $fatal(1, "AND decode failed");
        funct3 = 3'b000; funct7 = 7'b0100000; #1; assert (ALUControl == 4'b0001) else $fatal(1, "SUB decode failed");
        $display("alu_decoder_tb: PASS"); $finish;
    end
endmodule
