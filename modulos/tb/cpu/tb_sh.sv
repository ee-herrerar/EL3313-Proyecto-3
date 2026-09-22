module tb_sh;

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

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        WE = 0;
        A = 32'd0;
        WD = 32'd0;
        funct3 = 3'b010;

        dut.mem[0] = 32'hAABBCCDD;

        #10;

        funct3 = 3'b001;      // sh
        A = 32'd0;
        WD = 32'h00001122;
        WE = 1;

        #10;
        WE = 0;

        if (dut.mem[0] !== 32'hAABB1122) begin
            $display("ERROR SH: mem[0] = %h", dut.mem[0]);
            $fatal;
        end else begin
            $display("OK SH: mem[0] = %h", dut.mem[0]);
        end

        $finish;
    end

endmodule