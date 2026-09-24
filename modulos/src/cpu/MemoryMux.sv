module MemoryMux (
    input logic [31:0] ReadData,
    input logic ResultSrc,
    input logic [31:0] ALUResult,
    output logic [31:0] Result
);

always_comb begin
    case (ResultSrc)
    default: Result = 32'd0;
    1'b0: Result = ALUResult;
    1'b1: Result = ReadData;
    endcase
end

endmodule