module ALUMux_tb;

    // Señales
    logic [31:0] RD2;
    logic        ALUSrc;
    logic [31:0] ImmExt;
    logic [31:0] SrcB;

    // Instancia del MUX
    ALUMux uut (
        .RD2(RD2),
        .ALUSrc(ALUSrc),
        .ImmExt(ImmExt),
        .SrcB(SrcB)
    );

    int errors = 0;

    // Task de verificación
    task check;
        input [31:0] expected;
        input string name;
    begin
        if (SrcB !== expected) begin
            $display("ERROR %s | SrcB=%0d esperado=%0d", name, SrcB, expected);
            errors++;
        end else begin
            $display("%s OK", name);
        end
    end
    endtask

    // Waveform
    initial begin
        $dumpfile("mux.vcd");
        $dumpvars(0, ALUMux_tb);
    end

    // Tests
    initial begin

        // Caso 1: ALUSrc = 0 → RD2
        RD2 = 32'd10;
        ImmExt = 32'd99;
        ALUSrc = 0;
        #10;
        check(10, "MUX RD2");

        // Caso 2: ALUSrc = 1 → ImmExt
        RD2 = 32'd10;
        ImmExt = 32'd99;
        ALUSrc = 1;
        #10;
        check(99, "MUX IMM");

        // Caso 3: valores negativos
        RD2 = -5;
        ImmExt = 20;
        ALUSrc = 0;
        #10;
        check(-5, "MUX NEG RD2");

        ALUSrc = 1;
        #10;
        check(20, "MUX NEG IMM");

        // Resultado final
        if (errors == 0)
            $display("TODOS LOS TESTS DEL MUX PASARON");
        else
            $display("FALLARON %0d TESTS ", errors);

        $finish;
    end

endmodule