module MemoryMux_tb;

    logic [31:0] ReadData;
    logic        ResultSrc;
    logic [31:0] ALUResult;
    logic [31:0] Result;

    int errors = 0;

    MemoryMux uut (
        .ReadData(ReadData),
        .ResultSrc(ResultSrc),
        .ALUResult(ALUResult),
        .Result(Result)
    );

    task check;
        input [31:0] expected;
        input string name;
    begin
        #10;
        if (Result !== expected) begin
            $display("ERROR %s | Result=%h esperado=%h", name, Result, expected);
            errors++;
        end else begin
            $display("%s OK", name);
        end
    end
    endtask

    initial begin
        $dumpfile("memorymux.vcd");
        $dumpvars(0, MemoryMux_tb);
    end

    initial begin
        ALUResult = 32'h00000015;
        ReadData  = 32'h000000AA;
        ResultSrc = 1'b0;
        check(32'h00000015, "Selecciona ALUResult");

        ResultSrc = 1'b1;
        check(32'h000000AA, "Selecciona ReadData");

        ALUResult = 32'h12345678;
        ReadData  = 32'hDEADBEEF;
        ResultSrc = 1'b0;
        check(32'h12345678, "ALUResult cambio");

        ResultSrc = 1'b1;
        check(32'hDEADBEEF, "ReadData cambio");

        if (errors == 0)
            $display("TODOS LOS TESTS DE MemoryMux PASARON");
        else
            $display("FALLARON %0d TESTS", errors);

        $finish;
    end

endmodule