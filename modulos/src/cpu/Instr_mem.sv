module instr_mem #(
    parameter DEPTH = 2048
)(
    input  logic [31:0] A,     // Dirección (PC)
    output logic [31:0] RD     // Instrucción
);

    logic [31:0] mem [0:DEPTH-1];

    // Lectura combinacional
    assign RD = mem[A[31:2]];

    // Inicialización segura antes de cargar el programa.
    initial begin
        for (int i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000013; // nop
        $readmemh("program.hex", mem);
    end

endmodule