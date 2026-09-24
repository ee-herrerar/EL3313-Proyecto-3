module PCPlus4_tb;

    logic [31:0] PC;
    logic [31:0] PCPlus4;

    int errors = 0;

    PCPlus4 uut (
        .PC(PC),
        .PCPlus4(PCPlus4)
    );

    task check;
        input [31:0] expected;
        input string name;
    begin
        #10;
        if (PCPlus4 !== expected) begin
            $display("ERROR %s | PCPlus4=%h esperado=%h", name, PCPlus4, expected);
            errors++;
        end else begin
            $display("%s OK", name);
        end
    end
    endtask

    initial begin
        $dumpfile("pcplus4.vcd");
        $dumpvars(0, PCPlus4_tb);
    end

    initial begin
        PC = 32'h00000000;
        check(32'h00000004, "PC 0");

        PC = 32'h00000004;
        check(32'h00000008, "PC 4");

        PC = 32'h00000020;
        check(32'h00000024, "PC 20");

        PC = 32'h00001000;
        check(32'h00001004, "PC 1000");

        if (errors == 0)
            $display("TODOS LOS TESTS DE PCPlus4 PASARON");
        else
            $display("FALLARON %0d TESTS", errors);

        $finish;
    end

endmodule