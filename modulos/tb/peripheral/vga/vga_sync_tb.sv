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
        #100;
        @(negedge clk_vga_i);
        rst_i = 0;

        #1;
        assert (pixel_x_o == 0 && pixel_y_o == 0 && video_on_o)
            else $fatal(1, "VGA counters did not restart at the visible origin");

        wait (pixel_x_o == 10'd639);
        #1;
        assert (video_on_o) else $fatal(1, "last visible pixel was blanked");
        wait (pixel_x_o == 10'd640);
        #1;
        assert (!video_on_o && hsync_o)
            else $fatal(1, "horizontal blanking did not start at pixel 640");
        wait (pixel_x_o == 10'd656);
        #1;
        assert (!hsync_o) else $fatal(1, "horizontal sync pulse did not assert low");
        wait (pixel_x_o == 10'd752);
        #1;
        assert (hsync_o) else $fatal(1, "horizontal sync pulse did not deassert");

        $display("vga_sync_tb: PASS");
        $finish;
    end

endmodule