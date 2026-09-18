`timescale 1ns / 1ps

module vga_periph_tb();

    // Señales CPU
    logic        clk_cpu_i;
    logic        rst_i;
    logic        write_enable_i;
    logic [31:0] addr_i;
    logic [31:0] wdata_i;

    // Señales VGA
    logic        clk_vga_i;
    logic        hsync_o;
    logic        vsync_o;
    logic [3:0]  vga_r_o;
    logic [3:0]  vga_g_o;
    logic [3:0]  vga_b_o;

    vga_periph uut (
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

    always #5 clk_cpu_i = ~clk_cpu_i;
    always #20 clk_vga_i = ~clk_vga_i;

    initial begin
        clk_cpu_i = 0;
        clk_vga_i = 0;
        rst_i = 1;
        write_enable_i = 0;
        addr_i = 0;
        wdata_i = 0;

        #100 rst_i = 0;

        // 1. CPU escribe un bloque de agua (0x000) en el inicio de la memoria de video
        // Según el mapa, la base es 0x00011000
        @(posedge clk_cpu_i);
        write_enable_i = 1;
        addr_i = 32'h00011000;
        wdata_i = 32'b000; // Agua
        
        @(posedge clk_cpu_i);
        write_enable_i = 0;

        // 2. Ejecutar la simulación durante el inicio de un frame activo
        // El sync vertical/horizontal toma tiempo en estabilizarse y entrar en la zona visible
        #100000; // Permitimos que avance el barrido VGA

        $finish;
    end

endmodule