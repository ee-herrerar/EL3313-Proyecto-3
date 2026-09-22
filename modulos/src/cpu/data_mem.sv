module data_mem(
    input logic [2:0] funct3,       // Para diferenciar entre lb, lh, lw, lbu, lhu
    input logic clk,
    input logic WE,              // Write Enable
    input logic [31:0] A,        // Dirección
    input logic [31:0] WD,       // Write Data
    output logic [31:0] RD       // Read Data
);
    logic [31:0] mem [0:255];
    logic [31:0] word;

    assign word = mem[A[31:2]]  ;

    always @(*) begin
        case (funct3)
            3'b000: RD = {{24{word[7]}},  word[7:0]};   // lb
            3'b001: RD = {{16{word[15]}}, word[15:0]};  // lh
            3'b010: RD = word;                          // lw
            3'b100: RD = {24'b0, word[7:0]};            // lbu
            3'b101: RD = {16'b0, word[15:0]};           // lhu
            default: RD = 32'd0;
        endcase
    end
    always_ff @(posedge clk) begin
    if (WE) begin
        case (funct3)
            3'b000: mem[A[31:2]][7:0]  <= WD[7:0];   // sb
            3'b001: mem[A[31:2]][15:0] <= WD[15:0];  // sh
            3'b010: mem[A[31:2]]       <= WD;        // sw
            default: ; // no hacer nada
        endcase
    end
end
    // Inicialización (opcional)
    initial begin
        integer i;
        for (i = 0; i < 256; i++) begin
            mem[i] = 0;
        end
    end

endmodule