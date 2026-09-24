module uart_generador_baudios #(
    parameter SYS_CLK_FREQ = 100_000_000, // Reloj del sistema a 100 MHz
    parameter BAUD_RATE    = 115_200,     // Baudios solicitados para el proyecto
    parameter OVERSAMPLE   = 16
)(
    input  logic clk_i,
    input  logic rst_i,
    output logic s_tick
);

    localparam int DIVISOR = SYS_CLK_FREQ / (BAUD_RATE * OVERSAMPLE);
    localparam int COUNTER_WIDTH = $clog2(DIVISOR);

    logic [COUNTER_WIDTH-1:0] count_reg, count_next;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            count_reg <= '0;
        else
            count_reg <= count_next;
    end

    always_comb begin
        count_next = count_reg + 1'b1;
        s_tick = 1'b0;

        if (count_reg == DIVISOR - 1) begin
            count_next = '0;
            s_tick = 1'b1;
        end
    end

endmodule