module cpu (
    input logic clk,
    input logic rst,
    input logic [31:0] ProgInstr_i,
    output logic [31:0] ProgAddress_o,
    input logic [31:0] DataIn_i,
    output logic [31:0] DataAddress_o,
    output logic [31:0] DataOut_o,
    output logic [2:0] DataFunct3_o,
    output logic DataWriteEnable_o
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
    datapath #(
        .EXTERNAL_MEMORY(1'b1)
    ) dp(
        .clk(clk),
        .rst(rst),

        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl),
        .ImmSrc(ImmSrc),
        .PCSrc(PCSrc),
        .ProgInstr_i(ProgInstr_i),
        .DataReadData_i(DataIn_i),

        .PC(PC),
        .Instr(Instr),
        .zero(zero),
        .less(less),
        .DataAddress_o(DataAddress_o),
        .DataWriteData_o(DataOut_o),
        .DataFunct3_o(DataFunct3_o),
        .DataWriteEnable_o(DataWriteEnable_o)
    );

    assign ProgAddress_o = PC;

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