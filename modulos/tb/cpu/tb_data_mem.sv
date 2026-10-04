module tb_data_mem;

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

        // ======================
        // LOAD TESTS
        // ======================
        // Espera a que termine el bloque de inicialización del DUT.
        #1;
        dut.mem[0] = 32'hAABBCCDD;
        A = 32'd0;

        funct3 = 3'b000; // lb
        #1;
        if (RD !== 32'hFFFFFFDD) begin
            $display("ERROR LB: RD=%h", RD);
            $fatal;
        end else $display("OK LB");

        funct3 = 3'b001; // lh
        #1;
        if (RD !== 32'hFFFFCCDD) begin
            $display("ERROR LH: RD=%h", RD);
            $fatal;
        end else $display("OK LH");

        funct3 = 3'b010; // lw
        #1;
        if (RD !== 32'hAABBCCDD) begin
            $display("ERROR LW: RD=%h", RD);
            $fatal;
        end else $display("OK LW");

        funct3 = 3'b100; // lbu
        #1;
        if (RD !== 32'h000000DD) begin
            $display("ERROR LBU: RD=%h", RD);
            $fatal;
        end else $display("OK LBU");

        funct3 = 3'b101; // lhu
        #1;
        if (RD !== 32'h0000CCDD) begin
            $display("ERROR LHU: RD=%h", RD);
            $fatal;
        end else $display("OK LHU");

        // Los bits A[1:0] seleccionan byte y A[1] selecciona la mitad alta/baja.
        A = 32'd2;
        funct3 = 3'b000; // lb del byte 2: 0xBB
        #1;
        if (RD !== 32'hFFFFFFBB) $fatal(1, "LB offset 2 mismatch: %h", RD);
        funct3 = 3'b100; // lbu del mismo byte
        #1;
        if (RD !== 32'h000000BB) $fatal(1, "LBU offset 2 mismatch: %h", RD);
        funct3 = 3'b001; // lh de la mitad alta
        #1;
        if (RD !== 32'hFFFFAABB) $fatal(1, "LH offset 2 mismatch: %h", RD);
        funct3 = 3'b101; // lhu de la mitad alta
        #1;
        if (RD !== 32'h0000AABB) $fatal(1, "LHU offset 2 mismatch: %h", RD);

        // ======================
        // STORE BYTE
        // ======================
        dut.mem[1] = 32'hAABBCCDD;
        A = 32'd5;              // mem[1], byte lane 1
        WD = 32'h00000011;
        funct3 = 3'b000;        // sb
        WE = 1;

        #10;
        WE = 0;

        if (dut.mem[1] !== 32'hAABB11DD) begin
            $display("ERROR SB: mem[1]=%h", dut.mem[1]);
            $fatal;
        end else $display("OK SB");

        // ======================
        // STORE HALF
        // ======================
        dut.mem[2] = 32'hAABBCCDD;
        A = 32'd10;             // mem[2], mitad alta
        WD = 32'h00001122;
        funct3 = 3'b001;        // sh
        WE = 1;

        #10;
        WE = 0;

        if (dut.mem[2] !== 32'h1122CCDD) begin
            $display("ERROR SH: mem[2]=%h", dut.mem[2]);
            $fatal;
        end else $display("OK SH");

        // ======================
        // STORE WORD
        // ======================
        dut.mem[3] = 32'hAABBCCDD;
        A = 32'd12;             // mem[3]
        WD = 32'h12345678;
        funct3 = 3'b010;        // sw
        WE = 1;

        #10;
        WE = 0;

        if (dut.mem[3] !== 32'h12345678) begin
            $display("ERROR SW: mem[3]=%h", dut.mem[3]);
            $fatal;
        end else $display("OK SW");

        // TEST: WE = 0 no debe escribir
        dut.mem[4] = 32'hAAAAAAAA;
        A = 32'd16;             // mem[4]
        WD = 32'h55555555;
        funct3 = 3'b010;        // sw
        WE = 0;

        #10;

        if (dut.mem[4] !== 32'hAAAAAAAA) begin
            $display("ERROR WE=0: mem[4]=%h", dut.mem[4]);
            $fatal;
        end else begin
            $display("OK WE=0 no escribe");
        end

        $display("TODOS LOS TESTS DE DATA MEMORY PASARON");
        $finish;
    end

endmodule