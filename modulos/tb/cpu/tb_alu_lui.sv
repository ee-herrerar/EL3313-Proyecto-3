module tb_alu_lui;

    logic [31:0] SrcA;
    logic [31:0] SrcB;
    logic [3:0]  ALUControl;
    logic [31:0] ALUResult;
    logic zero;
    logic less;

    initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_alu_lui);
    end

    ALU dut (
        .SrcA(SrcA),
        .SrcB(SrcB),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .zero(zero),
        .less(less)
    );

    initial begin
        SrcA = 32'hDEADBEEF;
        SrcB = 32'h12345000;
        ALUControl = 4'b1010; // Pasa directo SrcB para LUI

        #10;

        if (ALUResult !== 32'h12345000) begin
            $display("ERROR: LUI PASS B fallo. ALUResult = %h", ALUResult);
            $fatal;
        end else begin
            $display("OK: LUI PASS B funciona. ALUResult = %h", ALUResult);
        end

        $finish;
    end

endmodule