`timescale 1ns/1ps

module soc_top_tb;

    // ============================================================
    // CONSTANTES DEL SoC
    // ============================================================

    localparam logic [31:0] UART_STATUS  = 32'h0001_0040;
    localparam logic [31:0] UART_TX      = 32'h0001_0044;
    localparam logic [31:0] GPIO_BASE    = 32'h0001_0120;

    localparam logic [31:0] RAM_BASE     = 32'h0000_2000;
    localparam logic [31:0] LOCAL_BOARD  = 32'h0000_2000;
    localparam logic [31:0] REMOTE_BOARD = 32'h0000_2100;
    localparam logic [31:0] P1_WINS      = 32'h0000_2F00;
    localparam logic [31:0] P2_WINS      = 32'h0000_2F04;

    localparam int LOCAL_BASE_IDX  =
        (LOCAL_BOARD - RAM_BASE) >> 2;

    localparam int REMOTE_BASE_IDX =
        (REMOTE_BOARD - RAM_BASE) >> 2;

    localparam int P1_WINS_IDX =
        (P1_WINS - RAM_BASE) >> 2;

    localparam int P2_WINS_IDX =
        (P2_WINS - RAM_BASE) >> 2;


    // ============================================================
    // PROTOCOLO UART
    // ============================================================

    localparam logic [7:0] STX       = 8'h02;
    localparam logic [7:0] ETX       = 8'h03;

    localparam logic [7:0] CMD_PLACE = 8'h01;
    localparam logic [7:0] CMD_FIRE  = 8'h02;

    localparam logic [7:0] EVT_PLACE_START  = 8'h80;
    localparam logic [7:0] EVT_PLACE_OK     = 8'h81;
    localparam logic [7:0] EVT_PLACE_BAD    = 8'h82;
    localparam logic [7:0] EVT_BATTLE_START = 8'h83;
    localparam logic [7:0] EVT_TURN         = 8'h84;

    // J2 dispara -> resultado propio de J2
    localparam logic [7:0] EVT_SHOT_RESULT  = 8'h85;

    // J1 dispara -> J2 recibe el disparo
    localparam logic [7:0] EVT_INCOMING     = 8'h86;

    localparam logic [7:0] EVT_GAME_OVER    = 8'h87;


    // ============================================================
    // BOTONES
    // ============================================================

    localparam logic [6:0] BTN_UP     = 7'b010_0000;
    localparam logic [6:0] BTN_DOWN   = 7'b001_0000;
    localparam logic [6:0] BTN_LEFT   = 7'b000_1000;
    localparam logic [6:0] BTN_RIGHT  = 7'b000_0100;
    localparam logic [6:0] BTN_SELECT = 7'b000_0010;
    localparam logic [6:0] BTN_OK     = 7'b000_0001;


    // ============================================================
    // TIEMPOS
    // ============================================================

    localparam integer UART_BIT_NS = 8640;

    // 50 ms a 100 MHz
    localparam integer WAIT_CYCLES = 5_000_000;


    // ============================================================
    // SEÑALES DEL DUT
    // ============================================================

    logic clk100mhz = 1'b0;

    logic btnC = 1'b1;
    logic btnU = 1'b0;
    logic btnD = 1'b0;
    logic btnL = 1'b0;
    logic btnR = 1'b0;

    logic [1:0] sw = 2'b00;

    logic uart_rx = 1'b1;
    logic uart_tx;

    logic [15:0] led;

    logic [6:0] seg;
    logic dp;
    logic [3:0] an;

    logic buzzer;

    logic hsync;
    logic vsync;

    logic [3:0] vgaRed;
    logic [3:0] vgaGreen;
    logic [3:0] vgaBlue;


    // ============================================================
    // DUT
    // ============================================================

    soc_top dut (

        .clk100mhz(clk100mhz),

        .btnC(btnC),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),

        .sw(sw),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),

        .led(led),

        .seg(seg),
        .dp(dp),
        .an(an),

        .buzzer(buzzer),

        .hsync(hsync),
        .vsync(vsync),

        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)

    );


    // ============================================================
    // CLOCK 100 MHz
    // ============================================================

    always #5 clk100mhz = ~clk100mhz;


    // ============================================================
    // MONITOR UART FPGA -> PC
    //
    // Observamos directamente los writes MMIO del CPU.
    // ============================================================

    integer tx_state = 0;

    integer tx_len = 0;

    integer tx_payload_idx = 0;

    logic [7:0] tx_cmd = 8'h00;

    logic [7:0] tx_checksum = 8'h00;

    logic [7:0] tx_byte;


    integer count_place_start  = 0;

    integer count_place_ok     = 0;

    integer count_place_bad    = 0;

    integer count_battle_start = 0;

    integer count_turn         = 0;

    integer count_shot_result  = 0;

    integer count_incoming     = 0;

    integer count_game_over    = 0;


    always @(posedge clk100mhz) begin

        if (
            dut.data_write_enable === 1'b1 &&
            dut.data_address === UART_TX
        ) begin

            tx_byte = dut.data_write[7:0];


            case (tx_state)


                // ----------------------------------------------------
                // Esperar STX
                // ----------------------------------------------------

                0: begin

                    if (tx_byte == STX)
                        tx_state = 1;

                end


                // ----------------------------------------------------
                // CMD
                // ----------------------------------------------------

                1: begin

                    tx_cmd = tx_byte;

                    tx_checksum = tx_byte;

                    tx_state = 2;

                end


                // ----------------------------------------------------
                // LEN
                // ----------------------------------------------------

                2: begin

                    tx_len = tx_byte;

                    tx_payload_idx = 0;

                    tx_checksum =
                        tx_checksum ^ tx_byte;

                    if (tx_byte == 0)
                        tx_state = 4;
                    else
                        tx_state = 3;

                end


                // ----------------------------------------------------
                // PAYLOAD
                // ----------------------------------------------------

                3: begin

                    tx_checksum =
                        tx_checksum ^ tx_byte;

                    tx_payload_idx =
                        tx_payload_idx + 1;

                    if (
                        tx_payload_idx >= tx_len
                    )
                        tx_state = 4;

                end


                // ----------------------------------------------------
                // CHECKSUM
                // ----------------------------------------------------

                4: begin

                    if (
                        tx_byte !== tx_checksum
                    ) begin

                        $error(
                            "UART TX checksum incorrecto. CMD=%02h esperado=%02h recibido=%02h",
                            tx_cmd,
                            tx_checksum,
                            tx_byte
                        );

                    end

                    tx_state = 5;

                end


                // ----------------------------------------------------
                // ETX
                // ----------------------------------------------------

                5: begin

                    if (tx_byte !== ETX) begin

                        $error(
                            "UART TX ETX incorrecto. CMD=%02h recibido=%02h",
                            tx_cmd,
                            tx_byte
                        );

                    end
                    else begin

                        $display(
                            "[%0t] UART FPGA->PC: CMD=%02h LEN=%0d",
                            $time,
                            tx_cmd,
                            tx_len
                        );


                        case (tx_cmd)

                            EVT_PLACE_START:
                                count_place_start =
                                    count_place_start + 1;

                            EVT_PLACE_OK:
                                count_place_ok =
                                    count_place_ok + 1;

                            EVT_PLACE_BAD:
                                count_place_bad =
                                    count_place_bad + 1;

                            EVT_BATTLE_START:
                                count_battle_start =
                                    count_battle_start + 1;

                            EVT_TURN:
                                count_turn =
                                    count_turn + 1;

                            EVT_SHOT_RESULT:
                                count_shot_result =
                                    count_shot_result + 1;

                            EVT_INCOMING:
                                count_incoming =
                                    count_incoming + 1;

                            EVT_GAME_OVER:
                                count_game_over =
                                    count_game_over + 1;

                            default:
                                ;

                        endcase

                    end


                    tx_state = 0;

                end


                default:
                    tx_state = 0;


            endcase

        end

    end


    // ============================================================
    // ESPERAR POLLING UART
    // ============================================================

    task automatic wait_uart_poll;

        integer n;

        begin

            n = 0;


            while (
                !(
                    dut.data_address === UART_STATUS &&
                    dut.data_write_enable === 1'b0 &&
                    dut.prog_instr[6:0] === 7'b0000011
                )
            ) begin

                @(posedge clk100mhz);

                n = n + 1;


                if (n >= WAIT_CYCLES) begin

                    $fatal(
                        1,
                        "Timeout esperando lectura UART STATUS. PC=%08h",
                        dut.prog_address
                    );

                end

            end

        end

    endtask


    // ============================================================
    // ESPERAR EVENTO UART
    // ============================================================

    task automatic wait_event_count(

        input logic [7:0] event_cmd,

        input integer target

    );

        integer n;

        integer current_count;


        begin

            n = 0;

            current_count = 0;


            while (
                current_count < target
            ) begin


                case (event_cmd)

                    EVT_PLACE_START:
                        current_count =
                            count_place_start;

                    EVT_PLACE_OK:
                        current_count =
                            count_place_ok;

                    EVT_PLACE_BAD:
                        current_count =
                            count_place_bad;

                    EVT_BATTLE_START:
                        current_count =
                            count_battle_start;

                    EVT_TURN:
                        current_count =
                            count_turn;

                    EVT_SHOT_RESULT:
                        current_count =
                            count_shot_result;

                    EVT_INCOMING:
                        current_count =
                            count_incoming;

                    EVT_GAME_OVER:
                        current_count =
                            count_game_over;

                    default:
                        current_count = 0;

                endcase


                if (
                    current_count < target
                ) begin

                    @(posedge clk100mhz);

                    n = n + 1;


                    if (n >= WAIT_CYCLES) begin

                        $fatal(
                            1,
                            "Timeout esperando evento UART CMD=%02h target=%0d",
                            event_cmd,
                            target
                        );

                    end

                end

            end

        end

    endtask


    // ============================================================
    // PRESIONAR BOTÓN GPIO
    //
    // Se fuerza directamente btns_debounced para no esperar
    // ~10 ms por cada debounce.
    // ============================================================

    task press_gpio(

        input logic [6:0] mask

    );

        integer n;


        begin

            $display(
                "[%0t] TB: presionando GPIO mask=%02h PC=%08h",
                $time,
                mask,
                dut.prog_address
            );


            // ----------------------------------------------------
            // Presionar
            // ----------------------------------------------------

            @(negedge clk100mhz);

            force dut.u_gpio.btns_debounced = mask;


            // ----------------------------------------------------
            // Esperar que CPU lea el botón
            // ----------------------------------------------------

            n = 0;


            do begin

                @(posedge clk100mhz);

                n = n + 1;


                if (n >= WAIT_CYCLES) begin

                    $fatal(
                        1,
                        "Timeout esperando lectura GPIO. mask=%02h PC=%08h",
                        mask,
                        dut.prog_address
                    );

                end

            end
            while (
                !(
                    dut.data_address === GPIO_BASE &&
                    dut.data_write_enable === 1'b0 &&
                    dut.prog_instr[6:0] === 7'b0000011 &&
                    dut.data_read[6:0] === mask
                )
            );


            $display(
                "[%0t] TB: CPU detecto GPIO=%02h PC=%08h",
                $time,
                dut.data_read[6:0],
                dut.prog_address
            );


            // Dejar que lw / andi capturen el dato.
            repeat (4)
                @(posedge clk100mhz);


            // ----------------------------------------------------
            // Soltar botón
            // ----------------------------------------------------

            @(negedge clk100mhz);

            force dut.u_gpio.btns_debounced =
                7'b0000000;


            $display(
                "[%0t] TB: soltando GPIO mask=%02h",
                $time,
                mask
            );


            // ----------------------------------------------------
            // Esperar que wait_release vea cero
            // ----------------------------------------------------

            n = 0;


            do begin

                @(posedge clk100mhz);

                n = n + 1;


                if (n >= WAIT_CYCLES) begin

                    $fatal(
                        1,
                        "Timeout esperando liberacion GPIO. PC=%08h",
                        dut.prog_address
                    );

                end

            end
            while (
                !(
                    dut.data_address === GPIO_BASE &&
                    dut.data_write_enable === 1'b0 &&
                    dut.prog_instr[6:0] === 7'b0000011 &&
                    dut.data_read[6:0] === 7'b0000000
                )
            );


            repeat (4)
                @(posedge clk100mhz);


            release dut.u_gpio.btns_debounced;


            $display(
                "[%0t] TB: GPIO liberado mask=%02h",
                $time,
                mask
            );

        end

    endtask


    // ============================================================
    // UART PC -> FPGA
    // ============================================================

    task automatic uart_send_byte(

        input logic [7:0] data

    );

        integer i;


        begin

            // Start bit
            uart_rx = 1'b0;

            #(UART_BIT_NS);


            // 8 bits LSB first
            for (
                i = 0;
                i < 8;
                i = i + 1
            ) begin

                uart_rx = data[i];

                #(UART_BIT_NS);

            end


            // Stop bit
            uart_rx = 1'b1;

            #(UART_BIT_NS);

        end

    endtask


    // ============================================================
    // ENVIAR COLOCACIÓN J2
    // ============================================================

    task automatic send_place(

        input logic [7:0] ship_id,

        input logic [7:0] row,

        input logic [7:0] col,

        input logic [7:0] orientation

    );

        logic [7:0] chk;


        begin

            wait_uart_poll();


            chk =
                CMD_PLACE ^
                8'd4 ^
                ship_id ^
                row ^
                col ^
                orientation;


            $display(
                "[%0t] PC->FPGA PLACE id=%0d row=%0d col=%0d ori=%0d",
                $time,
                ship_id,
                row,
                col,
                orientation
            );


            uart_send_byte(STX);

            uart_send_byte(CMD_PLACE);

            uart_send_byte(8'd4);

            uart_send_byte(ship_id);

            uart_send_byte(row);

            uart_send_byte(col);

            uart_send_byte(orientation);

            uart_send_byte(chk);

            uart_send_byte(ETX);

        end

    endtask


    // ============================================================
    // ENVIAR DISPARO J2
    // ============================================================

    task automatic send_fire(

        input logic [7:0] row,

        input logic [7:0] col

    );

        logic [7:0] chk;


        begin

            wait_uart_poll();


            chk =
                CMD_FIRE ^
                8'd2 ^
                row ^
                col;


            $display(
                "[%0t] PC->FPGA FIRE row=%0d col=%0d",
                $time,
                row,
                col
            );


            uart_send_byte(STX);

            uart_send_byte(CMD_FIRE);

            uart_send_byte(8'd2);

            uart_send_byte(row);

            uart_send_byte(col);

            uart_send_byte(chk);

            uart_send_byte(ETX);

        end

    endtask


    // ============================================================
    // COLOCAR BARCO J1
    // ============================================================

    task automatic local_place_ship(

        input integer row,

        input integer col,

        input logic vertical

    );

        integer i;


        begin

            for (
                i = 0;
                i < row;
                i = i + 1
            )
                press_gpio(BTN_DOWN);


            for (
                i = 0;
                i < col;
                i = i + 1
            )
                press_gpio(BTN_RIGHT);


            if (vertical)
                press_gpio(BTN_SELECT);


            press_gpio(BTN_OK);

        end

    endtask


    // ============================================================
    // DISPARO J1
    // ============================================================

    task automatic local_fire(

        input integer row,

        input integer col

    );

        integer i;


        begin

            // El firmware reinicia cursor a 0,0.

            for (
                i = 0;
                i < row;
                i = i + 1
            )
                press_gpio(BTN_DOWN);


            for (
                i = 0;
                i < col;
                i = i + 1
            )
                press_gpio(BTN_RIGHT);


            press_gpio(BTN_OK);

        end

    endtask


    // ============================================================
    // RONDA COMPLETA
    //
    // J1 dispara
    //   -> CMD 86
    //   -> CMD 84 turno J2
    //
    // J2 dispara
    //   -> CMD 85
    //   -> CMD 84 turno J1
    // ============================================================

    task automatic play_round(

        input integer round_no,

        input integer j1_row,

        input integer j1_col,

        input logic [7:0] j2_row,

        input logic [7:0] j2_col

    );

        begin

            // ----------------------------------------------------
            // J1 dispara
            // ----------------------------------------------------

            local_fire(
                j1_row,
                j1_col
            );


            // J1 disparó sobre J2.
            // PC recibe CMD 86.
            wait_event_count(
                EVT_INCOMING,
                round_no
            );


            // Cambio de turno hacia J2.
            wait_event_count(
                EVT_TURN,
                2 * round_no
            );


            // ----------------------------------------------------
            // J2 dispara
            // ----------------------------------------------------

            send_fire(
                j2_row,
                j2_col
            );


            // Resultado propio de J2.
            // PC recibe CMD 85.
            wait_event_count(
                EVT_SHOT_RESULT,
                round_no
            );


            // Regresar turno a J1.
            wait_event_count(
                EVT_TURN,
                2 * round_no + 1
            );

        end

    endtask


    // ============================================================
    // COMPROBAR CELDA RAM
    // ============================================================

    task automatic expect_cell(

        input integer base_idx,

        input integer row,

        input integer col,

        input logic [31:0] expected

    );

        integer idx;


        begin

            idx =
                base_idx +
                row * 8 +
                col;


            if (
                dut.u_data_ram.mem[idx] !== expected
            ) begin

                $fatal(
                    1,
                    "Celda incorrecta: base=%0d row=%0d col=%0d esperado=%08h recibido=%08h",
                    base_idx,
                    row,
                    col,
                    expected,
                    dut.u_data_ram.mem[idx]
                );

            end

        end

    endtask


    // ============================================================
    // TEST PRINCIPAL
    // ============================================================

    initial begin


        $display(
            "============================================================"
        );

        $display(
            " soc_top_tb - integración completa batalla naval"
        );

        $display(
            "============================================================"
        );


        uart_rx = 1'b1;

        btnC = 1'b1;


        // ========================================================
        // RESET
        // ========================================================

        repeat (20)
            @(posedge clk100mhz);


        btnC = 1'b0;


        // ========================================================
        // ESPERAR FASE COLOCACIÓN
        // ========================================================

        wait_event_count(
            EVT_PLACE_START,
            1
        );


        $display(
            "PASS: firmware llegó a fase de colocación"
        );


        // ========================================================
        // COLOCACIÓN J1
        //
        // Barco 0:
        // row 0 col 0 horizontal, largo 4
        //
        // Barco 1:
        // row 1 col 0 horizontal, largo 3
        //
        // Barco 2:
        // row 2 col 0 horizontal, largo 2
        // ========================================================

        local_place_ship(
            0,
            0,
            1'b0
        );


        local_place_ship(
            1,
            0,
            1'b0
        );


        local_place_ship(
            2,
            0,
            1'b0
        );


        // Esperar que firmware pase a UART J2.
        wait_uart_poll();


        // ========================================================
        // VERIFICAR J1
        // ========================================================

        expect_cell(
            LOCAL_BASE_IDX,
            0,
            0,
            32'd1
        );

        expect_cell(
            LOCAL_BASE_IDX,
            0,
            1,
            32'd1
        );

        expect_cell(
            LOCAL_BASE_IDX,
            0,
            2,
            32'd1
        );

        expect_cell(
            LOCAL_BASE_IDX,
            0,
            3,
            32'd1
        );


        expect_cell(
            LOCAL_BASE_IDX,
            1,
            0,
            32'd1
        );

        expect_cell(
            LOCAL_BASE_IDX,
            1,
            1,
            32'd1
        );

        expect_cell(
            LOCAL_BASE_IDX,
            1,
            2,
            32'd1
        );


        expect_cell(
            LOCAL_BASE_IDX,
            2,
            0,
            32'd1
        );

        expect_cell(
            LOCAL_BASE_IDX,
            2,
            1,
            32'd1
        );


        $display(
            "PASS: flota local colocada correctamente"
        );


        // ========================================================
        // COLOCACIÓN J2
        //
        // Barco 0:
        // (0,4), vertical
        //
        // Barco 1:
        // (4,0), horizontal
        //
        // Barco 2:
        // (6,0), horizontal
        // ========================================================

        send_place(
            8'd0,
            8'd0,
            8'd4,
            8'd1
        );


        wait_event_count(
            EVT_PLACE_OK,
            1
        );


        send_place(
            8'd1,
            8'd4,
            8'd0,
            8'd0
        );


        wait_event_count(
            EVT_PLACE_OK,
            2
        );


        send_place(
            8'd2,
            8'd6,
            8'd0,
            8'd0
        );


        wait_event_count(
            EVT_PLACE_OK,
            3
        );


        wait_event_count(
            EVT_BATTLE_START,
            1
        );


        $display(
            "PASS: flota remota aceptada; inició batalla"
        );


        // ========================================================
        // VERIFICAR J2
        // ========================================================

        expect_cell(
            REMOTE_BASE_IDX,
            0,
            4,
            32'd1
        );

        expect_cell(
            REMOTE_BASE_IDX,
            1,
            4,
            32'd1
        );

        expect_cell(
            REMOTE_BASE_IDX,
            2,
            4,
            32'd1
        );

        expect_cell(
            REMOTE_BASE_IDX,
            3,
            4,
            32'd1
        );


        expect_cell(
            REMOTE_BASE_IDX,
            4,
            0,
            32'd1
        );

        expect_cell(
            REMOTE_BASE_IDX,
            4,
            1,
            32'd1
        );

        expect_cell(
            REMOTE_BASE_IDX,
            4,
            2,
            32'd1
        );


        expect_cell(
            REMOTE_BASE_IDX,
            6,
            0,
            32'd1
        );

        expect_cell(
            REMOTE_BASE_IDX,
            6,
            1,
            32'd1
        );


        $display(
            "PASS: flota J2 almacenada correctamente"
        );


        // ========================================================
        // TURNO INICIAL J1
        // ========================================================

        wait_event_count(
            EVT_TURN,
            1
        );


        $display(
            "PASS: turno inicial de J1 recibido"
        );


        // ========================================================
        // RONDA 1
        //
        // J1 golpea (0,4)
        // J2 falla (7,0)
        // ========================================================

        play_round(
            1,
            0,
            4,
            8'd7,
            8'd0
        );


        // ========================================================
        // RONDA 2
        // ========================================================

        play_round(
            2,
            1,
            4,
            8'd7,
            8'd1
        );


        // ========================================================
        // RONDA 3
        // ========================================================

        play_round(
            3,
            2,
            4,
            8'd7,
            8'd2
        );


        // ========================================================
        // RONDA 4
        // ========================================================

        play_round(
            4,
            3,
            4,
            8'd7,
            8'd3
        );


        // ========================================================
        // RONDA 5
        // ========================================================

        play_round(
            5,
            4,
            0,
            8'd7,
            8'd4
        );


        // ========================================================
        // RONDA 6
        // ========================================================

        play_round(
            6,
            4,
            1,
            8'd7,
            8'd5
        );


        // ========================================================
        // RONDA 7
        // ========================================================

        play_round(
            7,
            4,
            2,
            8'd7,
            8'd6
        );


        // ========================================================
        // RONDA 8
        // ========================================================

        play_round(
            8,
            6,
            0,
            8'd7,
            8'd7
        );


        // ========================================================
        // NOVENO IMPACTO
        //
        // J1 golpea última casilla de J2.
        // Aquí J1 debe ganar.
        // ========================================================

        local_fire(
            6,
            1
        );


        wait_event_count(
            EVT_INCOMING,
            9
        );


        wait_event_count(
            EVT_GAME_OVER,
            1
        );


        $display(
            "PASS: GAME_OVER recibido"
        );


        // ========================================================
        // VERIFICAR SCORE
        // ========================================================

        if (
            dut.u_data_ram.mem[P1_WINS_IDX] !==
            32'd1
        ) begin

            $fatal(
                1,
                "P1_WINS incorrecto: %08h",
                dut.u_data_ram.mem[P1_WINS_IDX]
            );

        end


        if (
            dut.u_data_ram.mem[P2_WINS_IDX] !==
            32'd0
        ) begin

            $fatal(
                1,
                "P2_WINS incorrecto: %08h",
                dut.u_data_ram.mem[P2_WINS_IDX]
            );

        end


        // ========================================================
        // LED DE VICTORIA
        // ========================================================

        if (
            led !== 16'h0004
        ) begin

            $fatal(
                1,
                "LED final incorrecto. Esperado=0004 recibido=%04h",
                led
            );

        end


        // ========================================================
        // DISPLAY
        //
        // J1 = 01
        // J2 = 00
        //
        // 0x0100
        // ========================================================

        if (
            dut.u_display.datos_reg !==
            32'h0000_0100
        ) begin

            $fatal(
                1,
                "Display incorrecto. Esperado=00000100 recibido=%08h",
                dut.u_display.datos_reg
            );

        end


        // ========================================================
        // EVENTOS UART
        // ========================================================

        if (
            count_place_bad != 0
        ) begin

            $fatal(
                1,
                "Hubo %0d colocaciones rechazadas",
                count_place_bad
            );

        end


        // J1 disparó 9 veces.
        if (
            count_incoming != 9
        ) begin

            $fatal(
                1,
                "Esperados 9 CMD=86. Recibidos=%0d",
                count_incoming
            );

        end


        // J2 disparó 8 veces.
        if (
            count_shot_result != 8
        ) begin

            $fatal(
                1,
                "Esperados 8 CMD=85. Recibidos=%0d",
                count_shot_result
            );

        end


        // Turno inicial +
        // 2 cambios por cada una de las 8 rondas.
        if (
            count_turn != 17
        ) begin

            $fatal(
                1,
                "Esperados 17 CMD=84. Recibidos=%0d",
                count_turn
            );

        end


        $display(
            "PASS: score J1=01 J2=00"
        );


        $display(
            "PASS: eventos UART correctos"
        );


        // ========================================================
        // RESET Y PERSISTENCIA DEL SCORE
        // ========================================================

        btnC = 1'b1;


        repeat (20)
            @(posedge clk100mhz);


        btnC = 1'b0;


        // Esperar que _start vuelva a escribir score.
        begin : wait_score_restore

            integer n;

            n = 0;


            while (
                dut.u_display.datos_reg !==
                32'h0000_0100
            ) begin

                @(posedge clk100mhz);

                n = n + 1;


                if (
                    n >= WAIT_CYCLES
                ) begin

                    $fatal(
                        1,
                        "Score no restaurado despues de BTN_RST"
                    );

                end

            end

        end


        // ========================================================
        // VERIFICAR PERSISTENCIA RAM
        // ========================================================

        if (
            dut.u_data_ram.mem[P1_WINS_IDX] !==
            32'd1
        ) begin

            $fatal(
                1,
                "BTN_RST borro P1_WINS"
            );

        end


        if (
            dut.u_data_ram.mem[P2_WINS_IDX] !==
            32'd0
        ) begin

            $fatal(
                1,
                "BTN_RST altero P2_WINS"
            );

        end


        $display(
            "PASS: BTN_RST conserva score acumulado"
        );


        $display(
            "============================================================"
        );

        $display(
            " soc_top_tb: ALL TESTS PASSED"
        );

        $display(
            "============================================================"
        );


        $finish;

    end


endmodule