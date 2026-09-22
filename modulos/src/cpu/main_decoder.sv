module main_decoder(
    input  logic [6:0] op,
    input logic [2:0] funct3,
    output logic Jump,
    output logic RegWrite,
    output logic MemWrite,
    output logic ALUSrc,
    output logic [1:0] ResultSrc,
    output logic Branch,
    output logic BranchNE,
    output logic BranchGE,
    output logic BranchLT,
    output logic [3:0] ImmSrc,
    output logic [1:0] ALUOp
);

always_comb begin
    // valores por defecto
    RegWrite = 0;
    ALUSrc   = 0;
    Jump     = 0;
    ResultSrc = 2'b00;
    Branch   = 0;
    BranchNE = 0;
    BranchGE = 0;
    BranchLT = 0;
    ImmSrc   = 4'b0000;
    ALUOp    = 2'b00;
    MemWrite = 0;

    case(op)

        // ======================
        // R-TYPE (ADD, SUB, AND, OR...)
        // ======================
        7'b0110011: begin
            RegWrite = 1;
            ALUSrc   = 0;
            ALUOp    = 2'b10;
        end

        // ======================
        // I-TYPE (ADDI, ANDI...)
        // ======================
        7'b0010011: begin
            RegWrite = 1;
            ALUSrc   = 1;
            ImmSrc   = 4'b0000; // I-type
            ALUOp    = 2'b10;
        end

        // ======================
        // LOAD (LW, lb, lh, lbu, lhu)
        // ======================
        7'b0000011: begin
            RegWrite = 1;
            ALUSrc   = 1;
            ResultSrc = 2'b01;
            ImmSrc   = 4'b0000; // I-type
            ALUOp    = 2'b00; // suma
        end

        // ======================
        // STORE (SW)
        // ======================
        7'b0100011: begin
            ALUSrc   = 1;
            ImmSrc   = 4'b0001; // S-type
            ALUOp    = 2'b00;
            MemWrite = 1; 
        end

        // ======================
        // BRANCH (BEQ, BNEQ)
        // ======================
        7'b1100011: begin
            ImmSrc = 4'b0010;
            ALUOp  = 2'b01;
            case(funct3)
                3'b000: Branch   = 1; // BEQ
                3'b001: BranchNE = 1; // BNE
                3'b101: BranchGE = 1; // BGE
                3'b100: BranchLT = 1; // BLT
            endcase
        end
        // ======================
        // Jump (jal)
        // ======================
        7'b1101111: begin 
            RegWrite = 1;
            ResultSrc = 2'b10;
            ImmSrc   = 4'b0011; // J-type
            ALUOp    = 2'b00;
            Jump     = 1;
        end

        // ======================
        // JALR
        // ======================
        7'b1100111: begin
            RegWrite = 1;
            ALUSrc   = 1;
            ResultSrc = 2'b10;
            ImmSrc   = 4'b0000; // I-type
            ALUOp    = 2'b00;    // rs1 + inmediato
        end
        // ======================
        // LUI
        // ======================
        7'b0110111: begin
        RegWrite = 1;
        ALUSrc   = 1;
        ResultSrc = 2'b00;
        ImmSrc   = 4'b0100;  // U-type
        ALUOp    = 2'b11;    // necesitarías definir esto como "pasar SrcB"
        end
    endcase
end

endmodule