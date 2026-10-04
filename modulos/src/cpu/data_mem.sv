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
    logic [7:0] byte_value;
    logic [15:0] half_value;

    assign word = mem[A[31:2]];
    // A[1:0] desplaza la selección al byte solicitado dentro de la palabra.
    assign byte_value = word >> (8 * A[1:0]);
    assign half_value = A[1] ? word[31:16] : word[15:0];

    always @(*) begin
        case (funct3)
            3'b000: RD = {{24{byte_value[7]}}, byte_value}; // lb
            3'b001: RD = {{16{half_value[15]}}, half_value}; // lh
            3'b010: RD = word;                          // lw
            3'b100: RD = {24'b0, byte_value};           // lbu
            3'b101: RD = {16'b0, half_value};           // lhu
            default: RD = 32'd0;
        endcase
    end
    always_ff @(posedge clk) begin
        if (WE) begin
            case (funct3)
                3'b000: begin
                    case (A[1:0])
                        2'b00: mem[A[31:2]][7:0]   <= WD[7:0];
                        2'b01: mem[A[31:2]][15:8]  <= WD[7:0];
                        2'b10: mem[A[31:2]][23:16] <= WD[7:0];
                        2'b11: mem[A[31:2]][31:24] <= WD[7:0];
                    endcase
                end
                3'b001: begin
                    if (A[1])
                        mem[A[31:2]][31:16] <= WD[15:0];
                    else
                        mem[A[31:2]][15:0] <= WD[15:0];
                end
                3'b010: mem[A[31:2]] <= WD; // sw
                default: ; // no hacer nada
            end
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