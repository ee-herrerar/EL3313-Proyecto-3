`timescale 1ns/1ps

module soc_top_tb;

    // ============================================================
    // CONFIGURACION DE DEBUG
    // ============================================================

    localparam bit TRACE_UART_FRAMES = 1'b1;
    localparam bit TRACE_GPIO        = 1'b1;
    localparam bit TRACE_BUZZER      = 1'b1;
    localparam bit TRACE_LED         = 1'b0;
    localparam bit TRACE_DISPLAY     = 1'b0;
    localparam bit TRACE_VGA         = 1'b0;
    localparam bit TRACE_RAM_WRITES  = 1'b0;

    // El firmware actual sigue colocando:
    //
    //     J1 primero
    //     J2 despues
    //
    // Por eso esta prueba se deja preparada pero desactivada.
    // Cuando implementemos colocacion concurrente, cambiar a 1.
    localparam bit REQUIRE_CONCURRENT_PLACEMENT = 1'b1;


    // ============================================================
    // DIRECCIONES DEL SOC
    // ============================================================

    localparam logic [31:0] UART_STATUS  = 32'h0001_0040;
    localparam logic [31:0] UART_TX      = 32'h0001_0044;
    localparam logic [31:0] UART_RX      = 32'h0001_0048;

    localparam logic [31:0] GPIO_BASE    = 32'h0001_0120;

    localparam logic [31:0] DISPLAY_BASE = 32'h0001_0130;
    localparam logic [31:0] LED_BASE     = 32'h0001_0138;
    localparam logic [31:0] BUZZER_BASE  = 32'h0001_0140;

    localparam logic [31:0] VGA_BASE     = 32'h0001_1000;
    localparam logic [31:0] VGA_END      = 32'h0001_1800;


    // ============================================================
    // RAM
    // ============================================================

    localparam logic [31:0] RAM_BASE     = 32'h0000_2000;

    localparam logic [31:0] LOCAL_BOARD  = 32'h0000_2000;
    localparam logic [31:0] REMOTE_BOARD = 32'h0000_2100;

    localparam logic [31:0] P1_WINS      = 32'h0000_2F00;
    localparam logic [31:0] P2_WINS      = 32'h0000_2F04;


    localparam integer LOCAL_BASE_IDX =
        (LOCAL_BOARD - RAM_BASE) >> 2;

    localparam integer REMOTE_BASE_IDX =
        (REMOTE_BOARD - RAM_BASE) >> 2;

    localparam integer P1_WINS_IDX =
        (P1_WINS - RAM_BASE) >> 2;

    localparam integer P2_WINS_IDX =
        (P2_WINS - RAM_BASE) >> 2;


    // ============================================================
    // PROTOCOLO UART
    // ============================================================

    localparam logic [7:0] STX = 8'h02;
    localparam logic [7:0] ETX = 8'h03;

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
    // DUT
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
    // CLOCK
    // ============================================================

    always #5 clk100mhz = ~clk100mhz;


    // ============================================================
    // ESTADO GENERAL DE DEBUG
    // ============================================================

    string tb_stage = "BOOT";

    integer protocol_error_count = 0;

    integer mmio_write_count = 0;
    integer ram_write_count = 0;
    integer vga_write_count = 0;
    integer uart_tx_write_count = 0;
    integer display_write_count = 0;
    integer led_write_count = 0;
    integer buzzer_write_count = 0;

    logic [31:0] last_mmio_addr = 32'h0;
    logic [31:0] last_mmio_data = 32'h0;

    logic [31:0] last_vga_addr = 32'h0;
    logic [31:0] last_vga_data = 32'h0;

    logic [31:0] last_display_data = 32'h0;
    logic [31:0] last_led_data = 32'h0;

    logic [2:0] last_buzzer_code = 3'd0;


    // ============================================================
    // COBERTURA DE BUZZER
    // ============================================================

    integer count_buzzer_hit     = 0;
    integer count_buzzer_miss    = 0;
    integer count_buzzer_sunk    = 0;
    integer count_buzzer_invalid = 0;
    integer count_buzzer_victory = 0;


    // ============================================================
    // COBERTURA LED
    // ============================================================

    logic seen_led_placement = 1'b0;
    logic seen_led_battle    = 1'b0;
    logic seen_led_gameover  = 1'b0;


    // ============================================================
    // FLAGS DE REGRESION
    // ============================================================

    logic flag_local_invalid_pass       = 1'b0;
    logic flag_remote_invalid_pass      = 1'b0;
    logic flag_vga_secrecy_pass        = 1'b0;
    logic flag_repeat_j1_pass           = 1'b0;
    logic flag_repeat_j2_pass           = 1'b0;

    logic flag_j1_victory_pass          = 1'b0;
    logic flag_j2_victory_pass          = 1'b0;

    logic flag_sunk_j1_pass             = 1'b0;
    logic flag_sunk_j2_pass             = 1'b0;

    logic flag_score_persistence_pass   = 1'b0;
    logic flag_score_saturation_pass    = 1'b0;

    logic flag_vga_hit_miss_pass        = 1'b0;
    logic flag_buzzer_coverage_pass     = 1'b0;
    logic flag_led_coverage_pass        = 1'b0;

    logic flag_concurrent_placement_pass = 1'b0;
    logic flag_target_cursor_pass         = 1'b0;
    logic flag_remote_order_pass          = 1'b0;


    // ============================================================
    // MONITOR MMIO
    // ============================================================

    always @(posedge clk100mhz) begin

        if (dut.data_write_enable === 1'b1) begin

            mmio_write_count = mmio_write_count + 1;

            last_mmio_addr = dut.data_address;
            last_mmio_data = dut.data_write;


            // ----------------------------------------------------
            // RAM
            // ----------------------------------------------------

            if (
                dut.data_address >= 32'h0000_2000 &&
                dut.data_address <  32'h0000_3000
            ) begin

                ram_write_count = ram_write_count + 1;

                if (TRACE_RAM_WRITES) begin

                    $display(
                        "[%0t] RAM WRITE addr=%08h data=%08h f3=%0d PC=%08h",
                        $time,
                        dut.data_address,
                        dut.data_write,
                        dut.data_funct3,
                        dut.prog_address
                    );

                end

            end


            // ----------------------------------------------------
            // VGA
            // ----------------------------------------------------

            if (
                dut.data_address >= VGA_BASE &&
                dut.data_address < VGA_END
            ) begin

                vga_write_count = vga_write_count + 1;

                last_vga_addr = dut.data_address;
                last_vga_data = dut.data_write;

                if (TRACE_VGA) begin

                    $display(
                        "[%0t] VGA WRITE addr=%08h data=%08h PC=%08h",
                        $time,
                        dut.data_address,
                        dut.data_write,
                        dut.prog_address
                    );

                end

            end


            // ----------------------------------------------------
            // LED
            // ----------------------------------------------------

            if (dut.data_address === LED_BASE) begin

                led_write_count = led_write_count + 1;

                last_led_data = dut.data_write;

                case (dut.data_write[1:0])

                    2'd0:
                        seen_led_placement = 1'b1;

                    2'd1:
                        seen_led_battle = 1'b1;

                    2'd2:
                        seen_led_gameover = 1'b1;

                    default:
                        ;

                endcase


                if (TRACE_LED) begin

                    $display(
                        "[%0t] LED EVENT code=%0d led=%04h PC=%08h",
                        $time,
                        dut.data_write[1:0],
                        led,
                        dut.prog_address
                    );

                end

            end


            // ----------------------------------------------------
            // DISPLAY
            // ----------------------------------------------------

            if (dut.data_address === DISPLAY_BASE) begin

                display_write_count =
                    display_write_count + 1;

                last_display_data =
                    dut.data_write;

                if (TRACE_DISPLAY) begin

                    $display(
                        "[%0t] DISPLAY WRITE=%08h PC=%08h",
                        $time,
                        dut.data_write,
                        dut.prog_address
                    );

                end

            end


            // ----------------------------------------------------
            // BUZZER
            // ----------------------------------------------------

            if (dut.data_address === BUZZER_BASE) begin

                buzzer_write_count =
                    buzzer_write_count + 1;

                last_buzzer_code =
                    dut.data_write[2:0];


                case (dut.data_write[2:0])

                    3'd1:
                        count_buzzer_hit =
                            count_buzzer_hit + 1;

                    3'd2:
                        count_buzzer_miss =
                            count_buzzer_miss + 1;

                    3'd3:
                        count_buzzer_sunk =
                            count_buzzer_sunk + 1;

                    3'd4:
                        count_buzzer_invalid =
                            count_buzzer_invalid + 1;

                    3'd5:
                        count_buzzer_victory =
                            count_buzzer_victory + 1;

                    default:
                        ;

                endcase


                if (TRACE_BUZZER) begin

                    $display(
                        "[%0t] BUZZER EVENT code=%0d PC=%08h",
                        $time,
                        dut.data_write[2:0],
                        dut.prog_address
                    );

                end

            end

        end

    end


    // ============================================================
    // MONITOR UART FPGA -> PC
    // ============================================================

    integer tx_state = 0;

    integer tx_len = 0;
    integer tx_payload_idx = 0;

    logic [7:0] tx_cmd = 8'h00;
    logic [7:0] tx_checksum = 8'h00;
    logic [7:0] tx_byte;

    logic [7:0] tx_payload [0:31];


    integer count_place_start  = 0;
    integer count_place_ok     = 0;
    integer count_place_bad    = 0;
    integer count_battle_start = 0;
    integer count_turn         = 0;
    integer count_shot_result  = 0;
    integer count_incoming     = 0;
    integer count_game_over    = 0;

    integer count_incoming_sunk = 0;
    integer count_shot_result_sunk = 0;


    // Ultimos payloads recibidos

    logic [7:0] last_place_ok_id = 8'h00;

    logic [7:0] last_place_bad_id = 8'h00;
    logic [7:0] last_place_bad_reason = 8'h00;

    logic [7:0] last_turn_player = 8'h00;

    logic [7:0] last_incoming_row = 8'h00;
    logic [7:0] last_incoming_col = 8'h00;
    logic [7:0] last_incoming_result = 8'h00;

    logic [7:0] last_shot_row = 8'h00;
    logic [7:0] last_shot_col = 8'h00;
    logic [7:0] last_shot_result = 8'h00;

    logic [7:0] last_game_over_winner = 8'h00;
    logic [15:0] last_game_over_shots = 16'h0000;
    logic [7:0] last_game_over_sunk_j1 = 8'h00;
    logic [7:0] last_game_over_sunk_j2 = 8'h00;


    // Historial util para debug

    logic [7:0] incoming_result_history [0:63];
    logic [7:0] shot_result_history [0:63];

    logic [7:0] place_bad_id_history [0:31];
    logic [7:0] place_bad_reason_history [0:31];


    always @(posedge clk100mhz) begin

        if (
            dut.data_write_enable === 1'b1 &&
            dut.data_address === UART_TX
        ) begin

            uart_tx_write_count =
                uart_tx_write_count + 1;

            tx_byte =
                dut.data_write[7:0];


            case (tx_state)

                // ------------------------------------------------
                // STX
                // ------------------------------------------------

                0: begin

                    if (tx_byte == STX)
                        tx_state = 1;

                end


                // ------------------------------------------------
                // CMD
                // ------------------------------------------------

                1: begin

                    tx_cmd =
                        tx_byte;

                    tx_checksum =
                        tx_byte;

                    tx_state =
                        2;

                end


                // ------------------------------------------------
                // LEN
                // ------------------------------------------------

                2: begin

                    tx_len =
                        tx_byte;

                    tx_payload_idx =
                        0;

                    tx_checksum =
                        tx_checksum ^ tx_byte;


                    if (tx_byte > 32) begin

                        protocol_error_count =
                            protocol_error_count + 1;

                        $error(
                            "UART TX LEN demasiado grande: %0d",
                            tx_byte
                        );

                    end


                    if (tx_byte == 0)
                        tx_state = 4;
                    else
                        tx_state = 3;

                end


                // ------------------------------------------------
                // PAYLOAD
                // ------------------------------------------------

                3: begin

                    if (tx_payload_idx < 32)
                        tx_payload[tx_payload_idx] =
                            tx_byte;


                    tx_checksum =
                        tx_checksum ^ tx_byte;


                    tx_payload_idx =
                        tx_payload_idx + 1;


                    if (
                        tx_payload_idx >= tx_len
                    )
                        tx_state = 4;

                end


                // ------------------------------------------------
                // CHECKSUM
                // ------------------------------------------------

                4: begin

                    if (
                        tx_byte !== tx_checksum
                    ) begin

                        protocol_error_count =
                            protocol_error_count + 1;

                        $error(
                            "UART checksum incorrecto CMD=%02h esperado=%02h recibido=%02h",
                            tx_cmd,
                            tx_checksum,
                            tx_byte
                        );

                    end


                    tx_state = 5;

                end


                // ------------------------------------------------
                // ETX + DECODIFICACION
                // ------------------------------------------------

                5: begin

                    if (tx_byte !== ETX) begin

                        protocol_error_count =
                            protocol_error_count + 1;

                        $error(
                            "UART ETX incorrecto CMD=%02h recibido=%02h",
                            tx_cmd,
                            tx_byte
                        );

                    end
                    else begin

                        if (TRACE_UART_FRAMES) begin

                            $display(
                                "[%0t] UART FPGA->PC CMD=%02h LEN=%0d PC=%08h",
                                $time,
                                tx_cmd,
                                tx_len,
                                dut.prog_address
                            );

                        end


                        case (tx_cmd)

                            // ====================================
                            // 80
                            // ====================================

                            EVT_PLACE_START: begin

                                if (tx_len != 0) begin
                                    protocol_error_count =
                                        protocol_error_count + 1;

                                    $error(
                                        "CMD80 LEN incorrecto=%0d",
                                        tx_len
                                    );
                                end

                                count_place_start =
                                    count_place_start + 1;

                            end


                            // ====================================
                            // 81
                            // ====================================

                            EVT_PLACE_OK: begin

                                if (tx_len != 1) begin
                                    protocol_error_count =
                                        protocol_error_count + 1;

                                    $error(
                                        "CMD81 LEN incorrecto=%0d",
                                        tx_len
                                    );
                                end

                                last_place_ok_id =
                                    tx_payload[0];

                                count_place_ok =
                                    count_place_ok + 1;

                            end


                            // ====================================
                            // 82
                            // ====================================

                            EVT_PLACE_BAD: begin

                                if (tx_len != 2) begin
                                    protocol_error_count =
                                        protocol_error_count + 1;

                                    $error(
                                        "CMD82 LEN incorrecto=%0d",
                                        tx_len
                                    );
                                end


                                last_place_bad_id =
                                    tx_payload[0];

                                last_place_bad_reason =
                                    tx_payload[1];


                                if (count_place_bad < 32) begin

                                    place_bad_id_history[
                                        count_place_bad
                                    ] =
                                        tx_payload[0];

                                    place_bad_reason_history[
                                        count_place_bad
                                    ] =
                                        tx_payload[1];

                                end


                                count_place_bad =
                                    count_place_bad + 1;

                            end


                            // ====================================
                            // 83
                            // ====================================

                            EVT_BATTLE_START: begin

                                if (tx_len != 0) begin
                                    protocol_error_count =
                                        protocol_error_count + 1;

                                    $error(
                                        "CMD83 LEN incorrecto=%0d",
                                        tx_len
                                    );
                                end


                                count_battle_start =
                                    count_battle_start + 1;

                            end


                            // ====================================
                            // 84
                            // ====================================

                            EVT_TURN: begin

                                if (tx_len != 1) begin
                                    protocol_error_count =
                                        protocol_error_count + 1;

                                    $error(
                                        "CMD84 LEN incorrecto=%0d",
                                        tx_len
                                    );
                                end


                                last_turn_player =
                                    tx_payload[0];

                                count_turn =
                                    count_turn + 1;

                            end


                            // ====================================
                            // 85
                            // ====================================

                            EVT_SHOT_RESULT: begin

                                if (tx_len != 3) begin
                                    protocol_error_count =
                                        protocol_error_count + 1;

                                    $error(
                                        "CMD85 LEN incorrecto=%0d",
                                        tx_len
                                    );
                                end


                                last_shot_row =
                                    tx_payload[0];

                                last_shot_col =
                                    tx_payload[1];

                                last_shot_result =
                                    tx_payload[2];


                                if (count_shot_result < 64)
                                    shot_result_history[
                                        count_shot_result
                                    ] =
                                        tx_payload[2];


                                if (tx_payload[2] == 8'd2)
                                    count_shot_result_sunk =
                                        count_shot_result_sunk + 1;


                                count_shot_result =
                                    count_shot_result + 1;

                            end


                            // ====================================
                            // 86
                            // ====================================

                            EVT_INCOMING: begin

                                if (tx_len != 3) begin
                                    protocol_error_count =
                                        protocol_error_count + 1;

                                    $error(
                                        "CMD86 LEN incorrecto=%0d",
                                        tx_len
                                    );
                                end


                                last_incoming_row =
                                    tx_payload[0];

                                last_incoming_col =
                                    tx_payload[1];

                                last_incoming_result =
                                    tx_payload[2];


                                if (count_incoming < 64)
                                    incoming_result_history[
                                        count_incoming
                                    ] =
                                        tx_payload[2];


                                if (tx_payload[2] == 8'd2)
                                    count_incoming_sunk =
                                        count_incoming_sunk + 1;


                                count_incoming =
                                    count_incoming + 1;

                            end


                            // ====================================
                            // 87
                            // ====================================

                            EVT_GAME_OVER: begin

                                if (tx_len != 5) begin
                                    protocol_error_count =
                                        protocol_error_count + 1;

                                    $error(
                                        "CMD87 LEN incorrecto=%0d",
                                        tx_len
                                    );
                                end


                                last_game_over_winner =
                                    tx_payload[0];

                                last_game_over_shots =
                                    {
                                        tx_payload[1],
                                        tx_payload[2]
                                    };

                                last_game_over_sunk_j1 =
                                    tx_payload[3];

                                last_game_over_sunk_j2 =
                                    tx_payload[4];


                                count_game_over =
                                    count_game_over + 1;

                            end


                            default: begin

                                protocol_error_count =
                                    protocol_error_count + 1;

                                $error(
                                    "Evento UART desconocido CMD=%02h",
                                    tx_cmd
                                );

                            end

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
    // FUNCION: CONTADOR DE EVENTO
    // ============================================================

    function automatic integer get_event_count(
        input logic [7:0] cmd
    );

        begin

            case (cmd)

                EVT_PLACE_START:
                    get_event_count = count_place_start;

                EVT_PLACE_OK:
                    get_event_count = count_place_ok;

                EVT_PLACE_BAD:
                    get_event_count = count_place_bad;

                EVT_BATTLE_START:
                    get_event_count = count_battle_start;

                EVT_TURN:
                    get_event_count = count_turn;

                EVT_SHOT_RESULT:
                    get_event_count = count_shot_result;

                EVT_INCOMING:
                    get_event_count = count_incoming;

                EVT_GAME_OVER:
                    get_event_count = count_game_over;

                default:
                    get_event_count = -1;

            endcase

        end

    endfunction


    // ============================================================
    // VGA INDEX
    // ============================================================

    function automatic integer local_vga_index(
        input integer row,
        input integer col
    );

        begin

            local_vga_index =
                ((row + 2) * 20) +
                (col + 1);

        end

    endfunction


    function automatic integer remote_vga_index(
        input integer row,
        input integer col
    );

        begin

            remote_vga_index =
                ((row + 2) * 20) +
                (col + 11);

        end

    endfunction


    // ============================================================
    // DEBUG DUMP
    // ============================================================

    task automatic dump_boards;

        integer r;
        integer c;
        integer idx;

        begin

            $display("");
            $display("========== LOCAL BOARD ==========");

            for (r = 0; r < 8; r = r + 1) begin

                $write("R%0d: ", r);

                for (c = 0; c < 8; c = c + 1) begin

                    idx =
                        LOCAL_BASE_IDX +
                        r * 8 +
                        c;

                    $write(
                        "%0d ",
                        dut.u_data_ram.mem[idx]
                    );

                end

                $write("\n");

            end


            $display("");
            $display("========== REMOTE BOARD ==========");

            for (r = 0; r < 8; r = r + 1) begin

                $write("R%0d: ", r);

                for (c = 0; c < 8; c = c + 1) begin

                    idx =
                        REMOTE_BASE_IDX +
                        r * 8 +
                        c;

                    $write(
                        "%0d ",
                        dut.u_data_ram.mem[idx]
                    );

                end

                $write("\n");

            end

            $display("");

        end

    endtask


    task automatic dump_debug_state;

        begin

            $display("");
            $display("============================================================");
            $display(" DEBUG STATE");
            $display("============================================================");

            $display("Stage               : %s", tb_stage);
            $display("Time                : %0t", $time);

            $display("PC                  : %08h", dut.prog_address);
            $display("Instruction         : %08h", dut.prog_instr);

            $display("DataAddress         : %08h", dut.data_address);
            $display("DataWrite           : %08h", dut.data_write);
            $display("DataRead            : %08h", dut.data_read);
            $display("DataFunct3          : %0d", dut.data_funct3);
            $display("DataWriteEnable     : %b", dut.data_write_enable);

            $display("clock_locked        : %b", dut.clock_locked);
            $display("system_reset        : %b", dut.system_reset);

            $display("LED                 : %04h", led);
            $display("Display register    : %08h", dut.u_display.datos_reg);
            $display("Last buzzer code    : %0d", last_buzzer_code);

            $display("P1_WINS             : %0d",
                dut.u_data_ram.mem[P1_WINS_IDX]);

            $display("P2_WINS             : %0d",
                dut.u_data_ram.mem[P2_WINS_IDX]);

            $display("");
            $display("UART counts:");
            $display("  80 PLACE_START    : %0d", count_place_start);
            $display("  81 PLACE_OK       : %0d", count_place_ok);
            $display("  82 PLACE_BAD      : %0d", count_place_bad);
            $display("  83 BATTLE_START   : %0d", count_battle_start);
            $display("  84 TURN           : %0d", count_turn);
            $display("  85 SHOT_RESULT    : %0d", count_shot_result);
            $display("  86 INCOMING       : %0d", count_incoming);
            $display("  87 GAME_OVER      : %0d", count_game_over);

            $display("");
            $display("Last CMD85:");
            $display(
                "  row=%0d col=%0d result=%0d",
                last_shot_row,
                last_shot_col,
                last_shot_result
            );

            $display("Last CMD86:");
            $display(
                "  row=%0d col=%0d result=%0d",
                last_incoming_row,
                last_incoming_col,
                last_incoming_result
            );

            $display("Last GAME_OVER:");
            $display(
                "  winner=%0d shots=%0d sunkJ1=%0d sunkJ2=%0d",
                last_game_over_winner,
                last_game_over_shots,
                last_game_over_sunk_j1,
                last_game_over_sunk_j2
            );

            $display("");
            $display("MMIO:");
            $display("  total writes      : %0d", mmio_write_count);
            $display("  RAM writes        : %0d", ram_write_count);
            $display("  VGA writes        : %0d", vga_write_count);
            $display("  UART TX writes    : %0d", uart_tx_write_count);
            $display("  Display writes    : %0d", display_write_count);
            $display("  LED writes        : %0d", led_write_count);
            $display("  Buzzer writes     : %0d", buzzer_write_count);
            $display("  Last MMIO addr    : %08h", last_mmio_addr);
            $display("  Last MMIO data    : %08h", last_mmio_data);

            $display("");
            $display("Buzzer coverage:");
            $display("  hit               : %0d", count_buzzer_hit);
            $display("  miss              : %0d", count_buzzer_miss);
            $display("  sunk              : %0d", count_buzzer_sunk);
            $display("  invalid           : %0d", count_buzzer_invalid);
            $display("  victory           : %0d", count_buzzer_victory);

            $display("");
            $display("Protocol errors     : %0d", protocol_error_count);

            $display("============================================================");
            $display("");

        end

    endtask


    task automatic tb_fatal(
        input string message
    );

        begin

            $display("");
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("TEST FAILURE: %s", message);
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

            dump_debug_state();
            dump_boards();

            $fatal(1, "%s", message);

        end

    endtask


    // ============================================================
    // ASSERT HELPERS
    // ============================================================

    task automatic expect_int(
        input string name,
        input integer actual,
        input integer expected
    );

        begin

            if (actual != expected) begin

                $display(
                    "EXPECT FAIL %s expected=%0d actual=%0d",
                    name,
                    expected,
                    actual
                );

                tb_fatal(name);

            end

        end

    endtask


    task automatic expect8(
        input string name,
        input logic [7:0] actual,
        input logic [7:0] expected
    );

        begin

            if (actual !== expected) begin

                $display(
                    "EXPECT FAIL %s expected=%02h actual=%02h",
                    name,
                    expected,
                    actual
                );

                tb_fatal(name);

            end

        end

    endtask


    task automatic expect16(
        input string name,
        input logic [15:0] actual,
        input logic [15:0] expected
    );

        begin

            if (actual !== expected) begin

                $display(
                    "EXPECT FAIL %s expected=%04h actual=%04h",
                    name,
                    expected,
                    actual
                );

                tb_fatal(name);

            end

        end

    endtask


    task automatic expect32(
        input string name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );

        begin

            if (actual !== expected) begin

                $display(
                    "EXPECT FAIL %s expected=%08h actual=%08h",
                    name,
                    expected,
                    actual
                );

                tb_fatal(name);

            end

        end

    endtask


    // ============================================================
    // ESPERAR EVENTO
    // ============================================================

    task automatic wait_event_count(
        input logic [7:0] event_cmd,
        input integer target
    );

        integer n;

        begin

            n = 0;

            while (
                get_event_count(event_cmd) < target
            ) begin

                @(posedge clk100mhz);

                n = n + 1;

                if (n >= WAIT_CYCLES) begin

                    $display(
                        "Timeout CMD=%02h target=%0d actual=%0d",
                        event_cmd,
                        target,
                        get_event_count(event_cmd)
                    );

                    tb_fatal(
                        "Timeout esperando evento UART"
                    );

                end

            end

        end

    endtask


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

                    tb_fatal(
                        "Timeout esperando polling UART"
                    );

                end

            end

        end

    endtask


    // ============================================================
    // ESPERAR DISPLAY
    // ============================================================

    task automatic wait_display(
        input logic [31:0] expected
    );

        integer n;

        begin

            n = 0;

            while (
                dut.u_display.datos_reg !== expected
            ) begin

                @(posedge clk100mhz);

                n = n + 1;

                if (n >= WAIT_CYCLES) begin

                    $display(
                        "Display esperado=%08h actual=%08h",
                        expected,
                        dut.u_display.datos_reg
                    );

                    tb_fatal(
                        "Timeout esperando display"
                    );

                end

            end

        end

    endtask


    // ============================================================
    // ESPERAR BUZZER CODE
    // ============================================================

    task automatic wait_buzzer_invalid(
        input integer target
    );

        integer n;

        begin

            n = 0;

            while (
                count_buzzer_invalid < target
            ) begin

                @(posedge clk100mhz);

                n = n + 1;

                if (n >= WAIT_CYCLES)
                    tb_fatal(
                        "Timeout esperando buzzer INVALID"
                    );

            end

        end

    endtask


    // ============================================================
    // RESET
    // ============================================================

    task automatic reset_to_placement;

        integer target;

        begin

            target =
                count_place_start + 1;


            uart_rx = 1'b1;


            @(negedge clk100mhz);

            btnC = 1'b1;


            repeat (40)
                @(posedge clk100mhz);


            @(negedge clk100mhz);

            btnC = 1'b0;


            wait_event_count(
                EVT_PLACE_START,
                target
            );


            if (led !== 16'h0001) begin

                $display(
                    "LED placement esperado=0001 actual=%04h",
                    led
                );

                tb_fatal(
                    "LED incorrecto en placement"
                );

            end

        end

    endtask


    // ============================================================
    // GPIO
    // ============================================================

    task press_gpio(
        input logic [6:0] mask
    );

        integer n;

        begin

            if (TRACE_GPIO) begin

                $display(
                    "[%0t] TB GPIO PRESS mask=%02h PC=%08h stage=%s",
                    $time,
                    mask,
                    dut.prog_address,
                    tb_stage
                );

            end


            @(negedge clk100mhz);

            force dut.u_gpio.btns_debounced =
                mask;


            n = 0;

            do begin

                @(posedge clk100mhz);

                n = n + 1;

                if (n >= WAIT_CYCLES) begin

                    release dut.u_gpio.btns_debounced;

                    tb_fatal(
                        "Timeout CPU leyendo GPIO"
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


            if (TRACE_GPIO) begin

                $display(
                    "[%0t] TB GPIO CPU detecto=%02h PC=%08h",
                    $time,
                    dut.data_read[6:0],
                    dut.prog_address
                );

            end


            repeat (4)
                @(posedge clk100mhz);


            @(negedge clk100mhz);

            force dut.u_gpio.btns_debounced =
                7'b0000000;


            n = 0;

            do begin

                @(posedge clk100mhz);

                n = n + 1;

                if (n >= WAIT_CYCLES) begin

                    release dut.u_gpio.btns_debounced;

                    tb_fatal(
                        "Timeout liberando GPIO"
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


            if (TRACE_GPIO) begin

                $display(
                    "[%0t] TB GPIO RELEASE mask=%02h",
                    $time,
                    mask
                );

            end

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

            uart_rx = 1'b0;

            #(UART_BIT_NS);


            for (
                i = 0;
                i < 8;
                i = i + 1
            ) begin

                uart_rx = data[i];

                #(UART_BIT_NS);

            end


            uart_rx = 1'b1;

            #(UART_BIT_NS);

        end

    endtask


    // ============================================================
    // PLACE SIN ESPERAR POLLING
    //
    // Util para prueba futura de colocacion concurrente.
    // ============================================================

    task automatic send_place_nowait(
        input logic [7:0] ship_id,
        input logic [7:0] row,
        input logic [7:0] col,
        input logic [7:0] orientation
    );

        logic [7:0] chk;

        begin

            chk =
                CMD_PLACE ^
                8'd4 ^
                ship_id ^
                row ^
                col ^
                orientation;


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


    task automatic send_place(
        input logic [7:0] ship_id,
        input logic [7:0] row,
        input logic [7:0] col,
        input logic [7:0] orientation
    );

        begin

            wait_uart_poll();


            $display(
                "[%0t] PC->FPGA PLACE id=%0d row=%0d col=%0d ori=%0d",
                $time,
                ship_id,
                row,
                col,
                orientation
            );


            send_place_nowait(
                ship_id,
                row,
                col,
                orientation
            );

        end

    endtask


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
    // LOCAL PLACEMENT
    // ============================================================

    task automatic local_place_ship(
        input integer row,
        input integer col,
        input logic vertical
    );

        integer i;

        begin

            for (i = 0; i < row; i = i + 1)
                press_gpio(BTN_DOWN);


            for (i = 0; i < col; i = i + 1)
                press_gpio(BTN_RIGHT);


            if (vertical)
                press_gpio(BTN_SELECT);


            press_gpio(BTN_OK);

        end

    endtask


    // ============================================================
    // LOCAL FIRE
    // ============================================================

    task automatic local_fire(
        input integer row,
        input integer col
    );

        integer i;

        begin

            for (i = 0; i < row; i = i + 1)
                press_gpio(BTN_DOWN);


            for (i = 0; i < col; i = i + 1)
                press_gpio(BTN_RIGHT);


            press_gpio(BTN_OK);

        end

    endtask


    // ============================================================
    // RAM EXPECT
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

                $display(
                    "CELL FAIL base=%0d row=%0d col=%0d expected=%08h actual=%08h",
                    base_idx,
                    row,
                    col,
                    expected,
                    dut.u_data_ram.mem[idx]
                );

                tb_fatal(
                    "Contenido de tablero incorrecto"
                );

            end

        end

    endtask


    // ============================================================
    // VGA EXPECT
    // ============================================================

    task automatic expect_vga_local(
        input integer row,
        input integer col,
        input logic [31:0] expected
    );

        integer idx;

        begin

            idx =
                local_vga_index(
                    row,
                    col
                );


            if (
                dut.u_vga.u_vram.vram[idx] !== expected
            ) begin

                $display(
                    "VGA LOCAL FAIL row=%0d col=%0d idx=%0d expected=%0d actual=%0d",
                    row,
                    col,
                    idx,
                    expected,
                    dut.u_vga.u_vram.vram[idx]
                );

                tb_fatal(
                    "VGA local incorrecto"
                );

            end

        end

    endtask


    task automatic expect_vga_remote(
        input integer row,
        input integer col,
        input logic [31:0] expected
    );

        integer idx;

        begin

            idx =
                remote_vga_index(
                    row,
                    col
                );


            if (
                dut.u_vga.u_vram.vram[idx] !== expected
            ) begin

                $display(
                    "VGA REMOTE FAIL row=%0d col=%0d idx=%0d expected=%0d actual=%0d",
                    row,
                    col,
                    idx,
                    expected,
                    dut.u_vga.u_vram.vram[idx]
                );

                tb_fatal(
                    "VGA remoto incorrecto"
                );

            end

        end

    endtask


    // ============================================================
    // WAIT VGA REMOTE
    // ============================================================

    task automatic wait_vga_remote(
        input integer row,
        input integer col,
        input logic [31:0] expected
    );

        integer idx;
        integer n;

        begin

            idx =
                remote_vga_index(
                    row,
                    col
                );

            n = 0;

            while (
                dut.u_vga.u_vram.vram[idx] !== expected
            ) begin

                @(posedge clk100mhz);

                n = n + 1;

                if (n >= WAIT_CYCLES) begin

                    $display(
                        "WAIT VGA REMOTE FAIL row=%0d col=%0d idx=%0d expected=%0d actual=%0d",
                        row,
                        col,
                        idx,
                        expected,
                        dut.u_vga.u_vram.vram[idx]
                    );

                    tb_fatal(
                        "Timeout esperando VGA remoto"
                    );

                end

            end

        end

    endtask


    // ============================================================
    // VERIFY FLEETS
    // ============================================================

    task automatic verify_initial_fleets;

        begin

            // ----------------------------------------------------
            // J1
            //
            // ship 0 -> 1
            // ship 1 -> 2
            // ship 2 -> 3
            // ----------------------------------------------------

            expect_cell(LOCAL_BASE_IDX, 0, 0, 32'd1);
            expect_cell(LOCAL_BASE_IDX, 0, 1, 32'd1);
            expect_cell(LOCAL_BASE_IDX, 0, 2, 32'd1);
            expect_cell(LOCAL_BASE_IDX, 0, 3, 32'd1);

            expect_cell(LOCAL_BASE_IDX, 1, 0, 32'd2);
            expect_cell(LOCAL_BASE_IDX, 1, 1, 32'd2);
            expect_cell(LOCAL_BASE_IDX, 1, 2, 32'd2);

            expect_cell(LOCAL_BASE_IDX, 2, 0, 32'd3);
            expect_cell(LOCAL_BASE_IDX, 2, 1, 32'd3);


            // ----------------------------------------------------
            // J2
            // ----------------------------------------------------

            expect_cell(REMOTE_BASE_IDX, 0, 4, 32'd1);
            expect_cell(REMOTE_BASE_IDX, 1, 4, 32'd1);
            expect_cell(REMOTE_BASE_IDX, 2, 4, 32'd1);
            expect_cell(REMOTE_BASE_IDX, 3, 4, 32'd1);

            expect_cell(REMOTE_BASE_IDX, 4, 0, 32'd2);
            expect_cell(REMOTE_BASE_IDX, 4, 1, 32'd2);
            expect_cell(REMOTE_BASE_IDX, 4, 2, 32'd2);

            expect_cell(REMOTE_BASE_IDX, 6, 0, 32'd3);
            expect_cell(REMOTE_BASE_IDX, 6, 1, 32'd3);


            // Agua de referencia

            expect_cell(LOCAL_BASE_IDX, 7, 7, 32'd0);
            expect_cell(REMOTE_BASE_IDX, 7, 7, 32'd0);

        end

    endtask


    // ============================================================
    // LOCAL FLEET SETUP
    // ============================================================

    task automatic setup_local_fleet(
        input logic test_invalid_overlap
    );

        integer invalid_before;
        integer bad_before;

        begin

            // Ship 0
            local_place_ship(
                0,
                0,
                1'b0
            );


            if (test_invalid_overlap) begin

                invalid_before =
                    count_buzzer_invalid;

                bad_before =
                    count_place_bad;


                // Intentar colocar ship 1 encima del ship 0
                local_place_ship(
                    0,
                    0,
                    1'b0
                );


                wait_buzzer_invalid(
                    invalid_before + 1
                );


                expect_int(
                    "Local invalid no debe generar CMD82",
                    count_place_bad,
                    bad_before
                );


                flag_local_invalid_pass =
                    1'b1;


                // El cursor sigue en 0,0.
                // Mover ship 1 a row=1.
                local_place_ship(
                    1,
                    0,
                    1'b0
                );

            end
            else begin

                local_place_ship(
                    1,
                    0,
                    1'b0
                );

            end


            // Ship 2
            local_place_ship(
                2,
                0,
                1'b0
            );


            wait_uart_poll();

        end

    endtask


    // ============================================================
    // REMOTE PLACEMENT EXPECT BAD
    // ============================================================

    task automatic remote_place_expect_bad(
        input logic [7:0] ship_id,
        input logic [7:0] row,
        input logic [7:0] col,
        input logic [7:0] orientation,
        input logic [7:0] expected_reason
    );

        integer bad_before;
        integer ok_before;

        begin

            bad_before =
                count_place_bad;

            ok_before =
                count_place_ok;


            send_place(
                ship_id,
                row,
                col,
                orientation
            );


            wait_event_count(
                EVT_PLACE_BAD,
                bad_before + 1
            );


            expect_int(
                "PLACE_BAD no debe incrementar PLACE_OK",
                count_place_ok,
                ok_before
            );


            expect8(
                "PLACE_BAD id",
                last_place_bad_id,
                ship_id
            );


            expect8(
                "PLACE_BAD reason",
                last_place_bad_reason,
                expected_reason
            );

        end

    endtask


    // ============================================================
    // REMOTE PLACEMENT EXPECT OK
    // ============================================================

    task automatic remote_place_expect_ok(
        input logic [7:0] ship_id,
        input logic [7:0] row,
        input logic [7:0] col,
        input logic [7:0] orientation
    );

        integer ok_before;

        begin

            ok_before =
                count_place_ok;


            send_place(
                ship_id,
                row,
                col,
                orientation
            );


            wait_event_count(
                EVT_PLACE_OK,
                ok_before + 1
            );


            expect8(
                "PLACE_OK id",
                last_place_ok_id,
                ship_id
            );

        end

    endtask


    // ============================================================
    // REMOTE FLEET SETUP
    // ============================================================

    task automatic setup_remote_fleet(
        input logic test_invalid
    );

        integer bad_before;
        integer battle_before;

        begin

            bad_before =
                count_place_bad;

            battle_before =
                count_battle_start;


            if (test_invalid) begin

                // -----------------------------------------------
                // ID valido, pero fuera de orden.
                //
                // La FPGA espera primero ship ID 0.
                // Intentamos enviar ship ID 1.
                // Debe responder PLACE_BAD reason=1 y no
                // modificar el tablero remoto.
                // -----------------------------------------------

                remote_place_expect_bad(
                    8'd1,
                    8'd4,
                    8'd0,
                    8'd0,
                    8'd1
                );


                expect_cell(
                    REMOTE_BASE_IDX,
                    4,
                    0,
                    32'd0
                );


                flag_remote_order_pass =
                    1'b1;


                $display(
                    "PASS: strict remote fleet order"
                );


                // -----------------------------------------------
                // Fuera del tablero
                // validate_place=2 -> protocolo reason=1
                // -----------------------------------------------

                remote_place_expect_bad(
                    8'd0,
                    8'd6,
                    8'd4,
                    8'd1,
                    8'd1
                );


                // -----------------------------------------------
                // ID invalido
                // -----------------------------------------------

                remote_place_expect_bad(
                    8'd3,
                    8'd0,
                    8'd0,
                    8'd0,
                    8'd1
                );


                // -----------------------------------------------
                // Orientacion invalida
                // -----------------------------------------------

                remote_place_expect_bad(
                    8'd0,
                    8'd0,
                    8'd0,
                    8'd2,
                    8'd1
                );

            end


            // Ship 0 valido
            remote_place_expect_ok(
                8'd0,
                8'd0,
                8'd4,
                8'd1
            );


            if (test_invalid) begin

                // -----------------------------------------------
                // Traslape con ship 0
                // validate_place=1 -> protocolo reason=0
                // -----------------------------------------------

                remote_place_expect_bad(
                    8'd1,
                    8'd1,
                    8'd4,
                    8'd0,
                    8'd0
                );

            end


            // Ship 1
            remote_place_expect_ok(
                8'd1,
                8'd4,
                8'd0,
                8'd0
            );


            // Ship 2
            remote_place_expect_ok(
                8'd2,
                8'd6,
                8'd0,
                8'd0
            );


            wait_event_count(
                EVT_BATTLE_START,
                battle_before + 1
            );


            if (test_invalid) begin

                expect_int(
                    "Numero de PLACE_BAD",
                    count_place_bad - bad_before,
                    5
                );

                flag_remote_invalid_pass =
                    1'b1;

            end


            if (led !== 16'h0002) begin

                $display(
                    "LED battle esperado=0002 actual=%04h",
                    led
                );

                tb_fatal(
                    "LED incorrecto en batalla"
                );

            end

        end

    endtask


    // ============================================================
    // J1 FIRE EXPECT
    // ============================================================

    task automatic j1_fire_expect(
        input integer row,
        input integer col,
        input logic [7:0] expected_result,
        input logic expect_next_turn
    );

        integer incoming_before;
        integer turn_before;

        begin

            incoming_before =
                count_incoming;

            turn_before =
                count_turn;


            local_fire(
                row,
                col
            );


            wait_event_count(
                EVT_INCOMING,
                incoming_before + 1
            );


            expect8(
                "CMD86 row",
                last_incoming_row,
                row[7:0]
            );


            expect8(
                "CMD86 col",
                last_incoming_col,
                col[7:0]
            );


            expect8(
                "CMD86 result",
                last_incoming_result,
                expected_result
            );


            if (expect_next_turn) begin

                wait_event_count(
                    EVT_TURN,
                    turn_before + 1
                );


                expect8(
                    "Turno esperado J2",
                    last_turn_player,
                    8'd1
                );

            end

        end

    endtask


    // ============================================================
    // J2 FIRE EXPECT
    // ============================================================

    task automatic j2_fire_expect(
        input logic [7:0] row,
        input logic [7:0] col,
        input logic [7:0] expected_result,
        input logic expect_next_turn
    );

        integer shot_before;
        integer turn_before;

        begin

            shot_before =
                count_shot_result;

            turn_before =
                count_turn;


            send_fire(
                row,
                col
            );


            wait_event_count(
                EVT_SHOT_RESULT,
                shot_before + 1
            );


            expect8(
                "CMD85 row",
                last_shot_row,
                row
            );


            expect8(
                "CMD85 col",
                last_shot_col,
                col
            );


            expect8(
                "CMD85 result",
                last_shot_result,
                expected_result
            );


            if (expect_next_turn) begin

                wait_event_count(
                    EVT_TURN,
                    turn_before + 1
                );


                expect8(
                    "Turno esperado J1",
                    last_turn_player,
                    8'd0
                );

            end

        end

    endtask


    // ============================================================
    // REPEAT SHOT J1
    //
    // Se usa (0,0), por lo que el cursor permanece en origen.
    // ============================================================

    task automatic test_repeat_j1_origin;

        integer incoming_before;
        integer turn_before;
        integer game_before;

        begin

            tb_stage =
                "GAME1 REPEATED SHOT J1";


            incoming_before =
                count_incoming;

            turn_before =
                count_turn;

            game_before =
                count_game_over;


            local_fire(
                0,
                0
            );


            // Dar tiempo a resolve_shot para volver al input.
            repeat (200)
                @(posedge clk100mhz);


            expect_int(
                "Repeat J1 no CMD86",
                count_incoming,
                incoming_before
            );


            expect_int(
                "Repeat J1 no cambia turno",
                count_turn,
                turn_before
            );


            expect_int(
                "Repeat J1 no GAME_OVER",
                count_game_over,
                game_before
            );


            // La casilla sigue marcada como fallo.
            expect_cell(
                REMOTE_BASE_IDX,
                0,
                0,
                32'd4
            );


            flag_repeat_j1_pass =
                1'b1;

        end

    endtask


    // ============================================================
    // REPEAT SHOT J2
    // ============================================================

    task automatic test_repeat_j2(
        input logic [7:0] row,
        input logic [7:0] col
    );

        integer shot_before;
        integer turn_before;

        begin

            tb_stage =
                "GAME1 REPEATED SHOT J2";


            shot_before =
                count_shot_result;

            turn_before =
                count_turn;


            send_fire(
                row,
                col
            );


            // Esperar que el firmware descarte el disparo y
            // vuelva a quedarse esperando UART.
            wait_uart_poll();


            repeat (100)
                @(posedge clk100mhz);


            expect_int(
                "Repeat J2 no CMD85",
                count_shot_result,
                shot_before
            );


            expect_int(
                "Repeat J2 no cambia turno",
                count_turn,
                turn_before
            );


            flag_repeat_j2_pass =
                1'b1;

        end

    endtask


    // ============================================================
    // GAME OVER EXPECT
    // ============================================================

    task automatic expect_game_over(
        input integer game_over_target,
        input logic [7:0] winner,
        input logic [15:0] shots,
        input logic [7:0] sunk_j1,
        input logic [7:0] sunk_j2
    );

        begin

            wait_event_count(
                EVT_GAME_OVER,
                game_over_target
            );


            expect8(
                "GAME_OVER winner",
                last_game_over_winner,
                winner
            );


            expect16(
                "GAME_OVER shots",
                last_game_over_shots,
                shots
            );


            expect8(
                "GAME_OVER sunk J1",
                last_game_over_sunk_j1,
                sunk_j1
            );


            expect8(
                "GAME_OVER sunk J2",
                last_game_over_sunk_j2,
                sunk_j2
            );


            if (led !== 16'h0004) begin

                $display(
                    "LED gameover esperado=0004 actual=%04h",
                    led
                );

                tb_fatal(
                    "LED incorrecto en GAME_OVER"
                );

            end

        end

    endtask


    // ============================================================
    // GAME 1
    //
    // - invalid placements
    // - VGA secrecy
    // - repeat J1
    // - repeat J2
    // - J1 wins
    // ============================================================

    task automatic run_game1;

        integer place_ok_before;
        integer incoming_before;
        integer shot_before;
        integer turn_before;
        integer game_before;
        integer sunk_before;

        begin

            $display("");
            $display("============================================================");
            $display(" GAME 1 - J1 WIN + INVALID + REPEAT + VGA");
            $display("============================================================");


            tb_stage =
                "GAME1 RESET";


            reset_to_placement();


            wait_display(
                32'h0000_0000
            );


            expect32(
                "Inicial P1 score",
                dut.u_data_ram.mem[P1_WINS_IDX],
                32'd0
            );


            expect32(
                "Inicial P2 score",
                dut.u_data_ram.mem[P2_WINS_IDX],
                32'd0
            );


            // ----------------------------------------------------
            // LOCAL PLACEMENT + INVALID OVERLAP
            // ----------------------------------------------------

            tb_stage =
                "GAME1 LOCAL PLACEMENT";


            setup_local_fleet(
                1'b1
            );


            // ----------------------------------------------------
            // REMOTE PLACEMENT + INVALID TESTS
            // ----------------------------------------------------

            tb_stage =
                "GAME1 REMOTE PLACEMENT";


            place_ok_before =
                count_place_ok;


            setup_remote_fleet(
                1'b1
            );


            expect_int(
                "GAME1 accepted remote ships",
                count_place_ok - place_ok_before,
                3
            );


            verify_initial_fleets();


            // ----------------------------------------------------
            // VGA secrecy before shots
            // ----------------------------------------------------

            tb_stage =
                "GAME1 VGA SECRECY";


            // Local own ship is visible.
            expect_vga_local(
                0,
                0,
                32'd1
            );


            // Remote intact ships MUST be hidden.
            expect_vga_remote(
                0,
                4,
                32'd0
            );

            expect_vga_remote(
                1,
                4,
                32'd0
            );

            expect_vga_remote(
                4,
                0,
                32'd0
            );

            expect_vga_remote(
                6,
                0,
                32'd0
            );


            flag_vga_secrecy_pass =
                1'b1;


            // ----------------------------------------------------
            // INITIAL TURN
            // ----------------------------------------------------

            turn_before =
                count_turn;


            wait_event_count(
                EVT_TURN,
                turn_before + 1
            );


            expect8(
                "GAME1 initial turn",
                last_turn_player,
                8'd0
            );


            // ----------------------------------------------------
            // J1 TARGET CURSOR
            //
            // Al comenzar el turno de J1 el cursor debe aparecer
            // en la casilla remota (0,0). Luego se mueve a (0,1)
            // y regresa a (0,0) para no alterar las pruebas de
            // disparo existentes.
            // ----------------------------------------------------

            tb_stage =
                "GAME1 TARGET CURSOR";


            wait_vga_remote(
                0,
                0,
                32'd5
            );


            expect_vga_remote(
                0,
                0,
                32'd5
            );


            // RIGHT -> (0,1)

            press_gpio(
                BTN_RIGHT
            );


            wait_vga_remote(
                0,
                1,
                32'd5
            );


            expect_vga_remote(
                0,
                0,
                32'd0
            );


            expect_vga_remote(
                0,
                1,
                32'd5
            );


            // LEFT -> regresar a (0,0)

            press_gpio(
                BTN_LEFT
            );


            wait_vga_remote(
                0,
                0,
                32'd5
            );


            expect_vga_remote(
                0,
                0,
                32'd5
            );


            expect_vga_remote(
                0,
                1,
                32'd0
            );


            flag_target_cursor_pass =
                1'b1;


            $display(
                "PASS: J1 target cursor"
            );


            incoming_before =
                count_incoming;

            shot_before =
                count_shot_result;

            turn_before =
                count_turn;

            game_before =
                count_game_over;

            sunk_before =
                count_incoming_sunk;


            // ====================================================
            // J1 MISS (0,0)
            // ====================================================

            tb_stage =
                "GAME1 J1 FIRST MISS";


            j1_fire_expect(
                0,
                0,
                8'd0,
                1'b1
            );


            // render_boards ocurre antes del TURN.
            expect_vga_remote(
                0,
                0,
                32'd3
            );


            // Enemy ship remains hidden.
            expect_vga_remote(
                0,
                4,
                32'd0
            );


            // ====================================================
            // J2 MISS (7,0)
            // ====================================================

            tb_stage =
                "GAME1 J2 FIRST MISS";


            j2_fire_expect(
                8'd7,
                8'd0,
                8'd0,
                1'b1
            );


            expect_vga_local(
                7,
                0,
                32'd3
            );


            // ====================================================
            // REPEAT J1 (0,0)
            // ====================================================

            test_repeat_j1_origin();


            // ====================================================
            // J1 HIT ship0
            // ====================================================

            tb_stage =
                "GAME1 J1 HIT 1";


            j1_fire_expect(
                0,
                4,
                8'd1,
                1'b1
            );


            expect_vga_remote(
                0,
                4,
                32'd2
            );


            // Siguiente parte sigue oculta.
            expect_vga_remote(
                1,
                4,
                32'd0
            );


            flag_vga_hit_miss_pass =
                1'b1;


            // ====================================================
            // REPEAT J2 (7,0)
            // ====================================================

            test_repeat_j2(
                8'd7,
                8'd0
            );


            // J2 sigue teniendo el turno.
            j2_fire_expect(
                8'd7,
                8'd1,
                8'd0,
                1'b1
            );


            // ====================================================
            // RESTO SHIP 0
            // ====================================================

            tb_stage =
                "GAME1 SINK SHIP0";


            j1_fire_expect(1, 4, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd2, 8'd0, 1'b1);

            j1_fire_expect(2, 4, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd3, 8'd0, 1'b1);

            j1_fire_expect(3, 4, 8'd2, 1'b1);
            j2_fire_expect(8'd7, 8'd4, 8'd0, 1'b1);


            // ====================================================
            // SHIP 1
            // ====================================================

            tb_stage =
                "GAME1 SINK SHIP1";


            j1_fire_expect(4, 0, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd5, 8'd0, 1'b1);

            j1_fire_expect(4, 1, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd6, 8'd0, 1'b1);

            j1_fire_expect(4, 2, 8'd2, 1'b1);
            j2_fire_expect(8'd7, 8'd7, 8'd0, 1'b1);


            // ====================================================
            // SHIP 2
            // ====================================================

            tb_stage =
                "GAME1 SINK SHIP2";


            j1_fire_expect(6, 0, 8'd1, 1'b1);

            j2_fire_expect(
                8'd5,
                8'd7,
                8'd0,
                1'b1
            );


            // Ultimo tiro gana.
            j1_fire_expect(
                6,
                1,
                8'd2,
                1'b0
            );


            // ====================================================
            // GAME OVER
            //
            // Valid shots:
            //
            // J1: 10
            // J2:  9
            // Total: 19
            //
            // Los dos repetidos NO cuentan.
            // ====================================================

            tb_stage =
                "GAME1 GAME OVER";


            expect_game_over(
                game_before + 1,
                8'd0,
                16'd19,
                8'd3,
                8'd0
            );


            expect_int(
                "GAME1 CMD86 count",
                count_incoming - incoming_before,
                10
            );


            expect_int(
                "GAME1 CMD85 count",
                count_shot_result - shot_before,
                9
            );


            expect_int(
                "GAME1 TURN count",
                count_turn - turn_before,
                18
            );


            // turn_before fue tomado despues del initial turn.
            // 18 adicionales + initial = 19 por partida.


            expect_int(
                "GAME1 sunk events",
                count_incoming_sunk - sunk_before,
                3
            );


            // ----------------------------------------------------
            // Final RAM representation
            // ----------------------------------------------------

            expect_cell(REMOTE_BASE_IDX, 0, 4, 32'd5);
            expect_cell(REMOTE_BASE_IDX, 1, 4, 32'd5);
            expect_cell(REMOTE_BASE_IDX, 2, 4, 32'd5);
            expect_cell(REMOTE_BASE_IDX, 3, 4, 32'd5);

            expect_cell(REMOTE_BASE_IDX, 4, 0, 32'd6);
            expect_cell(REMOTE_BASE_IDX, 4, 1, 32'd6);
            expect_cell(REMOTE_BASE_IDX, 4, 2, 32'd6);

            expect_cell(REMOTE_BASE_IDX, 6, 0, 32'd7);
            expect_cell(REMOTE_BASE_IDX, 6, 1, 32'd7);


            // ----------------------------------------------------
            // Score
            // ----------------------------------------------------

            expect32(
                "GAME1 P1 score RAM",
                dut.u_data_ram.mem[P1_WINS_IDX],
                32'd1
            );


            expect32(
                "GAME1 P2 score RAM",
                dut.u_data_ram.mem[P2_WINS_IDX],
                32'd0
            );


            expect32(
                "GAME1 display",
                dut.u_display.datos_reg,
                32'h0000_0100
            );


            flag_j1_victory_pass =
                1'b1;

            flag_sunk_j1_pass =
                1'b1;


            $display("PASS: GAME 1");

        end

    endtask


    // ============================================================
    // GAME 2
    //
    // J2 wins
    // ============================================================

    task automatic run_game2;

        integer incoming_before;
        integer shot_before;
        integer turn_before;
        integer game_before;
        integer sunk_before;

        begin

            $display("");
            $display("============================================================");
            $display(" GAME 2 - J2 WIN");
            $display("============================================================");


            tb_stage =
                "GAME2 RESET";


            reset_to_placement();


            wait_display(
                32'h0000_0100
            );


            expect32(
                "Score persistence P1",
                dut.u_data_ram.mem[P1_WINS_IDX],
                32'd1
            );


            expect32(
                "Score persistence P2",
                dut.u_data_ram.mem[P2_WINS_IDX],
                32'd0
            );


            flag_score_persistence_pass =
                1'b1;


            // ----------------------------------------------------
            // FLEETS
            // ----------------------------------------------------

            tb_stage =
                "GAME2 LOCAL PLACEMENT";


            setup_local_fleet(
                1'b0
            );


            tb_stage =
                "GAME2 REMOTE PLACEMENT";


            setup_remote_fleet(
                1'b0
            );


            verify_initial_fleets();


            // Initial turn
            turn_before =
                count_turn;

            wait_event_count(
                EVT_TURN,
                turn_before + 1
            );


            expect8(
                "GAME2 initial turn",
                last_turn_player,
                8'd0
            );


            incoming_before =
                count_incoming;

            shot_before =
                count_shot_result;

            turn_before =
                count_turn;

            game_before =
                count_game_over;

            sunk_before =
                count_shot_result_sunk;


            // ====================================================
            // Round 1
            // ====================================================

            tb_stage = "GAME2 ROUND1";

            j1_fire_expect(0, 0, 8'd0, 1'b1);
            j2_fire_expect(8'd0, 8'd0, 8'd1, 1'b1);


            // ====================================================
            // Round 2
            // ====================================================

            tb_stage = "GAME2 ROUND2";

            j1_fire_expect(0, 1, 8'd0, 1'b1);
            j2_fire_expect(8'd0, 8'd1, 8'd1, 1'b1);


            // ====================================================
            // Round 3
            // ====================================================

            tb_stage = "GAME2 ROUND3";

            j1_fire_expect(0, 2, 8'd0, 1'b1);
            j2_fire_expect(8'd0, 8'd2, 8'd1, 1'b1);


            // ====================================================
            // Round 4 - sink ship0
            // ====================================================

            tb_stage = "GAME2 SINK SHIP0";

            j1_fire_expect(0, 3, 8'd0, 1'b1);
            j2_fire_expect(8'd0, 8'd3, 8'd2, 1'b1);


            // ====================================================
            // Round 5
            // ====================================================

            j1_fire_expect(0, 5, 8'd0, 1'b1);
            j2_fire_expect(8'd1, 8'd0, 8'd1, 1'b1);


            // ====================================================
            // Round 6
            // ====================================================

            j1_fire_expect(0, 6, 8'd0, 1'b1);
            j2_fire_expect(8'd1, 8'd1, 8'd1, 1'b1);


            // ====================================================
            // Round 7 - sink ship1
            // ====================================================

            tb_stage = "GAME2 SINK SHIP1";

            j1_fire_expect(0, 7, 8'd0, 1'b1);
            j2_fire_expect(8'd1, 8'd2, 8'd2, 1'b1);


            // ====================================================
            // Round 8
            // ====================================================

            j1_fire_expect(1, 0, 8'd0, 1'b1);
            j2_fire_expect(8'd2, 8'd0, 8'd1, 1'b1);


            // ====================================================
            // Round 9 - J2 wins
            // ====================================================

            tb_stage = "GAME2 SINK SHIP2";

            j1_fire_expect(1, 1, 8'd0, 1'b1);

            j2_fire_expect(
                8'd2,
                8'd1,
                8'd2,
                1'b0
            );


            // ====================================================
            // GAME OVER
            //
            // 9 J1 shots + 9 J2 shots = 18
            // ====================================================

            tb_stage =
                "GAME2 GAME OVER";


            expect_game_over(
                game_before + 1,
                8'd1,
                16'd18,
                8'd0,
                8'd3
            );


            expect_int(
                "GAME2 CMD86",
                count_incoming - incoming_before,
                9
            );


            expect_int(
                "GAME2 CMD85",
                count_shot_result - shot_before,
                9
            );


            // Despues del initial turn:
            // 9 turnos hacia J2
            // 8 regresos hacia J1
            expect_int(
                "GAME2 TURN adicionales",
                count_turn - turn_before,
                17
            );


            expect_int(
                "GAME2 sunk J2",
                count_shot_result_sunk - sunk_before,
                3
            );


            // ----------------------------------------------------
            // VGA local hit
            // ----------------------------------------------------

            expect_vga_local(
                0,
                0,
                32'd2
            );


            expect_vga_local(
                2,
                1,
                32'd2
            );


            // ----------------------------------------------------
            // Scores
            // ----------------------------------------------------

            expect32(
                "GAME2 P1 score",
                dut.u_data_ram.mem[P1_WINS_IDX],
                32'd1
            );


            expect32(
                "GAME2 P2 score",
                dut.u_data_ram.mem[P2_WINS_IDX],
                32'd1
            );


            expect32(
                "GAME2 display",
                dut.u_display.datos_reg,
                32'h0000_0101
            );


            flag_j2_victory_pass =
                1'b1;

            flag_sunk_j2_pass =
                1'b1;


            $display("PASS: GAME 2");

        end

    endtask


    // ============================================================
    // GAME 3
    //
    // Score starts at 99-99.
    // J1 wins and both scores must remain at 99.
    // ============================================================

    task automatic run_game3_score_saturation;

        integer game_before;

        begin

            $display("");
            $display("============================================================");
            $display(" GAME 3 - SCORE SATURATION 99");
            $display("============================================================");


            tb_stage =
                "GAME3 FORCE SCORE 99";


            // ----------------------------------------------------
            // Fuerza temporalmente RAM a 99-99.
            //
            // Se mantiene hasta que _start haya cargado s6/s7.
            // ----------------------------------------------------

            @(negedge clk100mhz);

            force dut.u_data_ram.mem[P1_WINS_IDX] =
                32'd99;

            force dut.u_data_ram.mem[P2_WINS_IDX] =
                32'd99;


            reset_to_placement();


            wait_display(
                32'h0000_9999
            );


            // El firmware ya cargo los valores en s6/s7.
            release dut.u_data_ram.mem[P1_WINS_IDX];
            release dut.u_data_ram.mem[P2_WINS_IDX];


            // ----------------------------------------------------
            // FLEETS
            // ----------------------------------------------------

            tb_stage =
                "GAME3 LOCAL PLACEMENT";


            setup_local_fleet(
                1'b0
            );


            tb_stage =
                "GAME3 REMOTE PLACEMENT";


            setup_remote_fleet(
                1'b0
            );


            // Initial turn
            begin : game3_initial_turn

                integer target;

                target =
                    count_turn + 1;

                wait_event_count(
                    EVT_TURN,
                    target
                );

            end


            game_before =
                count_game_over;


            // ====================================================
            // J1 sinks all ships
            // J2 fires misses
            // ====================================================

            tb_stage = "GAME3 SHIP0";

            j1_fire_expect(0, 4, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd0, 8'd0, 1'b1);

            j1_fire_expect(1, 4, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd1, 8'd0, 1'b1);

            j1_fire_expect(2, 4, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd2, 8'd0, 1'b1);

            j1_fire_expect(3, 4, 8'd2, 1'b1);
            j2_fire_expect(8'd7, 8'd3, 8'd0, 1'b1);


            tb_stage = "GAME3 SHIP1";

            j1_fire_expect(4, 0, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd4, 8'd0, 1'b1);

            j1_fire_expect(4, 1, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd5, 8'd0, 1'b1);

            j1_fire_expect(4, 2, 8'd2, 1'b1);
            j2_fire_expect(8'd7, 8'd6, 8'd0, 1'b1);


            tb_stage = "GAME3 SHIP2";

            j1_fire_expect(6, 0, 8'd1, 1'b1);
            j2_fire_expect(8'd7, 8'd7, 8'd0, 1'b1);


            j1_fire_expect(
                6,
                1,
                8'd2,
                1'b0
            );


            tb_stage =
                "GAME3 GAME OVER";


            expect_game_over(
                game_before + 1,
                8'd0,
                16'd17,
                8'd3,
                8'd0
            );


            // ----------------------------------------------------
            // Saturacion
            // ----------------------------------------------------

            expect32(
                "P1 saturado en 99",
                dut.u_data_ram.mem[P1_WINS_IDX],
                32'd99
            );


            expect32(
                "P2 permanece 99",
                dut.u_data_ram.mem[P2_WINS_IDX],
                32'd99
            );


            expect32(
                "Display 99-99",
                dut.u_display.datos_reg,
                32'h0000_9999
            );


            // ----------------------------------------------------
            // Reset adicional para demostrar persistencia
            // ----------------------------------------------------

            tb_stage =
                "GAME3 FINAL RESET";


            reset_to_placement();


            wait_display(
                32'h0000_9999
            );


            expect32(
                "P1 99 after reset",
                dut.u_data_ram.mem[P1_WINS_IDX],
                32'd99
            );


            expect32(
                "P2 99 after reset",
                dut.u_data_ram.mem[P2_WINS_IDX],
                32'd99
            );


            flag_score_saturation_pass =
                1'b1;


            $display("PASS: GAME 3 / SCORE SATURATION");

        end

    endtask


    // ============================================================
    // OPTIONAL CONCURRENT PLACEMENT TEST
    //
    // CURRENT FIRMWARE EXPECTED TO FAIL THIS.
    //
    // Enable with:
    //
    // REQUIRE_CONCURRENT_PLACEMENT = 1
    //
    // ============================================================

    task automatic run_concurrent_placement_test;

        integer ok_before;
        integer battle_before;

        logic local_done;

        begin

            $display("");
            $display("============================================================");
            $display(" CONCURRENT PLACEMENT TEST");
            $display("============================================================");


            tb_stage =
                "CONCURRENT PLACEMENT";


            reset_to_placement();


            ok_before =
                count_place_ok;

            battle_before =
                count_battle_start;

            local_done =
                1'b0;


            fork

                // ------------------------------------------------
                // J2 sends ship 0 while J1 is still placing.
                // ------------------------------------------------

                begin

                    repeat (100)
                        @(posedge clk100mhz);


                    $display(
                        "[%0t] Concurrent test: J2 sends placement while J1 is placing",
                        $time
                    );


                    send_place_nowait(
                        8'd0,
                        8'd0,
                        8'd4,
                        8'd1
                    );

                end


                // ------------------------------------------------
                // J1 placement
                // ------------------------------------------------

                begin

                    // Give J2 transmission time to begin.
                    repeat (200_000)
                        @(posedge clk100mhz);


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


                    local_done =
                        1'b1;

                end

            join


            // A concurrent implementation should already have
            // acknowledged ship 0.
            if (
                count_place_ok <= ok_before
            ) begin

                tb_fatal(
                    "Concurrent placement not supported"
                );

            end


            // Complete remote fleet.
            remote_place_expect_ok(
                8'd1,
                8'd4,
                8'd0,
                8'd0
            );


            remote_place_expect_ok(
                8'd2,
                8'd6,
                8'd0,
                8'd0
            );


            wait_event_count(
                EVT_BATTLE_START,
                battle_before + 1
            );


            flag_concurrent_placement_pass =
                1'b1;


            $display(
                "PASS: concurrent placement"
            );

        end

    endtask


    // ============================================================
    // FINAL COVERAGE CHECK
    // ============================================================

    task automatic final_coverage_check;

        begin

            tb_stage =
                "FINAL COVERAGE";


            // ----------------------------------------------------
            // Protocol
            // ----------------------------------------------------

            expect_int(
                "Protocol error count",
                protocol_error_count,
                0
            );


            // ----------------------------------------------------
            // Buzzer
            // ----------------------------------------------------

            if (
                count_buzzer_hit > 0 &&
                count_buzzer_miss > 0 &&
                count_buzzer_sunk > 0 &&
                count_buzzer_invalid > 0 &&
                count_buzzer_victory > 0
            ) begin

                flag_buzzer_coverage_pass =
                    1'b1;

            end
            else begin

                tb_fatal(
                    "Buzzer coverage incompleta"
                );

            end


            // ----------------------------------------------------
            // LEDs
            // ----------------------------------------------------

            if (
                seen_led_placement &&
                seen_led_battle &&
                seen_led_gameover
            ) begin

                flag_led_coverage_pass =
                    1'b1;

            end
            else begin

                tb_fatal(
                    "LED state coverage incompleta"
                );

            end


            // ----------------------------------------------------
            // Required regression flags
            // ----------------------------------------------------

            if (!flag_local_invalid_pass)
                tb_fatal("Local invalid placement not tested");

            if (!flag_remote_invalid_pass)
                tb_fatal("Remote invalid placement not tested");

            if (!flag_vga_secrecy_pass)
                tb_fatal("VGA secrecy not tested");

            if (!flag_vga_hit_miss_pass)
                tb_fatal("VGA hit/miss not tested");

            if (!flag_repeat_j1_pass)
                tb_fatal("J1 repeated shot not tested");

            if (!flag_repeat_j2_pass)
                tb_fatal("J2 repeated shot not tested");

            if (!flag_j1_victory_pass)
                tb_fatal("J1 victory not tested");

            if (!flag_j2_victory_pass)
                tb_fatal("J2 victory not tested");

            if (!flag_sunk_j1_pass)
                tb_fatal("J1 sunk logic not tested");

            if (!flag_sunk_j2_pass)
                tb_fatal("J2 sunk logic not tested");

            if (!flag_score_persistence_pass)
                tb_fatal("Score persistence not tested");

            if (!flag_score_saturation_pass)
                tb_fatal("Score saturation not tested");

            if (!flag_buzzer_coverage_pass)
                tb_fatal("Buzzer coverage failed");

            if (!flag_led_coverage_pass)
                tb_fatal("LED coverage failed");

            if (!flag_target_cursor_pass)
                tb_fatal("J1 target cursor not tested");

            if (!flag_remote_order_pass)
                tb_fatal("Strict remote fleet order not tested");


            if (REQUIRE_CONCURRENT_PLACEMENT) begin

                if (!flag_concurrent_placement_pass)
                    tb_fatal(
                        "Concurrent placement failed"
                    );

            end

        end

    endtask


    // ============================================================
    // TEST PRINCIPAL
    // ============================================================

    initial begin

        $display("");
        $display("============================================================");
        $display(" BATTLESHIP FULL SOC REGRESSION");
        $display("============================================================");

        $display("TRACE_UART_FRAMES = %0d", TRACE_UART_FRAMES);
        $display("TRACE_GPIO        = %0d", TRACE_GPIO);
        $display("TRACE_BUZZER      = %0d", TRACE_BUZZER);
        $display("TRACE_VGA         = %0d", TRACE_VGA);

        $display(
            "CONCURRENT TEST   = %0d",
            REQUIRE_CONCURRENT_PLACEMENT
        );

        $display("============================================================");
        $display("");


        uart_rx = 1'b1;

        btnC = 1'b1;


        // ========================================================
        // GAME 1
        // ========================================================

        run_game1();


        // ========================================================
        // GAME 2
        // ========================================================

        run_game2();


        // ========================================================
        // GAME 3
        // ========================================================

        run_game3_score_saturation();


        // ========================================================
        // CONCURRENT PLACEMENT
        // ========================================================

        if (REQUIRE_CONCURRENT_PLACEMENT) begin

            run_concurrent_placement_test();

        end
        else begin

            $display("");
            $display(
                "SKIP: concurrent placement"
            );

            $display(
                "      Current firmware is sequential."
            );

            $display(
                "      Set REQUIRE_CONCURRENT_PLACEMENT=1 after implementing it."
            );

        end


        // ========================================================
        // FINAL COVERAGE
        // ========================================================

        final_coverage_check();


        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("============================================================");
        $display(" FULL REGRESSION SUMMARY");
        $display("============================================================");

        $display(
            " Local invalid placement ........ PASS"
        );

        $display(
            " Remote invalid placements ...... PASS"
        );

        $display(
            " UART CMD82 reasons ............. PASS"
        );

        $display(
            " VGA enemy secrecy .............. PASS"
        );

        $display(
            " VGA hit/miss rendering ......... PASS"
        );

        $display(
            " J1 target cursor ............... PASS"
        );

        $display(
            " Strict remote fleet order ...... PASS"
        );

        $display(
            " Repeated shot J1 ............... PASS"
        );

        $display(
            " Repeated shot J2 ............... PASS"
        );

        $display(
            " J1 victory ..................... PASS"
        );

        $display(
            " J2 victory ..................... PASS"
        );

        $display(
            " HIT/SUNK J1 .................... PASS"
        );

        $display(
            " HIT/SUNK J2 .................... PASS"
        );

        $display(
            " GAME_OVER payload .............. PASS"
        );

        $display(
            " Score persistence .............. PASS"
        );

        $display(
            " Score saturation at 99 ......... PASS"
        );

        $display(
            " Buzzer event coverage .......... PASS"
        );

        $display(
            " LED state coverage ............. PASS"
        );

        $display(
            " UART checksum/ETX monitor ...... PASS"
        );


        if (REQUIRE_CONCURRENT_PLACEMENT) begin

            $display(
                " Concurrent placement ........... PASS"
            );

        end
        else begin

            $display(
                " Concurrent placement ........... SKIPPED"
            );

        end


        $display("------------------------------------------------------------");

        $display(
            " UART frames: 80=%0d 81=%0d 82=%0d 83=%0d 84=%0d 85=%0d 86=%0d 87=%0d",
            count_place_start,
            count_place_ok,
            count_place_bad,
            count_battle_start,
            count_turn,
            count_shot_result,
            count_incoming,
            count_game_over
        );

        $display(
            " Sunk events: J1=%0d J2=%0d",
            count_incoming_sunk,
            count_shot_result_sunk
        );

        $display(
            " MMIO writes=%0d RAM=%0d VGA=%0d UART_TX=%0d",
            mmio_write_count,
            ram_write_count,
            vga_write_count,
            uart_tx_write_count
        );

        $display(
            " Buzzer: hit=%0d miss=%0d sunk=%0d invalid=%0d victory=%0d",
            count_buzzer_hit,
            count_buzzer_miss,
            count_buzzer_sunk,
            count_buzzer_invalid,
            count_buzzer_victory
        );

        $display(
            " Final score RAM: J1=%0d J2=%0d",
            dut.u_data_ram.mem[P1_WINS_IDX],
            dut.u_data_ram.mem[P2_WINS_IDX]
        );

        $display(
            " Final display=%08h",
            dut.u_display.datos_reg
        );

        $display("============================================================");
        $display(" soc_top_tb: FULL REGRESSION PASSED");
        $display("============================================================");
        $display("");


        $finish;

    end


    // ============================================================
    // GLOBAL WATCHDOG
    //
    // Evita que una simulacion trabada siga para siempre si se
    // utiliza "run all".
    //
    // 250 ms simulados.
    // ============================================================

    initial begin : global_watchdog

        #250_000_000;


        $display("");
        $display("GLOBAL WATCHDOG TIMEOUT");


        dump_debug_state();
        dump_boards();


        $fatal(
            1,
            "La regresion excedio 250 ms simulados"
        );

    end

endmodule