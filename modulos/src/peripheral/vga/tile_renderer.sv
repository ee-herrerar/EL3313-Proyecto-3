module tile_renderer (
    input  logic [9:0]  pixel_x_i,
    input  logic [9:0]  pixel_y_i,
    input  logic        video_on_i,
    input  logic [31:0] tile_data_i,
    
    output logic [8:0]  tile_addr_o,
    output logic [11:0] rgb_o // {R[3:0], G[3:0], B[3:0]}
);

    logic [4:0] tile_x; // Columna (0-19)
    logic [3:0] tile_y; // Fila (0-14)
    
    // Dividir entre 32 es equivalente a ignorar los 5 bits menos significativos
    assign tile_x = pixel_x_i[9:5];
    assign tile_y = pixel_y_i[9:5];
    
    // Dirección lineal = fila * NUM_COLUMNAS + columna (20 columnas)
    // 20 = 16 + 4 = (tile_y << 4) + (tile_y << 2) para optimizar multiplicación en hardware
    assign tile_addr_o = (tile_y << 4) + (tile_y << 2) + tile_x;

    // Decodificación de colores (bits [2:0] según requerimiento del proyecto)
    logic [11:0] color_palette;
    always_comb begin
        case (tile_data_i[2:0])
            3'b000: color_palette = 12'h00F; // Agua (Azul)
            3'b001: color_palette = 12'h888; // Barco propio (Gris)
            3'b010: color_palette = 12'hF00; // Impacto (Rojo)
            3'b011: color_palette = 12'hFFF; // Fallo (Blanco)
            3'b100: color_palette = 12'h0F0; // HUD / Éxito (Verde)
            default: color_palette = 12'h000; // Fondo/Negro
        endcase
    end

    // Solo emitir color si estamos en la zona visible
    assign rgb_o = video_on_i ? color_palette : 12'h000;

endmodule