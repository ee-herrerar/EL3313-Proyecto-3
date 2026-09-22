module tb_lw;

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

        $dumpfile("wave_lw.vcd");
        $dumpvars(0, tb_lw);

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
        // TEST LW
        // ==========================
        funct3 = 3'b010;

        #10;

        if (RD !== 32'hAABBCCDD) begin
            $display("ERROR LW: RD = %h", RD);
            $fatal;
        end
        else
            $display("OK LW: RD = %h", RD);

            $finish;
    end 
endmodule