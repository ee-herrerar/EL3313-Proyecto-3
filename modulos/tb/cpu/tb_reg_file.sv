module tb_reg_file;

    logic clk;
    logic WE3;
    logic [4:0] A1, A2, A3;
    logic [31:0] WD3;
    logic [31:0] RD1, RD2;

    reg_file dut (
        .clk(clk),
        .WE3(WE3),
        .A1(A1),
        .A2(A2),
        .A3(A3),
        .WD3(WD3),
        .RD1(RD1),
        .RD2(RD2)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        WE3 = 0;
        A1 = 0;
        A2 = 0;
        A3 = 0;
        WD3 = 0;

        // TEST 1: x0 siempre debe ser 0
        #10;
        A1 = 5'd0;
        A2 = 5'd0;
        #1;

        if (RD1 !== 32'd0 || RD2 !== 32'd0) begin
            $display("ERROR x0 inicial: RD1=%h RD2=%h", RD1, RD2);
            $fatal;
        end else begin
            $display("OK x0 inicial");
        end

        // TEST 2: escribir en x5
        A3 = 5'd5;
        WD3 = 32'h12345678;
        WE3 = 1;
        #10;
        WE3 = 0;

        A1 = 5'd5;
        #1;

        if (RD1 !== 32'h12345678) begin
            $display("ERROR escritura x5: RD1=%h", RD1);
            $fatal;
        end else begin
            $display("OK escritura/lectura x5");
        end

        // TEST 3: escribir en x10 y leer por RD2
        A3 = 5'd10;
        WD3 = 32'hAABBCCDD;
        WE3 = 1;
        #10;
        WE3 = 0;

        A2 = 5'd10;
        #1;

        if (RD2 !== 32'hAABBCCDD) begin
            $display("ERROR escritura x10: RD2=%h", RD2);
            $fatal;
        end else begin
            $display("OK escritura/lectura x10");
        end

        // TEST 4: dos lecturas simultáneas
        A1 = 5'd5;
        A2 = 5'd10;
        #1;

        if (RD1 !== 32'h12345678 || RD2 !== 32'hAABBCCDD) begin
            $display("ERROR doble lectura: RD1=%h RD2=%h", RD1, RD2);
            $fatal;
        end else begin
            $display("OK doble lectura");
        end

        // TEST 5: intentar escribir en x0
        A3 = 5'd0;
        WD3 = 32'hFFFFFFFF;
        WE3 = 1;
        #10;
        WE3 = 0;

        A1 = 5'd0;
        #1;

        if (RD1 !== 32'd0) begin
            $display("ERROR escritura en x0: RD1=%h", RD1);
            $fatal;
        end else begin
            $display("OK x0 ignora escrituras");
        end

        // TEST 6: WE3 = 0 no debe escribir
        A3 = 5'd7;
        WD3 = 32'hDEADBEEF;
        WE3 = 0;
        #10;

        A1 = 5'd7;
        #1;

        if (RD1 !== 32'd0) begin
            $display("ERROR WE3=0 escribio x7: RD1=%h", RD1);
            $fatal;
        end else begin
            $display("OK WE3=0 no escribe");
        end

        $display("TODOS LOS TESTS DEL REGISTER FILE PASARON");
        $finish;
    end

endmodule