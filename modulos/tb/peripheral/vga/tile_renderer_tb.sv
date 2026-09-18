`timescale 1ns / 1ps

module tile_renderer_tb();

    logic [9:0]  pixel_x_i;
    logic [9:0]  pixel_y_i;
    logic        video_on_i;
    logic [31:0] tile_data_i;
    logic [8:0]  tile_addr_o;
    logic [11:0] rgb_o;

    tile_renderer uut (
        .pixel_x_i   (pixel_x_i),
        .pixel_y_i   (pixel_y_i),
        .video_on_i  (video_on_i),
        .tile_data_i (tile_data_i),
        .tile_addr_o (tile_addr_o),
        .rgb_o       (rgb_o)
    );

    initial begin
        // Prueba 1: Píxel en la región superior izquierda (Fila 0, Columna 0)
        pixel_x_i = 10'd15; // Dentro de los primeros 32 píxeles
        pixel_y_i = 10'd10; // Dentro de los primeros 32 píxeles
        video_on_i = 1;
        tile_data_i = 32'b001; // Color: Barco propio

        #10;
        if (tile_addr_o == 9'd0 && rgb_o == 12'h888) 
            $display("Test 1 PASSED: Tile 0 calculado correctamente.");
        else 
            $error("Test 1 FAILED");

        // Prueba 2: Píxel en la segunda fila, tercera columna (Fila 1, Columna 2)
        // Fila 1 = Y entre 32 y 63. Columna 2 = X entre 64 y 95.
        // Dirección esperada = (1 * 20) + 2 = 22
        pixel_x_i = 10'd70; 
        pixel_y_i = 10'd40; 
        tile_data_i = 32'b010; // Color: Impacto (Rojo)

        #10;
        if (tile_addr_o == 9'd22 && rgb_o == 12'hF00) 
            $display("Test 2 PASSED: Tile 22 calculado correctamente.");
        else 
            $error("Test 2 FAILED");

        $finish;
    end

endmodule