module instr_mem #(
    parameter DEPTH = 256
)(
    input  logic [31:0] A,     // Dirección (PC)
    output logic [31:0] RD     // Instrucción
);

    logic [31:0] mem [0:DEPTH-1];

    // Lectura combinacional
    assign RD = mem[A[31:2]];

    // Inicialización (para simulación)
    initial begin
        $readmemh("sim/program.hex", mem);
    end

endmodule