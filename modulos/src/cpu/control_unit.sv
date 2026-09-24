module control_unit(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic zero,
    input  logic less,

    output logic RegWrite,
    output logic ALUSrc,
    output logic [1:0] ResultSrc,
    output logic [3:0] ImmSrc,
    output logic [3:0] ALUControl,
    output logic [1:0] PCSrc,
    output logic MemWrite
);

    logic Branch;
    logic BranchNE;
    logic BranchGE;
    logic BranchLT;
    logic [1:0] ALUOp;
    logic Jump;

    // Main decoder
    main_decoder md(
        .op(op),
        .funct3(funct3),
        .Jump(Jump),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .BranchNE(BranchNE),
        .BranchGE(BranchGE),
        .BranchLT(BranchLT),
        .ImmSrc(ImmSrc),
        .ALUOp(ALUOp)
    );

    // ALU decoder
    alu_decoder ad(
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(ALUControl)
    );

    always @(*) begin
        PCSrc = 2'b00;

        // ======================
        // BRANCHES
        // ======================
        if (Branch && zero)
            PCSrc = 2'b01;   // BEQ

        else if (BranchNE && ~zero)
            PCSrc = 2'b01;   // BNE

        else if (BranchLT && less)
            PCSrc = 2'b01;   // BLT

        else if (BranchGE && ~less)
            PCSrc = 2'b01;   // BGE

        // ======================
        // JUMPS
        // ======================
        else if (Jump)
            PCSrc = 2'b01;   // JAL

        else if (op == 7'b1100111)
            PCSrc = 2'b10;   // JALR
    end

endmodule