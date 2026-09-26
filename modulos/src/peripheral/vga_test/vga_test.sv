
module vga_test #(
    parameter int CLK_FREQ = 100_000_000
)(
    input  logic        clk_i,
    input  logic        rst_i,

    output logic        write_enable_o,
    output logic [31:0] addr_o,
    output logic [31:0] wdata_o
);

    // Dirección base de la VRAM de la VGA
    localparam logic [31:0] VRAM_BASE = 32'h0001_1000;

    // 2 segundos con un clock de 100 MHz
    localparam int WAIT_CYCLES = 2 * CLK_FREQ;

    typedef enum logic [2:0] {
        INIT,
        WRITE_MAP,
        WAIT_NORMAL,
        WRITE_RED,
        WAIT_RED
    } state_t;

    state_t state;

    // Tile que vamos a cambiar
    localparam int CHANGE_X = 10;
    localparam int CHANGE_Y = 7;

    localparam int CHANGE_ADDR =
        CHANGE_Y * 20 + CHANGE_X;

    logic [8:0] tile_index;
    logic [31:0] wait_counter;

    // ------------------------------------------------------------
    // Determina el contenido inicial de cada tile
    // ------------------------------------------------------------
    function automatic logic [2:0] tile_value(
        input int x,
        input int y
    );

        begin

            // Fondo: agua
            tile_value = 3'b000;

            // Borde verde
            if ((x == 0) || (x == 19) ||
                (y == 0) || (y == 14)) begin

                tile_value = 3'b100;
            end

            // Barco horizontal
            else if ((y == 3) &&
                     (x >= 2) &&
                     (x <= 6)) begin

                tile_value = 3'b001;
            end

            // Barco vertical
            else if ((x == 12) &&
                     (y >= 5) &&
                     (y <= 8)) begin

                tile_value = 3'b001;
            end

            // Fallo
            else if ((x == 8) && (y == 5)) begin

                tile_value = 3'b011;
            end

            // Fallo
            else if ((x == 15) && (y == 10)) begin

                tile_value = 3'b011;
            end

            // El tile que vamos a cambiar
            // inicialmente permanece azul
            else if ((x == CHANGE_X) &&
                     (y == CHANGE_Y)) begin

                tile_value = 3'b000;
            end
        end
    endfunction


    // ------------------------------------------------------------
    // FSM
    // ------------------------------------------------------------
    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            state        <= INIT;
            tile_index   <= 9'd0;
            wait_counter <= 32'd0;

        end else begin

            case (state)

                // ------------------------------------------------
                // Preparar escritura del mapa
                // ------------------------------------------------
                INIT: begin

                    tile_index <= 9'd0;

                    state <= WRITE_MAP;

                end


                // ------------------------------------------------
                // Escribir los 300 tiles
                // ------------------------------------------------
                WRITE_MAP: begin

                    if (tile_index == 9'd299) begin

                        tile_index   <= 9'd0;
                        wait_counter <= 32'd0;

                        state <= WAIT_NORMAL;

                    end else begin

                        tile_index <= tile_index + 1'b1;

                    end

                end


                // ------------------------------------------------
                // Esperar 2 segundos con el mapa normal
                // ------------------------------------------------
                WAIT_NORMAL: begin

                    if (wait_counter == WAIT_CYCLES - 1) begin

                        wait_counter <= 32'd0;

                        state <= WRITE_RED;

                    end else begin

                        wait_counter <= wait_counter + 1'b1;

                    end

                end


                // ------------------------------------------------
                // Después de 2 s, cambiar un tile a rojo
                // ------------------------------------------------
                WRITE_RED: begin

                    wait_counter <= 32'd0;

                    state <= WAIT_RED;

                end


                // ------------------------------------------------
                // Esperar 2 segundos con el tile rojo
                // ------------------------------------------------
                WAIT_RED: begin

                    if (wait_counter == WAIT_CYCLES - 1) begin

                        wait_counter <= 32'd0;

                        state <= WRITE_MAP;

                    end else begin

                        wait_counter <= wait_counter + 1'b1;

                    end

                end


                default: begin

                    state <= INIT;

                end

            endcase
        end
    end


    // ------------------------------------------------------------
    // Bus hacia la VGA
    // ------------------------------------------------------------
    always_comb begin

        // Valores por defecto:
        write_enable_o = 1'b0;
        addr_o         = 32'd0;
        wdata_o        = 32'd0;

        case (state)

            // ----------------------------------------------------
            // Escritura de los 300 tiles
            // ----------------------------------------------------
            WRITE_MAP: begin

                write_enable_o = 1'b1;

                addr_o =
                    VRAM_BASE +
                    (tile_index * 4);

                wdata_o =
                    {
                        29'd0,
                        tile_value(
                            tile_index % 20,
                            tile_index / 20
                        )
                    };
            end


            // ----------------------------------------------------
            // Escribir el tile rojo
            // ----------------------------------------------------
            WRITE_RED: begin

                write_enable_o = 1'b1;

                addr_o =
                    VRAM_BASE +
                    (CHANGE_ADDR * 4);

                wdata_o = {
                    29'd0,
                    3'b010
                };
            end

            default: begin

                write_enable_o = 1'b0;
                addr_o         = 32'd0;
                wdata_o        = 32'd0;

            end

        endcase

    end

endmodule