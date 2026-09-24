module vga_top_dut (
    input  logic        clk_cpu_i,
    input  logic        clk_vga_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic        hsync_o,
    output logic        vsync_o,
    output logic [3:0]  vga_r_o,
    output logic [3:0]  vga_g_o,
    output logic [3:0]  vga_b_o
);

    vga_periph u_vga_periph (
        .clk_cpu_i      (clk_cpu_i),
        .rst_i          (rst_i),
        .write_enable_i (write_enable_i),
        .addr_i         (addr_i),
        .wdata_i        (wdata_i),
        .clk_vga_i      (clk_vga_i),
        .hsync_o        (hsync_o),
        .vsync_o        (vsync_o),
        .vga_r_o        (vga_r_o),
        .vga_g_o        (vga_g_o),
        .vga_b_o        (vga_b_o)
    );

endmodule
