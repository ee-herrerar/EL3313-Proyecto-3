module Debouncer #(
    parameter int N = 1 // Número de bits/botones
)(
    input  logic         clk,
    input  logic         reset,
    input  logic [N-1:0] btn_in,
    output logic [N-1:0] btn_out
);

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : gen_debouncer
            logic [19:0] contador;
            logic        btn_prev;

            always_ff @(posedge clk or posedge reset) begin
                if (reset) begin
                    contador <= '0;
                    btn_prev <= 1'b0;
                    btn_out[i]  <= 1'b0;
                end
                else begin
                    if (btn_in[i] != btn_prev) begin
                        btn_prev <= btn_in[i];
                        contador <= '0;
                    end
                    else if (contador < 20'd1048575) begin
                        contador <= contador + 1'b1;
                    end
                    else begin
                        btn_out[i] <= btn_prev;
                    end
                end
            end
        end
    endgenerate

endmodule
