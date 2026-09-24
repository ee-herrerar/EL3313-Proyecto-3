module Extend_tb;

    logic [31:0] Instr;
    logic [3:0]  ImmSrc;
    logic [31:0] ImmExt;

    int errors = 0;

    Extend uut (
        .Instr(Instr),
        .ImmSrc(ImmSrc),
        .ImmExt(ImmExt)
    );

    task check;
        input [31:0] expected;
        input string name;
    begin
        #10;
        if (ImmExt !== expected) begin
            $display("ERROR %s | ImmExt=%h esperado=%h", name, ImmExt, expected);
            errors++;
        end else begin
            $display("%s OK", name);
        end
    end
    endtask

    initial begin
        $dumpfile("extend.vcd");
        $dumpvars(0, Extend_tb);
    end

    initial begin

        // I-type positivo: imm = 0x123
        Instr = 32'h12300000;
        ImmSrc = 4'b0000;
        check(32'h00000123, "I-type positivo");

        // I-type negativo: imm = -1
        Instr = 32'hFFF00000;
        ImmSrc = 4'b0000;
        check(32'hFFFFFFFF, "I-type negativo");

        // S-type positivo: imm = 0x024
        Instr = 32'h02000200;
        ImmSrc = 4'b0001;
        check(32'h00000024, "S-type positivo");

        // S-type negativo: imm = -1
        Instr = 32'hFE000F80;
        ImmSrc = 4'b0001;
        check(32'hFFFFFFFF, "S-type negativo");

        // B-type positivo: imm = 16
        Instr = 32'h00000800;
        ImmSrc = 4'b0010;
        check(32'h00000010, "B-type positivo");

        // B-type negativo: imm = -2
        Instr = 32'hFE000F80;
        ImmSrc = 4'b0010;
        check(32'hFFFFFFFE, "B-type negativo");

        // J-type positivo: imm = 2048
        Instr = 32'h00100000;
        ImmSrc = 4'b0011;
        check(32'h00000800, "J-type positivo");

        // J-type negativo: imm = -2
        Instr = 32'hFFFFF000;
        ImmSrc = 4'b0011;
        check(32'hFFFFFFFE, "J-type negativo");

        // U-type
        Instr = 32'h12345000;
        ImmSrc = 4'b0100;
        check(32'h12345000, "U-type");

        // default
        Instr = 32'hFFFFFFFF;
        ImmSrc = 4'b1111;
        check(32'h00000000, "default");

        if (errors == 0)
            $display("TODOS LOS TESTS DEL EXTEND PASARON");
        else
            $display("FALLARON %0d TESTS", errors);

        $finish;
    end

endmodule