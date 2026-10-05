module vga_clock_gen (
    input  logic clk100_i,
    input  logic rst_i,
    output logic clk_fpga_o,
    output logic clk_vga_o,
    output logic locked_o
);

    clk_wiz_0 u_clk_wiz_0 (
        .clk_in1  (clk100_i),
        .reset    (rst_i),
        .clk_fpga (clk_fpga_o),
        .clk_vga  (clk_vga_o),
        .locked   (locked_o)
    );

endmodule