module tb_cpu;

    logic clk;
    logic rst;
    logic [31:0] ProgInstr_i;
    logic [31:0] ProgAddress_o;
    logic [31:0] DataIn_i;
    logic [31:0] DataAddress_o;
    logic [31:0] DataOut_o;
    logic [2:0] DataFunct3_o;
    logic DataWriteEnable_o;
    logic [31:0] program_mem [0:255];

    cpu dut (
        .clk(clk),
        .rst(rst),
        .ProgInstr_i(ProgInstr_i),
        .ProgAddress_o(ProgAddress_o),
        .DataIn_i(DataIn_i),
        .DataAddress_o(DataAddress_o),
        .DataOut_o(DataOut_o),
        .DataFunct3_o(DataFunct3_o),
        .DataWriteEnable_o(DataWriteEnable_o)
    );

    data_mem dmem (
        .clk(clk),
        .WE(DataWriteEnable_o),
        .A(DataAddress_o),
        .WD(DataOut_o),
        .funct3(DataFunct3_o),
        .RD(DataIn_i)
    );

    // La entrada de ROM se indexa por palabra con PC[9:2].
    always_comb ProgInstr_i = program_mem[ProgAddress_o[9:2]];
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #1;
        for (int i = 0; i < 256; i = i + 1)
            program_mem[i] = 32'h00000013;
        program_mem[0] = 32'h00A00093; // addi x1, x0, 10
        program_mem[1] = 32'h00300113; // addi x2, x0, 3
        program_mem[2] = 32'h002081B3; // add x3, x1, x2
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;
    end

    // $display usa especificadores como %h y %b para dar formato a las señales.
    always @(posedge clk) begin
        if (!rst) begin
            $display("\n==============================");
            $display("CYCLE");
            $display("PC      = %h", ProgAddress_o);
            $display("Instr   = %h", ProgInstr_i);
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

    initial begin
        $dumpfile("sim/wave.vcd");
        $dumpvars(0, tb_cpu);
        repeat (20) @(posedge clk);
        $finish;
    end

endmodule