module Extend (
    input logic [31:0] Instr,
    input logic [3:0] ImmSrc,
    output logic [31:0] ImmExt
);

always @(*) begin
    case (ImmSrc)

        // Instrucción tipo I
        4'b0000: ImmExt = {{20{Instr[31]}}, Instr[31:20]};

        // Instrucción tipo S
        4'b0001: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};

        // B-TYPE (BEQ, BNE)
        4'b0010: ImmExt = {{19{Instr[31]}}, Instr[31], 
                           Instr[7], Instr[30:25],
                           Instr[11:8], 1'b0};

        // Instrucción tipo J
         4'b0011: ImmExt = {{11{Instr[31]}}, Instr[31],
                           Instr[19:12], Instr[20],
                           Instr[30:21], 1'b0};

        // Instrucción tipo U
        4'b0100: ImmExt = {Instr[31:12], 12'b0};

        default: ImmExt = 32'd0;

    endcase
end

endmodule