module instr_mem (
    input  logic        clk,
    input  logic [31:0] A,
    output logic [31:0] RD
);

    batalla_naval_mem u_bram_inst (
        .clka  (clk),
        .ena   (1'b1),
        .addra (A[12:2]),
        .douta (RD)
    );

endmodule