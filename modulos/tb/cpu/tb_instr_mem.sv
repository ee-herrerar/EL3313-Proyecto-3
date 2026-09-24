module tb_instr_mem;

    logic [31:0] A;
    logic [31:0] RD;

    instr_mem dut (
        .A(A),
        .RD(RD)
    );

    initial begin
        // Sobrescribimos memoria directamente para no depender de program.hex
        dut.mem[0] = 32'h12345678;
        dut.mem[1] = 32'hAABBCCDD;
        dut.mem[2] = 32'h00000013; // nop en RISC-V: addi x0,x0,0
        dut.mem[3] = 32'hFFFFFFFF;

        // PC = 0 -> mem[0]
        A = 32'd0;
        #1;
        if (RD !== 32'h12345678) begin
            $display("ERROR PC=0: RD=%h", RD);
            $fatal;
        end else $display("OK PC=0");

        // PC = 4 -> mem[1]
        A = 32'd4;
        #1;
        if (RD !== 32'hAABBCCDD) begin
            $display("ERROR PC=4: RD=%h", RD);
            $fatal;
        end else $display("OK PC=4");

        // PC = 8 -> mem[2]
        A = 32'd8;
        #1;
        if (RD !== 32'h00000013) begin
            $display("ERROR PC=8: RD=%h", RD);
            $fatal;
        end else $display("OK PC=8");

        // PC = 12 -> mem[3]
        A = 32'd12;
        #1;
        if (RD !== 32'hFFFFFFFF) begin
            $display("ERROR PC=12: RD=%h", RD);
            $fatal;
        end else $display("OK PC=12");

        $display("TODOS LOS TESTS DE INSTRUCTION MEMORY PASARON");
        $finish;
    end

endmodule