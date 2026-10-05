module instr_mem #(
    parameter DEPTH = 2048
)(
    input  logic [31:0] A,
    output logic [31:0] RD
);

    logic [31:0] mem [0:DEPTH-1];

    assign RD = mem[A[12:2]];

    initial begin
        for (int i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000013; // nop

        $readmemh("C:/Repositorios Github/EL3313-Proyecto-3/modulos/ensamblador/batalla_naval.hex",
            mem);
    end

endmodule