module instr_mem #(
    parameter DEPTH = 1024
)(
    input  logic        clk,    // Necesario para la BRAM sincronizada
    input  logic [31:0] A,      // Dirección (PC)
    output logic [31:0] RD      // Instrucción leída
);

    // Instancia del IP Core Block Memory Generator 
    batalla_naval_mem u_bram_inst (
        .clka  (clk),           // Reloj de la memoria
        .rsta  (1'b0),          // Reset activo alto, deshabilitado para la ROM
        .ena   (1'b1),          // Habilitador de la memoria (siempre activa)
        .wea   (1'b0),          // Write Enable en 0 (es solo lectura para el PC)
        .addra (A[31:2]),       // Dirección de 32 bits truncada a palabra (desplazado 2 bits por byte-addressing)
        .dina  (32'h00000000),  // Dato de entrada (no se usa al leer)
        .douta (RD)             // Instrucción de salida de 32 bits hacia tu procesador
    );

endmodule