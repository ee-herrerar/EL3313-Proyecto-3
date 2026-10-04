// Modelo síncrono de la BRAM generada por Vivado para simulaciones RTL.
module batalha_naval_mem (
    input  logic        clka,
    input  logic        rsta,
    input  logic        ena,
    input  logic        wea,
    input  logic [10:0] addra,
    input  logic [31:0] dina,
    output logic [31:0] douta
);
    logic [31:0] mem [0:2047];

    initial begin
        for (int i = 0; i < 2048; i = i + 1)
            mem[i] = 32'h00000013;
    end

    always_ff @(posedge clka) begin
        if (rsta)
            douta <= 32'b0;
        else if (ena) begin
            if (wea)
                mem[addra] <= dina;
            douta <= mem[addra];
        end
    end
endmodule
