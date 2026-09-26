`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.09.2026 11:28:47
// Design Name: 
// Module Name: top_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_test (

    input  logic       clk100mhz,
    input  logic       btnC,
    output logic       hsync,
    output logic       vsync,
    // Salidas colores
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);


    logic           clk_vga;
    logic           write_enable;
    logic [31:0]    write_addr;
    logic [31:0]    write_data;

    vga_test u_test (
        .clk_i          (clk100mhz),
        .rst_i          (btnC),
        .write_enable_o (write_enable),
        .addr_o         (write_addr),
        .wdata_o        (write_data)
    );

   vga_top_dut u_dut (
        .clk_cpu_i      (clk100mhz),
        .rst_i          (btnC),
        .write_enable_i (write_enable),
        .addr_i         (write_addr),
        .wdata_i        (write_data),
        .hsync_o        (hsync),
        .vsync_o        (vsync),
        .vga_r_o        (vgaRed),
        .vga_g_o        (vgaGreen),
        .vga_b_o        (vgaBlue)
    );

endmodule