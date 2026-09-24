module SumPCTarget (
    input logic [31:0] PC,
    input logic [31:0] ImmExt,
    output logic [31:0] PCTarget
);

always_comb begin
    PCTarget = ImmExt + PC;
end

endmodule