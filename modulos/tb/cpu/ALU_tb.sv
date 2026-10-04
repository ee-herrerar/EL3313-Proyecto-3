module ALU_tb;

    // Señales
    logic [31:0] SrcA;
    logic [31:0] SrcB;
    logic [3:0]  ALUControl;
    logic [31:0] ALUResult;
    logic        zero, less;

    // Instancia de la ALU
    ALU uut (
        .SrcA(SrcA),
        .SrcB(SrcB),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .zero(zero),
        .less(less)
    );

    // Contador de errores
    int errors = 0;

    // Task para verificar
    task check;
        input [31:0] expected_result;
        input expected_zero;
        input expected_less;
        input string test_name;
    begin
        if (ALUResult !== expected_result || zero !== expected_zero ||
            less !== expected_less) begin
            $display(" ERROR en %s | Resultado=%h (esperado=%h) | zero=%b (esperado=%b) | less=%b (esperado=%b)",
                      test_name, ALUResult, expected_result, zero, expected_zero,
                      less, expected_less);
            errors++;
        end else begin
            $display("%s OK", test_name);
        end
    end
    endtask

    // Dump para waveform
    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, ALU_tb);
    end

    // Pruebas
    initial begin

        // ADD
        SrcA = 10; SrcB = 5; ALUControl = 4'b0000; #10;
        check(15, 0, 0, "ADD");

        // SUB
        SrcA = 10; SrcB = 10; ALUControl = 4'b0001; #10;
        check(0, 1, 0, "SUB");

        // AND
        SrcA = 8; SrcB = 4; ALUControl = 4'b0010; #10;
        check(0, 1, 0, "AND");

        // OR
        SrcA = 8; SrcB = 4; ALUControl = 4'b0011; #10;
        check(12, 0, 0, "OR");

        // XOR
        SrcA = 5; SrcB = 5; ALUControl = 4'b0100; #10;
        check(0, 1, 0, "XOR");

        // SLT (signed)
        SrcA = -5; SrcB = 3; ALUControl = 4'b0101; #10;
        check(1, 0, 1, "SLT");

        // SLTU (unsigned)
        SrcA = 5; SrcB = 10; ALUControl = 4'b1011; #10;
        check(1, 0, 1, "SLTU positivo");

        // El bit alto activa el caso que distingue la comparación unsigned.
        SrcA = -1; SrcB = 1; ALUControl = 4'b1011; #10;
        check(0, 1, 1, "SLTU con operando negativo");

        // SLL
        SrcA = 1; SrcB = 2; ALUControl = 4'b0110; #10;
        check(4, 0, 0, "SLL");

        // SRL
        SrcA = 8; SrcB = 2; ALUControl = 4'b1000; #10;
        check(2, 0, 0, "SRL");

        // SRA
        SrcA = -8; SrcB = 2; ALUControl = 4'b1001; #10;
        check(-2, 0, 1, "SRA");

        // Resultado final
        if (errors == 0) begin
            $display("\n TODOS LOS TESTS PASARON ");
        end else begin
            $fatal(1, "FALLARON %0d TESTS", errors);
        end

        $finish;
    end

endmodule
