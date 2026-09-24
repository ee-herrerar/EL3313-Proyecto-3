module sync_legacy #(
    parameter int N = 6 // Número de bits/botones
)(
    input  logic         clk,
    input  logic         reset,
    input  logic [N-1:0] async_signal,
    output logic [N-1:0] sync_signal
);

    logic [N-1:0] sync_ff1;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_ff1    <= '0;
            sync_signal <= '0;
        end
        else begin
            sync_ff1    <= async_signal;
            sync_signal <= sync_ff1;
        end
    end

endmodule
