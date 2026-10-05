module instr_mem #(
    parameter DEPTH = 1024
)(
    input  logic        clk,    // Reloj del sistema/procesador
    input  logic [31:0] A,      // Dirección (PC)
    output logic [31:0] RD      // Instrucción leída de 32 bits
);

    // Block Memory Generator configurado como ROM síncrona de un puerto (1024 x 32).
    batalla_naval_mem u_bram_inst (
        .clka  (clk),
        .ena   (1'b1),
        .addra (A[$clog2(DEPTH)+1:2]),
        .douta (RD)
    );

endmodule