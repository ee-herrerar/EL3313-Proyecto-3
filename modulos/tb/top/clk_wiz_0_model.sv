// Modelo de simulación del reloj IP; pasa clk_fpga y divide para clk_vga.
module clk_wiz_0 (
    input  logic clk_in1,
    input  logic reset,
    output logic clk_fpga,
    output logic clk_vga,
    output logic locked
);
    logic [1:0] divider;

    assign clk_fpga = clk_in1;

    always_ff @(posedge clk_in1 or posedge reset) begin
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
