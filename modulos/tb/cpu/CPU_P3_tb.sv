`timescale 1ns/1ps

module CPU_P3_tb;

    logic clk;
    logic rst;

    cpu dut(
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    function automatic [31:0] enc_r;
        input integer funct7;
        input integer rs2;
        input integer rs1;
        input integer funct3;
        input integer rd;
        begin
            enc_r = {funct7[6:0], rs2[4:0], rs1[4:0], funct3[2:0], rd[4:0], 7'b0110011};
        end
    endfunction

    function automatic [31:0] enc_i;
        input integer imm;
        input integer rs1;
        input integer funct3;
        input integer rd;
        input integer opcode;
        reg [11:0] imm12;
        begin
            imm12 = imm[11:0];
            enc_i = {imm12, rs1[4:0], funct3[2:0], rd[4:0], opcode[6:0]};
        end
    endfunction

    function automatic [31:0] enc_s;
        input integer imm;
        input integer rs2;
        input integer rs1;
        input integer funct3;
        reg [11:0] imm12;
        begin
            imm12 = imm[11:0];
            enc_s = {imm12[11:5], rs2[4:0], rs1[4:0], funct3[2:0], imm12[4:0], 7'b0100011};
        end
    endfunction

    function automatic [31:0] enc_b;
        input integer offset;
        input integer rs2;
        input integer rs1;
        input integer funct3;
        reg [12:0] imm13;
        begin
            imm13 = offset[12:0];
            enc_b = {imm13[12], imm13[10:5], rs2[4:0], rs1[4:0], funct3[2:0], imm13[4:1], imm13[11], 7'b1100011};
        end
    endfunction

    function automatic [31:0] enc_j;
        input integer offset;
        input integer rd;
        reg [20:0] imm21;
        begin
            imm21 = offset[20:0];
            enc_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd[4:0], 7'b1101111};
        end
    endfunction

    task automatic check_reg;
        input integer reg_number;
        input integer expected;
        input [127:0] instruction_name;
        reg [31:0] actual;
        begin
            actual = dut.dp.u_regfile.regs[reg_number];
            if (actual !== expected[31:0]) begin
                $error("%s: x%0d = %0d, esperado %0d", instruction_name, reg_number, $signed(actual), $signed(expected));
            end else begin
                $display("OK %-8s x%0d = %0d", instruction_name, reg_number, $signed(actual));
            end
        end
    endtask

    integer i;
    initial begin
        clk = 0;
        rst = 1;

        // Espera a que termine la inicializacion de instr_mem y carga este programa.
        #1;
        for (i = 0; i < 256; i = i + 1)
            dut.dp.u_imem.mem[i] = 32'h00000013; // nop

        // Aritmetica, logica e inmediatos.
        dut.dp.u_imem.mem[0]  = enc_i(10, 0, 3'b000, 1, 7'b0010011); // addi x1, x0, 10
        dut.dp.u_imem.mem[1]  = enc_i(3,  0, 3'b000, 2, 7'b0010011); // addi x2, x0, 3
        dut.dp.u_imem.mem[2]  = enc_r(0, 2, 1, 3'b000, 3);             // add x3, x1, x2
        dut.dp.u_imem.mem[3]  = enc_r(7'b0100000, 2, 1, 3'b000, 4);   // sub x4, x1, x2
        dut.dp.u_imem.mem[4]  = enc_r(0, 2, 1, 3'b111, 5);             // and x5, x1, x2
        dut.dp.u_imem.mem[5]  = enc_r(0, 2, 1, 3'b110, 6);             // or x6, x1, x2
        dut.dp.u_imem.mem[6]  = enc_r(0, 2, 1, 3'b100, 7);             // xor x7, x1, x2
        dut.dp.u_imem.mem[7]  = enc_i(1, 0, 3'b000, 8, 7'b0010011);   // addi x8, x0, 1
        dut.dp.u_imem.mem[8]  = enc_r(0, 8, 8, 3'b001, 9);             // sll x9, x8, x8
        dut.dp.u_imem.mem[9]  = enc_r(0, 8, 9, 3'b101, 10);            // srl x10, x9, x8
        dut.dp.u_imem.mem[10] = enc_i(8, 0, 3'b000, 11, 7'b0010011);  // addi x11, x0, 8
        dut.dp.u_imem.mem[11] = enc_i(3, 11, 3'b001, 12, 7'b0010011);  // slli x12, x11, 3
        dut.dp.u_imem.mem[12] = enc_i(1, 12, 3'b101, 13, 7'b0010011);  // srli x13, x12, 1
        dut.dp.u_imem.mem[13] = enc_i(32'h401, 11, 3'b101, 14, 7'b0010011); // srai x14, x11, 1
        dut.dp.u_imem.mem[14] = enc_i(-1, 0, 3'b000, 15, 7'b0010011); // addi x15, x0, -1
        dut.dp.u_imem.mem[15] = enc_r(0, 1, 15, 3'b010, 16);          // slt x16, x15, x1
        dut.dp.u_imem.mem[16] = enc_i(0, 15, 3'b010, 17, 7'b0010011); // slti x17, x15, 0
        dut.dp.u_imem.mem[17] = enc_r(0, 1, 15, 3'b011, 18);           // sltu x18, x15, x1
        dut.dp.u_imem.mem[18] = enc_i(0, 15, 3'b011, 19, 7'b0010011); // sltiu x19, x15, 0
        dut.dp.u_imem.mem[19] = enc_i(8'h0a, 0, 3'b111, 20, 7'b0010011); // andi x20, x0, 10
        dut.dp.u_imem.mem[20] = enc_i(8'h0a, 1, 3'b100, 21, 7'b0010011); // xori x21, x1, 10
        dut.dp.u_imem.mem[21] = enc_i(8'h05, 1, 3'b110, 22, 7'b0010011); // ori x22, x1, 5

        // Memoria de datos.
        dut.dp.u_imem.mem[22] = enc_i(64, 0, 3'b000, 23, 7'b0010011);  // addi x23, x0, 64
        dut.dp.u_imem.mem[23] = enc_i(123, 0, 3'b000, 24, 7'b0010011); // addi x24, x0, 123
        dut.dp.u_imem.mem[24] = enc_s(0, 24, 23, 3'b010);               // sw x24, 0(x23)
        dut.dp.u_imem.mem[25] = enc_i(0, 23, 3'b010, 25, 7'b0000011);   // lw x25, 0(x23)

        // Branches: cada salto omite una instruccion que escribira 99.
        dut.dp.u_imem.mem[26] = enc_b(8, 1, 1, 3'b000);                 // beq x1, x1, +8
        dut.dp.u_imem.mem[27] = enc_i(99, 0, 3'b000, 26, 7'b0010011);  // omitida
        dut.dp.u_imem.mem[28] = enc_b(8, 1, 2, 3'b001);                 // bne x2, x1, +8
        dut.dp.u_imem.mem[29] = enc_i(99, 0, 3'b000, 26, 7'b0010011);  // omitida
        dut.dp.u_imem.mem[30] = enc_b(8, 1, 2, 3'b100);                 // blt x2, x1, +8
        dut.dp.u_imem.mem[31] = enc_i(99, 0, 3'b000, 26, 7'b0010011);  // omitida
        dut.dp.u_imem.mem[32] = enc_b(8, 2, 1, 3'b101);                 // bge x1, x2, +8
        dut.dp.u_imem.mem[33] = enc_i(99, 0, 3'b000, 26, 7'b0010011);  // omitida
        dut.dp.u_imem.mem[34] = enc_i(7, 0, 3'b000, 26, 7'b0010011);   // valor esperado

        // JAL: salta a la instruccion 37 y guarda PC+4 en x27.
        dut.dp.u_imem.mem[35] = enc_j(8, 27);                           // jal x27, +8
        dut.dp.u_imem.mem[36] = enc_i(99, 0, 3'b000, 26, 7'b0010011);  // omitida
        dut.dp.u_imem.mem[37] = enc_i(8, 0, 3'b000, 28, 7'b0010011);   // addi x28, x0, 8

        // JALR: salta a la instruccion 41 y guarda PC+4 en x30.
        dut.dp.u_imem.mem[38] = enc_i(164, 0, 3'b000, 29, 7'b0010011); // direccion byte de mem[41]
        dut.dp.u_imem.mem[39] = enc_i(0, 29, 3'b000, 30, 7'b1100111); // jalr x30, 0(x29)
        dut.dp.u_imem.mem[40] = enc_i(99, 0, 3'b000, 26, 7'b0010011); // omitida
        dut.dp.u_imem.mem[41] = enc_i(9, 0, 3'b000, 31, 7'b0010011);  // addi x31, x0, 9
        dut.dp.u_imem.mem[42] = enc_r(7'b0100000, 8, 15, 3'b101, 15); // sra x15, x15, x8
        dut.dp.u_imem.mem[43] = enc_j(0, 0);                            // detener en este punto

        repeat (2) @(posedge clk);
        rst = 0;
        repeat (48) @(posedge clk);
        #1;

        $display("\n--- RESULTADOS CPU_P3 ---");
        check_reg(3, 13, "add");
        check_reg(4, 7,  "sub");
        check_reg(5, 2,  "and");
        check_reg(6, 11, "or");
        check_reg(7, 9,  "xor");
        check_reg(9, 2,  "sll");
        check_reg(10, 1, "srl");
        check_reg(12, 64, "slli");
        check_reg(13, 32, "srli");
        check_reg(14, 4, "srai");
        check_reg(15, -1, "sra");
        check_reg(16, 1, "slt");
        check_reg(17, 1, "slti");
        check_reg(18, 0, "sltu");
        check_reg(19, 0, "sltiu");
        check_reg(20, 0, "andi");
        check_reg(21, 0, "xori");
        check_reg(22, 15, "ori");
        check_reg(25, 123, "lw");
        check_reg(26, 7, "branches");
        check_reg(27, 144, "jal link");
        check_reg(28, 8, "jal target");
        check_reg(30, 160, "jalr link");
        check_reg(31, 9, "jalr target");

        $finish;
    end

endmodule
