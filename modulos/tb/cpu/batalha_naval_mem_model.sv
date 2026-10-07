// Modelo síncrono de la ROM generada por Vivado para simulaciones RTL.
module batalha_naval_mem (
    input  logic        clka,
    input  logic        ena,
    input  logic [9:0]  addra,
    output logic [31:0] douta
);
    logic [31:0] mem [0:1023];

    initial begin
        for (int i = 0; i < 1024; i = i + 1)
            mem[i] = 32'h00000013;
    end

    always_ff @(posedge clka) begin
        if (ena)
            douta <= mem[addra];
    end
endmodule
