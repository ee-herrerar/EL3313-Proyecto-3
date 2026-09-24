module tb_cpu;

    logic clk;
    logic rst;

    // Instancia CPU
    cpu dut(
        .clk(clk),
        .rst(rst)
    );

    // ======================
    // Clock
    // ======================
    initial clk = 0;
    always #5 clk = ~clk; // periodo = 10

    // ======================
    // Reset
    // ======================
    initial begin
        rst = 1;
        repeat (2) @(posedge clk); // 2 ciclos en reset
        rst = 0;
    end

    // ======================
    // MONITOR POR CICLO
    // ======================
    always @(posedge clk) begin
        if (!rst) begin
            $display("\n==============================");
            $display("CYCLE");
            $display("PC      = %h", dut.PC);
            $display("Instr   = %h", dut.Instr);
            $display("RS1     = %0d", dut.dp.RD1);
            $display("RS2     = %0d", dut.dp.RD2);
            $display("ALURes  = %0d", dut.dp.ALUResult);
            $display("Result  = %0d", dut.dp.Result);
            $display("zero    = %b", dut.zero);

            $display("---- REGISTERS ----");
            $display("x1=%0d x2=%0d x3=%0d x4=%0d",
                dut.dp.u_regfile.regs[1],
                dut.dp.u_regfile.regs[2],
                dut.dp.u_regfile.regs[3],
                dut.dp.u_regfile.regs[4]);

            $display("x5=%0d x6=%0d x7=%0d x8=%0d",
                dut.dp.u_regfile.regs[5],
                dut.dp.u_regfile.regs[6],
                dut.dp.u_regfile.regs[7],
                dut.dp.u_regfile.regs[8]);

            // DEBUG CONTROL
            $display("Branch=%b BranchNE=%b Jump=%b PCSrc=%b",
                dut.cu.Branch,
                dut.cu.BranchNE,
                dut.cu.Jump,
                dut.cu.PCSrc);
                $display("ImmExt = %0d", dut.dp.ImmExt);
                $display("PCTarget = %h", dut.dp.PCTarget);
                $display("ImmSrc = %b", dut.dp.ImmSrc);
        end
    end

    // ======================
    // FINALIZACIÓN
    // ======================
    initial begin
        $dumpfile("sim/wave.vcd");
        $dumpvars(0, tb_cpu);
        repeat (20) @(posedge clk); // corre 20 ciclos
        $finish;
    end

endmodule