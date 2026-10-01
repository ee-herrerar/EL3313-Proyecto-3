module instr_mem #(
    parameter DEPTH = 2048
)(
    input  logic        clk,    // Reloj del sistema/procesador
    input  logic [31:0] A,      // Dirección (PC)
    output logic [31:0] RD      // Instrucción leída de 32 bits
);

    // Instancia del Block Memory Generator IP
    batalla_naval_mem u_bram_inst (
        .clka  (clk),           // Reloj de la BRAM
        .rsta  (1'b0),          // Reset activo alto, inactivo para la ROM
        .ena   (1'b1),          // Memoria siempre habilitada
        .wea   (1'b0),          // Deshabilitar escritura (solo lectura)
        .addra (A[$clog2(DEPTH)+1:2]), // Dirección de palabra según profundidad
        .dina  (32'h00000000),  // Sin uso para lectura
        .douta (RD)             // Salida de la instrucción
    );

endmodule