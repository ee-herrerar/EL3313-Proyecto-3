module vga_clock_gen (
    input  logic clk100_i,
    input  logic rst_i,
    output logic clk_fpga_o,
    output logic clk_vga_o,
    output logic locked_o
);

    // ============================================================
    // RELOJ PRINCIPAL DEL SISTEMA
    //
    // El CPU, RAM y periféricos trabajan directamente a 100 MHz.
    // ============================================================

    assign clk_fpga_o = clk100_i;


    // ============================================================
    // PLL PARA VGA
    //
    // Entrada:
    //      100 MHz
    //
    // VCO:
    //      100 MHz * 8 = 800 MHz
    //
    // Salida:
    //      800 MHz / 32 = 25 MHz
    //
    // ============================================================

    logic clkfb_pll;
    logic clkfb_buf;
    logic clk25_pll;


    PLLE2_BASE #(
        .BANDWIDTH          ("OPTIMIZED"),
        .CLKFBOUT_MULT      (8),
        .DIVCLK_DIVIDE      (1),
        .CLKIN1_PERIOD      (10.0),
        .CLKOUT0_DIVIDE     (32),
        .STARTUP_WAIT       ("FALSE")
    ) u_pll (
        .CLKIN1             (clk100_i),

        .CLKFBIN            (clkfb_buf),
        .CLKFBOUT           (clkfb_pll),

        .CLKOUT0            (clk25_pll),

        .LOCKED             (locked_o),

        .PWRDWN             (1'b0),
        .RST                (rst_i)
    );


    // ============================================================
    // BUFFER GLOBAL DE REALIMENTACION
    // ============================================================

    BUFG u_bufg_feedback (
        .I (clkfb_pll),
        .O (clkfb_buf)
    );


    // ============================================================
    // BUFFER GLOBAL PARA RELOJ VGA
    // ============================================================

    BUFG u_bufg_vga (
        .I (clk25_pll),
        .O (clk_vga_o)
    );


endmodule