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

    logic [2:0]  tile_color;
    logic [4:0]  glyph_code;
    logic [11:0] color_palette;

    logic inside_board;
    logic grid_border;

    logic coord_label_area;
    logic [2:0] coord_digit;
    logic [6:0] digit_segments;
    logic coord_digit_pixel;

    logic glyph_pixel;


    assign tile_x = pixel_x_i[9:5];
    assign tile_y = pixel_y_i[9:5];

    assign pixel_in_tile_x = pixel_x_i[4:0];
    assign pixel_in_tile_y = pixel_y_i[4:0];


    // 20 columnas
    assign tile_addr_o =
        (tile_y << 4) +
        (tile_y << 2) +
        tile_x;


    // bits [2:0] = color
    // bits [7:3] = glifo
    assign tile_color = tile_data_i[2:0];
    assign glyph_code = tile_data_i[7:3];


    // =========================================================
    // PALETA
    // =========================================================

    always_comb begin

        case (tile_color)

            3'd0: color_palette = 12'h00F; // Azul
            3'd1: color_palette = 12'h888; // Gris
            3'd2: color_palette = 12'hF00; // Rojo
            3'd3: color_palette = 12'hFFF; // Blanco
            3'd4: color_palette = 12'h0F0; // Verde
            3'd5: color_palette = 12'hFF0; // Amarillo
            3'd6: color_palette = 12'h0FF; // Cian
            3'd7: color_palette = 12'h000; // Negro

            default:
                color_palette = 12'h00F;

        endcase

    end


    // =========================================================
    // TABLEROS
    //
    // J1: columnas 1..8
    // J2: columnas 11..18
    // filas: 2..9
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
    // CUADRICULA
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
    // COORDENADAS 0..7
    // =========================================================

    always_comb begin

        coord_label_area = 1'b0;
        coord_digit      = 3'd0;


        // Superior J1
        if (tile_y == 1 &&
            tile_x >= 1 &&
            tile_x <= 8) begin

            coord_label_area = 1'b1;
            coord_digit      = tile_x - 1;

        end


        // Superior J2
        else if (tile_y == 1 &&
                 tile_x >= 11 &&
                 tile_x <= 18) begin

            coord_label_area = 1'b1;
            coord_digit      = tile_x - 11;

        end


        // Lateral J1
        else if (tile_x == 0 &&
                 tile_y >= 2 &&
                 tile_y <= 9) begin

            coord_label_area = 1'b1;
            coord_digit      = tile_y - 2;

        end


        // Lateral J2
        else if (tile_x == 10 &&
                 tile_y >= 2 &&
                 tile_y <= 9) begin

            coord_label_area = 1'b1;
            coord_digit      = tile_y - 2;

        end

    end


    // =========================================================
    // NUMEROS 0..7
    // =========================================================

    always_comb begin

        case (coord_digit)

            3'd0: digit_segments = 7'b1111110;
            3'd1: digit_segments = 7'b0110000;
            3'd2: digit_segments = 7'b1101101;
            3'd3: digit_segments = 7'b1111001;
            3'd4: digit_segments = 7'b0110011;
            3'd5: digit_segments = 7'b1011011;
            3'd6: digit_segments = 7'b1011111;
            3'd7: digit_segments = 7'b1110000;

            default:
                digit_segments = 7'b0000000;

        endcase

    end


    always_comb begin

        coord_digit_pixel = 1'b0;

        if (coord_label_area) begin


            // A
            if (digit_segments[6] &&
                pixel_in_tile_x >= 9  &&
                pixel_in_tile_x <= 22 &&
                pixel_in_tile_y >= 5  &&
                pixel_in_tile_y <= 7)
                coord_digit_pixel = 1'b1;


            // B
            if (digit_segments[5] &&
                pixel_in_tile_x >= 21 &&
                pixel_in_tile_x <= 23 &&
                pixel_in_tile_y >= 7  &&
                pixel_in_tile_y <= 15)
                coord_digit_pixel = 1'b1;


            // C
            if (digit_segments[4] &&
                pixel_in_tile_x >= 21 &&
                pixel_in_tile_x <= 23 &&
                pixel_in_tile_y >= 16 &&
                pixel_in_tile_y <= 24)
                coord_digit_pixel = 1'b1;


            // D
            if (digit_segments[3] &&
                pixel_in_tile_x >= 9  &&
                pixel_in_tile_x <= 22 &&
                pixel_in_tile_y >= 24 &&
                pixel_in_tile_y <= 26)
                coord_digit_pixel = 1'b1;


            // E
            if (digit_segments[2] &&
                pixel_in_tile_x >= 8  &&
                pixel_in_tile_x <= 10 &&
                pixel_in_tile_y >= 16 &&
                pixel_in_tile_y <= 24)
                coord_digit_pixel = 1'b1;


            // F
            if (digit_segments[1] &&
                pixel_in_tile_x >= 8  &&
                pixel_in_tile_x <= 10 &&
                pixel_in_tile_y >= 7  &&
                pixel_in_tile_y <= 15)
                coord_digit_pixel = 1'b1;


            // G
            if (digit_segments[0] &&
                pixel_in_tile_x >= 9  &&
                pixel_in_tile_x <= 22 &&
                pixel_in_tile_y >= 15 &&
                pixel_in_tile_y <= 17)
                coord_digit_pixel = 1'b1;

        end

    end


    // =========================================================
    // GLIFOS
    //
    // 1 = J
    // 2 = 1
    // 3 = 2
    // 4 = mini barco
    // =========================================================

    always_comb begin

        glyph_pixel = 1'b0;


        case (glyph_code)


            // -------------------------------------------------
            // J
            // -------------------------------------------------

            5'd1: begin

                if (pixel_in_tile_y >= 5 &&
                    pixel_in_tile_y <= 8 &&
                    pixel_in_tile_x >= 8 &&
                    pixel_in_tile_x <= 23)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_x >= 20 &&
                    pixel_in_tile_x <= 23 &&
                    pixel_in_tile_y >= 5 &&
                    pixel_in_tile_y <= 23)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_y >= 23 &&
                    pixel_in_tile_y <= 26 &&
                    pixel_in_tile_x >= 8 &&
                    pixel_in_tile_x <= 23)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_x >= 8 &&
                    pixel_in_tile_x <= 11 &&
                    pixel_in_tile_y >= 18 &&
                    pixel_in_tile_y <= 24)
                    glyph_pixel = 1'b1;

            end


            // -------------------------------------------------
            // 1
            // -------------------------------------------------

            5'd2: begin

                if (pixel_in_tile_x >= 14 &&
                    pixel_in_tile_x <= 17 &&
                    pixel_in_tile_y >= 5 &&
                    pixel_in_tile_y <= 26)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_x >= 11 &&
                    pixel_in_tile_x <= 14 &&
                    pixel_in_tile_y >= 8 &&
                    pixel_in_tile_y <= 11)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_y >= 24 &&
                    pixel_in_tile_y <= 27 &&
                    pixel_in_tile_x >= 10 &&
                    pixel_in_tile_x <= 21)
                    glyph_pixel = 1'b1;

            end


            // -------------------------------------------------
            // 2
            // -------------------------------------------------

            5'd3: begin

                if (pixel_in_tile_y >= 5 &&
                    pixel_in_tile_y <= 8 &&
                    pixel_in_tile_x >= 8 &&
                    pixel_in_tile_x <= 23)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_x >= 20 &&
                    pixel_in_tile_x <= 23 &&
                    pixel_in_tile_y >= 6 &&
                    pixel_in_tile_y <= 15)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_y >= 14 &&
                    pixel_in_tile_y <= 18 &&
                    pixel_in_tile_x >= 8 &&
                    pixel_in_tile_x <= 23)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_x >= 8 &&
                    pixel_in_tile_x <= 11 &&
                    pixel_in_tile_y >= 17 &&
                    pixel_in_tile_y <= 25)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_y >= 24 &&
                    pixel_in_tile_y <= 27 &&
                    pixel_in_tile_x >= 8 &&
                    pixel_in_tile_x <= 23)
                    glyph_pixel = 1'b1;

            end


            // -------------------------------------------------
            // MINI BARCO
            // -------------------------------------------------

            5'd4: begin

                // Mastil
                if (pixel_in_tile_x >= 15 &&
                    pixel_in_tile_x <= 16 &&
                    pixel_in_tile_y >= 7 &&
                    pixel_in_tile_y <= 14)
                    glyph_pixel = 1'b1;


                // Cabina
                if (pixel_in_tile_x >= 12 &&
                    pixel_in_tile_x <= 19 &&
                    pixel_in_tile_y >= 12 &&
                    pixel_in_tile_y <= 16)
                    glyph_pixel = 1'b1;


                // Cubierta
                if (pixel_in_tile_x >= 7 &&
                    pixel_in_tile_x <= 24 &&
                    pixel_in_tile_y >= 16 &&
                    pixel_in_tile_y <= 19)
                    glyph_pixel = 1'b1;


                // Casco
                if (pixel_in_tile_x >= 9 &&
                    pixel_in_tile_x <= 22 &&
                    pixel_in_tile_y >= 20 &&
                    pixel_in_tile_y <= 23)
                    glyph_pixel = 1'b1;


                if (pixel_in_tile_x >= 12 &&
                    pixel_in_tile_x <= 19 &&
                    pixel_in_tile_y >= 24 &&
                    pixel_in_tile_y <= 25)
                    glyph_pixel = 1'b1;

            end


            default:
                glyph_pixel = 1'b0;

        endcase

    end


    // =========================================================
    // SALIDA VGA
    // =========================================================

    always_comb begin

        if (!video_on_i) begin

            rgb_o = 12'h000;

        end


        else if (coord_digit_pixel) begin

            rgb_o = 12'hFF0;

        end


        else if (grid_border) begin

            rgb_o = 12'h000;

        end


        else if (glyph_code != 0) begin

            if (glyph_pixel)
                rgb_o = color_palette;
            else
                rgb_o = 12'h00F;

        end


        else begin

            rgb_o = color_palette;

        end

    end

endmodule