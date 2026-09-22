module tb_lbu;

    logic [2:0]  funct3;
    logic        clk;
    logic        WE;
    logic [31:0] A;
    logic [31:0] WD;
    logic [31:0] RD;

    data_mem dut (
        .funct3(funct3),
        .clk(clk),
        .WE(WE),
        .A(A),
        .WD(WD),
        .RD(RD)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin

        $dumpfile("wave_lbu.vcd");
        $dumpvars(0, tb_lbu);

        clk = 0;
        WE  = 0;
        A   = 32'd0;
        WD  = 32'd0;

        // ==========================
        // Inicializar memoria
        // ==========================
        // mem[0] = 0xAABBCCDD
        dut.mem[0] = 32'hAABBCCDD;

        #10;

        // ==========================
        // TEST LBU
        // ==========================
        funct3 = 3'b100;

        #10;

        if (RD !== 32'h000000DD) begin
            $display("ERROR LBU: RD = %h", RD);
            $fatal;
        end
        else
            $display("OK LBU: RD = %h", RD);

            $finish;
    end
endmodule