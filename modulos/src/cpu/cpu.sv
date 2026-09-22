module cpu (
    input logic clk,
    input logic rst
);

    // ======================
    // Señales internas
    // ======================
    logic [31:0] PC;
    logic [31:0] Instr;
    logic zero;
    logic less;

    logic RegWrite;
    logic ALUSrc;
    logic [1:0] ResultSrc;
    logic MemWrite;
    logic [3:0] ImmSrc;
    logic [3:0] ALUControl;
    logic [1:0] PCSrc;

    // ======================
    // DATAPATH
    // ======================
    datapath dp(
        .clk(clk),
        .rst(rst),

        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl),
        .ImmSrc(ImmSrc),
        .PCSrc(PCSrc),

        .PC(PC),
        .Instr(Instr),
        .zero(zero),
        .less(less)
    );

    // ======================
    // CONTROL UNIT
    // ======================
    control_unit cu(
        .op(Instr[6:0]),
        .funct3(Instr[14:12]),
        .funct7(Instr[31:25]),
        .zero(zero),
        .less(less),

        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl),
        .PCSrc(PCSrc)
    );

endmodule