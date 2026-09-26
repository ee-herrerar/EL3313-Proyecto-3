`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2026 19:54:48
// Design Name: 
// Module Name: tile_map_ram
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


module tile_map_ram (
    // Puerto A: CPU (100 MHz)
    input  logic        clk_cpu_i,
    input  logic        write_enable_i,
        input  logic [8:0]  addr_cpu_i,     // 9 bits para indexar hasta 512 posiciones
    input  logic [31:0] wdata_i,
    
    // Puerto B: VGA (25 MHz)
    input  logic        clk_vga_i,
    input  logic [8:0]  addr_vga_i,
    output logic [31:0] rdata_vga_o
);

    // Memoria inferida como Block RAM (BRAM)
    logic [31:0] vram [0:511]; 

    // Inicialización opcional en negro/agua (0x00000000)
    initial begin
        for (int i = 0; i < 512; i++) vram[i] = 32'b0;
    end

    // Puerto de escritura síncrono al reloj del sistema
    always_ff @(posedge clk_cpu_i) begin
        if (write_enable_i) begin
            vram[addr_cpu_i] <= wdata_i;
            if (addr_cpu_i == 9'd150)
            $display("VRAM[150] = %h", wdata_i);
        end
    end

    // Puerto de lectura síncrono al reloj de píxel
    always_ff @(posedge clk_vga_i) begin
        rdata_vga_o <= vram[addr_vga_i];
    end

endmodule

