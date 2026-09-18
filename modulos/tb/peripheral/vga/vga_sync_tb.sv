`timescale 1ns / 1ps

module vga_sync_tb();

    logic clk_vga_i;
    logic rst_i;
    logic hsync_o;
    logic vsync_o;
    logic [9:0] pixel_x_o;
    logic [9:0] pixel_y_o;
    logic video_on_o;

    // Instancia del generador de sincronismos VGA
    vga_sync uut (
        .clk_vga_i  (clk_vga_i),
        .rst_i      (rst_i),
        .hsync_o    (hsync_o),
        .vsync_o    (vsync_o),
        .pixel_x_o  (pixel_x_o),
        .pixel_y_o  (pixel_y_o),
        .video_on_o (video_on_o)
    );

    // Reloj de píxel a 25 MHz (Periodo = 40 ns -> Mitad = 20 ns)
    always #20 clk_vga_i = ~clk_vga_i;

    initial begin
        // Inicialización
        clk_vga_i = 0;
        rst_i = 1;

        // Liberar reset
        #100 rst_i = 0;

        // Esperar el equivalente a un par de líneas completas (800 píxeles por línea)
        // 800 ciclos * 40 ns = 32000 ns
        #64000;

        // Terminar la simulación
        $finish;
    end

endmodule