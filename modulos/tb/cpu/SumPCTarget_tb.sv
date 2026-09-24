module SumPCTarget_tb;

    logic [31:0] PC;
    logic [31:0] ImmExt;
    logic [31:0] PCTarget;

    int errors = 0;

    SumPCTarget uut (
        .PC(PC),
        .ImmExt(ImmExt),
        .PCTarget(PCTarget)
    );

    task check;
        input [31:0] expected;
        input string name;
    begin
        #10;
        if (PCTarget !== expected) begin
            $display("ERROR %s | PCTarget=%h esperado=%h", name, PCTarget, expected);
            errors++;
        end else begin
            $display("%s OK", name);
        end
    end
    endtask

    initial begin
        $dumpfile("sum_pctarget.vcd");
        $dumpvars(0, SumPCTarget_tb);
    end

    initial begin
        PC = 32'h00000000;
        ImmExt = 32'h00000004;
        check(32'h00000004, "PC + 4");

        PC = 32'h00000020;
        ImmExt = 32'h00000010;
        check(32'h00000030, "Branch forward");

        PC = 32'h00000020;
        ImmExt = 32'hFFFFFFF8;
        check(32'h00000018, "Branch backward");

        PC = 32'h00001000;
        ImmExt = 32'h00000800;
        check(32'h00001800, "JAL forward");

        PC = 32'h00001000;
        ImmExt = 32'hFFFFF800;
        check(32'h00000800, "JAL backward");

        if (errors == 0)
            $display("TODOS LOS TESTS DE SumPCTarget PASARON");
        else
            $display("FALLARON %0d TESTS", errors);

        $finish;
    end

endmodule