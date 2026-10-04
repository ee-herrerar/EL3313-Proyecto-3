// Modelo de simulación del reloj IP; divide 100 MHz entre cuatro y marca lock.
module clk_wiz_0 (
    input  logic clk100mhz,
    input  logic reset,
    output logic clk_vga,
    output logic locked
);
    logic [1:0] divider;

    always_ff @(posedge clk100mhz or posedge reset) begin
        if (reset) begin
            divider <= 2'b00;
            clk_vga <= 1'b0;
            locked <= 1'b0;
        end else begin
            divider <= divider + 1'b1;
            clk_vga <= divider[1];
            locked <= 1'b1;
        end
    end
endmodule
