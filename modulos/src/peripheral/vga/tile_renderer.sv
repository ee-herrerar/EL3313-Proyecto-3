module tile_renderer (
    input  logic [9:0]  pixel_x_i,
    input  logic [9:0]  pixel_y_i,
    input  logic        video_on_i,
    input  logic [31:0] tile_data_i,

    output logic [8:0]  tile_addr_o,
    output logic [11:0] rgb_o
);

    logic [4:0] tile_x;
    logic [3:0] tile_y;

    logic [4:0] pixel_in_tile_x;
    logic [4:0] pixel_in_tile_y;

    logic [11:0] color_palette;

    logic inside_board;
    logic grid_border;

    logic label_area;
    logic [2:0] label_digit;
    logic digit_pixel;

    logic [6:0] digit_segments;


    // =========================================================
    // TILE ACTUAL
    // Cada tile = 32 x 32 pixeles
    // =========================================================

    assign tile_x = pixel_x_i[9:5];
    assign tile_y = pixel_y_i[9:5];

    assign pixel_in_tile_x = pixel_x_i[4:0];
    assign pixel_in_tile_y = pixel_y_i[4:0];


    // =========================================================
    // DIRECCION VRAM
    // 20 columnas
    // =========================================================

    assign tile_addr_o =
        (tile_y << 4) +
        (tile_y << 2) +
        tile_x;


    // =========================================================
    // PALETA
    // =========================================================

    always_comb begin
        case (tile_data_i[2:0])

            3'b000:
                color_palette = 12'h00F; // Agua azul

            3'b001:
                color_palette = 12'h888; // Barco gris

            3'b010:
                color_palette = 12'hF00; // Impacto rojo

            3'b011:
                color_palette = 12'hFFF; // Fallo blanco

            3'b100:
                color_palette = 12'h0F0; // HUD verde

            3'b101:
                color_palette = 12'hFF0; // Cursor amarillo

            3'b110:
                color_palette = 12'h0FF; // Cursor vertical cian

            default:
                color_palette = 12'h00F;

        endcase
    end


    // =========================================================
    // TABLEROS REALES
    //
    // IMPORTANTE:
    // El ASM usa:
    //
    //     fila VGA = fila juego + 2
    //
    // Por lo tanto:
    //
    // J1:
    //   columnas 1..8
    //   filas    2..9
    //
    // J2:
    //   columnas 11..18
    //   filas     2..9
    // =========================================================

    always_comb begin

        inside_board = 1'b0;

        if (tile_y >= 2 && tile_y <= 9) begin

            if ((tile_x >= 1  && tile_x <= 8) ||
                (tile_x >= 11 && tile_x <= 18)) begin

                inside_board = 1'b1;

            end

        end

    end


    // =========================================================
    // BORDES DE LAS CASILLAS
    // =========================================================

    always_comb begin

        grid_border = 1'b0;

        if (inside_board) begin

            if (pixel_in_tile_x == 0  ||
                pixel_in_tile_x == 31 ||
                pixel_in_tile_y == 0  ||
                pixel_in_tile_y == 31) begin

                grid_border = 1'b1;

            end

        end

    end


    // =========================================================
    // COORDENADAS
    //
    // Numeros de columnas:
    //
    //        0 1 2 3 4 5 6 7
    //        ----------------
    // fila 1 = etiquetas
    // fila 2 = fila 0 del juego
    //
    //
    // Numeros de filas:
    //
    // fila VGA 2 -> numero 0
    // fila VGA 3 -> numero 1
    // ...
    // fila VGA 9 -> numero 7
    //
    // =========================================================

    always_comb begin

        label_area  = 1'b0;
        label_digit = 3'd0;


        // =====================================================
        // NUMEROS SUPERIORES J1
        // Fila VGA 1
        // =====================================================

        if (tile_y == 1 &&
            tile_x >= 1 &&
            tile_x <= 8) begin

            label_area  = 1'b1;
            label_digit = tile_x - 1;

        end


        // =====================================================
        // NUMEROS SUPERIORES J2
        // =====================================================

        else if (tile_y == 1 &&
                 tile_x >= 11 &&
                 tile_x <= 18) begin

            label_area  = 1'b1;
            label_digit = tile_x - 11;

        end


        // =====================================================
        // NUMEROS LATERALES J1
        // =====================================================

        else if (tile_x == 0 &&
                 tile_y >= 2 &&
                 tile_y <= 9) begin

            label_area  = 1'b1;
            label_digit = tile_y - 2;

        end


        // =====================================================
        // NUMEROS LATERALES J2
        // =====================================================

        else if (tile_x == 10 &&
                 tile_y >= 2 &&
                 tile_y <= 9) begin

            label_area  = 1'b1;
            label_digit = tile_y - 2;

        end

    end


    // =========================================================
    // DECODIFICADOR DE DIGITOS 0..7
    //
    //       AAA
    //      F   B
    //      F   B
    //       GGG
    //      E   C
    //      E   C
    //       DDD
    // =========================================================

    always_comb begin

        case (label_digit)

            3'd0:
                digit_segments = 7'b1111110;

            3'd1:
                digit_segments = 7'b0110000;

            3'd2:
                digit_segments = 7'b1101101;

            3'd3:
                digit_segments = 7'b1111001;

            3'd4:
                digit_segments = 7'b0110011;

            3'd5:
                digit_segments = 7'b1011011;

            3'd6:
                digit_segments = 7'b1011111;

            3'd7:
                digit_segments = 7'b1110000;

            default:
                digit_segments = 7'b0000000;

        endcase

    end


    // =========================================================
    // DIBUJO DE LOS NUMEROS
    // =========================================================

    always_comb begin

        digit_pixel = 1'b0;

        if (label_area) begin


            // Segmento A
            if (digit_segments[6] &&
                pixel_in_tile_x >= 9  &&
                pixel_in_tile_x <= 22 &&
                pixel_in_tile_y >= 5  &&
                pixel_in_tile_y <= 7)
                digit_pixel = 1'b1;


            // Segmento B
            if (digit_segments[5] &&
                pixel_in_tile_x >= 21 &&
                pixel_in_tile_x <= 23 &&
                pixel_in_tile_y >= 7  &&
                pixel_in_tile_y <= 15)
                digit_pixel = 1'b1;


            // Segmento C
            if (digit_segments[4] &&
                pixel_in_tile_x >= 21 &&
                pixel_in_tile_x <= 23 &&
                pixel_in_tile_y >= 16 &&
                pixel_in_tile_y <= 24)
                digit_pixel = 1'b1;


            // Segmento D
            if (digit_segments[3] &&
                pixel_in_tile_x >= 9  &&
                pixel_in_tile_x <= 22 &&
                pixel_in_tile_y >= 24 &&
                pixel_in_tile_y <= 26)
                digit_pixel = 1'b1;


            // Segmento E
            if (digit_segments[2] &&
                pixel_in_tile_x >= 8  &&
                pixel_in_tile_x <= 10 &&
                pixel_in_tile_y >= 16 &&
                pixel_in_tile_y <= 24)
                digit_pixel = 1'b1;


            // Segmento F
            if (digit_segments[1] &&
                pixel_in_tile_x >= 8  &&
                pixel_in_tile_x <= 10 &&
                pixel_in_tile_y >= 7  &&
                pixel_in_tile_y <= 15)
                digit_pixel = 1'b1;


            // Segmento G
            if (digit_segments[0] &&
                pixel_in_tile_x >= 9  &&
                pixel_in_tile_x <= 22 &&
                pixel_in_tile_y >= 15 &&
                pixel_in_tile_y <= 17)
                digit_pixel = 1'b1;

        end

    end


    // =========================================================
    // SALIDA VGA
    // =========================================================

    always_comb begin

        if (!video_on_i) begin

            rgb_o = 12'h000;

        end

        else if (digit_pixel) begin

            rgb_o = 12'hFF0;   // Coordenadas amarillas

        end

        else if (grid_border) begin

            rgb_o = 12'h000;   // Bordes negros

        end

        else begin

            rgb_o = color_palette;

        end

    end

endmodule