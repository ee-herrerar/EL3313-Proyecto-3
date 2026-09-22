module pc(
    input logic clk,
    input logic rst,

    input logic [31:0] PCnext,
    output logic [31:0] PC
);

    always_ff @(posedge clk) begin
        if(rst) begin
            PC<=32'b0;
        end else begin
            PC <= PCnext;
        end
    end
endmodule