module vga_clock_gen (
    input  logic clk100_i,
    input  logic rst_i,
    output logic clk25_o,
    output logic locked_o
);

    logic clkfb;
    logic clk25_pll;

    PLLE2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT(8),
        .DIVCLK_DIVIDE(1),
        .CLKIN1_PERIOD(10.0),
        .CLKOUT0_DIVIDE(32)
    ) u_pll (
        .CLKIN1   (clk100_i),
        .RST      (rst_i),
        .PWRDWN   (1'b0),
        .CLKFBIN  (clkfb),
        .CLKFBOUT (clkfb),
        .CLKOUT0  (clk25_pll),
        .LOCKED   (locked_o)
    );

    BUFG u_bufg (
        .I (clk25_pll),
        .O (clk25_o)
    );

endmodule
