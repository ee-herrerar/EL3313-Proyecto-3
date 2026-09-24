module ALUMux (
    input logic [31:0] RD2,
    input logic ALUSrc,
    input logic [31:0] ImmExt,
    output logic [31:0] SrcB
);

always_comb begin
    case (ALUSrc)
    default: SrcB = 32'd0;
    1'b0: SrcB = RD2;
    1'b1: SrcB = ImmExt;
    endcase
end

endmodule