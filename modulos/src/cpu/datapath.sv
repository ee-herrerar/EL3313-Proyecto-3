module datapath(
    input logic clk,
    input logic rst,

    // Control signals
    input logic RegWrite,
    input logic ALUSrc,
    input logic MemWrite,
    input logic [1:0] ResultSrc,
    input logic [3:0] ALUControl,
    input logic [3:0] ImmSrc,
    input logic [1:0] PCSrc, 
    output logic [31:0] PC,
    output logic [31:0] Instr,
    output logic zero,
    output logic less
);

    // ======================
    // Señales internas
    // ======================
    logic [31:0] PCplus4, PCTarget, PCnext;
    logic [31:0] RD1, RD2;
    logic [31:0] SrcB;
    logic [31:0] ALUResult;
    logic [31:0] ALUResult_jalr;
    logic [31:0] ImmExt;
    logic [31:0] Result;
    logic [31:0] ReadData;
    

    // ======================
    // PC
    // ======================
    pc u_pc(
        .clk(clk),
        .rst(rst),
        .PCnext(PCnext),
        .PC(PC)
    );

    // ======================
    // PC + 4
    // ======================
    adder u_pc4(
        .in0(PC),
        .in1(32'd4),
        .out(PCplus4)
    );

    // ======================
    // Instruction Memory
    // ======================
    instr_mem u_imem(
        .A(PC),
        .RD(Instr)
    );

    // ======================
    // Register File
    // ======================
    reg_file u_regfile(
        .clk(clk),
        .WE3(RegWrite),
        .A1(Instr[19:15]),
        .A2(Instr[24:20]),
        .A3(Instr[11:7]),
        .WD3(Result),
        .RD1(RD1),
        .RD2(RD2)
    );

    // ======================
    // Immediate Extend
    // ======================
    Extend u_extend(
        .Instr(Instr),
        .ImmSrc(ImmSrc),
        .ImmExt(ImmExt)
    );

    // ======================
    // Branch Target (PC + Imm)
    // ======================
    adder u_pctarget(
        .in0(PC),
        .in1(ImmExt),
        .out(PCTarget)
    );

    // ======================
    // ALU MUX
    // ======================
    mux21 u_alumux(
        .sel(ALUSrc),
        .in0(RD2),
        .in1(ImmExt),
        .out(SrcB)
    );

    // ======================
    // ALU
    // ======================
    ALU u_alu(
        .SrcA(RD1),
        .SrcB(SrcB),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .zero(zero),
        .less(less)
    );

    // ======================
    // Result MUX
    // ======================
    mux41 u_resultmux(
        .sel(ResultSrc),
        .in0(ALUResult),
        .in1(ReadData),
        .in2(PCplus4),
        .in3(32'd0), // Reservado
        .out(Result)
    );

    // ======================
    // PC MUX (Branch)
    // ======================

    mux41 u_pcmux(
        .sel(PCSrc),
        .in0(PCplus4),   // 00 → normal
        .in1(PCTarget),  // 01 → branch / jal
        .in2(ALUResult_jalr), // 10 → jalr
        .in3(32'd0),     // 11 → reservado
        .out(PCnext)
    );

    // ======================
    // Memoria de datos
    // ======================
    data_mem u_dmem(
    .clk(clk),
    .funct3(Instr[14:12]),
    .WE(MemWrite),
    .A(ALUResult),
    .WD(RD2),
    .RD(ReadData)
);

assign ALUResult_jalr = {ALUResult[31:1], 1'b0};

endmodule