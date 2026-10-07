# Batalla Naval - firmware RV32I
#
# Registros base fijos:
#   gp = 0x00010000  base de perifericos
#   tp = 0x00011000  base de memoria de video VGA
#   s0 = 0x00002000  tablero local
#   s1 = 0x00002100  tablero remoto
#
# Mapa de RAM:
#   0x00002000 - tablero local   (64 palabras)
#   0x00002100 - tablero remoto  (64 palabras)
#   0x00002E00 - FRAME_BUF       (hasta 32 bytes)
#   0x00002E20 - estado parser UART placement
#   0x00002F00 - P1_WINS
#   0x00002F04 - P2_WINS
#   0x00002FFC - STACK_TOP
#
# GPIO:
#   bit6 RST
#   bit5 arriba
#   bit4 abajo
#   bit3 izquierda
#   bit2 derecha
#   bit1 seleccionar/orientacion
#   bit0 confirmar
#
# Representacion interna de casillas:
#   0 = agua
#   1 = barco 0 intacto (longitud 4)
#   2 = barco 1 intacto (longitud 3)
#   3 = barco 2 intacto (longitud 2)
#   4 = fallo
#   5 = impacto barco 0
#   6 = impacto barco 1
#   7 = impacto barco 2
#
# Trama UART:
#   STX(02) CMD LEN PAYLOAD CHECKSUM(XOR CMD,LEN,PAYLOAD) ETX(03)
#
# UART CTRL:
#   bit0 = TX ocupado
#   bit1 = RX listo


# ---------------------------------------------------------------------------
# Perifericos
# ---------------------------------------------------------------------------

.eqv UART_CTRL,   0x40
.eqv UART_TX,     0x44
.eqv UART_RX,     0x48

.eqv GPIO_OFF,    0x120
.eqv DISPLAY_OFF, 0x130
.eqv LED_OFF,     0x138
.eqv BUZZER_OFF,  0x140


# ---------------------------------------------------------------------------
# RAM
# ---------------------------------------------------------------------------

.eqv REMOTE_OFF,  0x100

.eqv FRAME_BUF,         0x00002E00

.eqv PLACE_UART_STATE,  0x00002E20
.eqv PLACE_UART_CMD,    0x00002E24
.eqv PLACE_UART_LEN,    0x00002E28
.eqv PLACE_UART_IDX,    0x00002E2C
.eqv PLACE_UART_CHK,    0x00002E30

.eqv P1_WINS,           0x00002F00
.eqv P2_WINS,           0x00002F04


# ---------------------------------------------------------------------------
# Protocolo UART
# ---------------------------------------------------------------------------

.eqv STX,              0x02
.eqv ETX,              0x03

.eqv CMD_PLACE,        0x01
.eqv CMD_FIRE,         0x02

.eqv EVT_PLACE_START,  0x80
.eqv EVT_PLACE_OK,     0x81
.eqv EVT_PLACE_BAD,    0x82
.eqv EVT_BATTLE_START, 0x83
.eqv EVT_TURN,         0x84
.eqv EVT_SHOT_RESULT,  0x85
.eqv EVT_INCOMING,     0x86
.eqv EVT_GAME_OVER,    0x87


# ---------------------------------------------------------------------------
# Botones
# ---------------------------------------------------------------------------

.eqv BTN_UP,           0x20
.eqv BTN_DOWN,         0x10
.eqv BTN_LEFT,         0x08
.eqv BTN_RIGHT,        0x04
.eqv BTN_SELECT,       0x02
.eqv BTN_OK,           0x01


# Buzzer:
# 1 impacto
# 2 fallo
# 3 hundido
# 4 colocacion invalida
# 5 victoria


.globl _start
.globl main


# ===========================================================================
# INICIO
# ===========================================================================

main:
_start:

    li      sp, 0x2FFC

    li      s0, 0x2000
    addi    s1, s0, REMOTE_OFF

    li      gp, 0x10000
    li      tp, 0x11000

    li      s2, 0
    li      s3, 0
    li      s4, 0
    li      s5, 0


    # Recuperar score

    li      t0, P1_WINS
    lw      s6, 0(t0)

    li      t0, P2_WINS
    lw      s7, 0(t0)


    # Limpiar tableros

    mv      a0, s0
    li      a1, 64
    jal     ra, clear_board

    mv      a0, s1
    li      a1, 64
    jal     ra, clear_board


    # VGA

    jal     ra, clear_vga


    # Fase placement

    li      a0, 0
    jal     ra, led_write

    jal     ra, update_score_display
    jal     ra, render_boards
    jal     ra, render_hud_initial


    # J1 y J2 colocan concurrentemente

    jal     ra, concurrent_placement


    # -------------------------------------------------------
    # Reiniciar registros reutilizados para batalla
    # -------------------------------------------------------

    li      s2, 0
    li      s3, 0
    li      s4, 0
    li      s5, 0
    li      s10, 0
    li      s11, 0

    # HUD de batalla: nombres + 3 barcos por jugador
    jal     ra, render_hud_battle


    # Fase batalla

    li      a0, 1
    jal     ra, led_write


    li      a0, EVT_BATTLE_START
    li      a1, FRAME_BUF
    li      a2, 0
    jal     ra, uart_send_frame


    # J1 inicia

    li      s2, 0

    li      a0, 0
    jal     ra, send_turn



# ===========================================================================
# BUCLE PRINCIPAL
# ===========================================================================

battle_loop:

    beq     s2, x0, local_turn

    jal     x0, remote_turn



# ===========================================================================
# COLOCACION CONCURRENTE
#
# s2  = latch de boton
# s3  = barcos remotos aceptados
# s8  = fila local
# s9  = columna local
# s10 = barco local
# s11 = orientacion
#
# Termina cuando:
#   s10 == 3
#   s3  == 3
# ===========================================================================

concurrent_placement:

    addi    sp, sp, -4
    sw      ra, 0(sp)


    # Estado local

    li      s2, 0

    li      s8, 0
    li      s9, 0
    li      s10, 0
    li      s11, 0


    # Remotos aceptados

    li      s3, 0


    # Inicializar parser UART

    li      t0, PLACE_UART_STATE
    sw      x0, 0(t0)

    li      t0, PLACE_UART_CMD
    sw      x0, 0(t0)

    li      t0, PLACE_UART_LEN
    sw      x0, 0(t0)

    li      t0, PLACE_UART_IDX
    sw      x0, 0(t0)

    li      t0, PLACE_UART_CHK
    sw      x0, 0(t0)


    # Preparar cursor primero

    jal     ra, render_local_cursor


    # Ahora si se informa al PC que estamos listos

    li      a0, EVT_PLACE_START
    li      a1, FRAME_BUF
    li      a2, 0

    jal     ra, uart_send_frame



concurrent_place_loop:

    # Ambos jugadores terminaron de colocar

    li      t0, 3

    bne     s10, t0, concurrent_service
    bne     s3, t0, concurrent_service


    # No salir mientras el ultimo switch siga activo

    bne     s2, x0, concurrent_service


    # Ambos terminaron y el ultimo control fue liberado

    lw      ra, 0(sp)

    addi    sp, sp, 4

    jalr    x0, 0(ra)



# ===========================================================================
# SERVICIO CONCURRENTE
# ===========================================================================

concurrent_service:

    # UART

    li      t0, 3

    beq     s3, t0, concurrent_gpio


    lw      t1, UART_CTRL(gp)

    andi    t1, t1, 2


    beq     t1, x0, concurrent_gpio


    lw      a0, UART_RX(gp)

    andi    a0, a0, 0xff


    jal     ra, placement_uart_feed


    beq     a0, x0, concurrent_gpio


    jal     ra, placement_process_frame


    jal     x0, concurrent_place_loop



# ===========================================================================
# GPIO LOCAL
# ===========================================================================

concurrent_gpio:

    lw      t1, GPIO_OFF(gp)

    andi    t1, t1, 0x3f


    # Esperando liberacion

    bne     s2, x0, concurrent_gpio_release_check


    # J1 ya termino

    li      t0, 3

    beq     s10, t0, concurrent_place_loop


    # Sin botones

    beq     t1, x0, concurrent_place_loop


    jal     x0, concurrent_gpio_new_press



concurrent_gpio_release_check:

    bne     t1, x0, concurrent_place_loop


    # Liberado

    li      s2, 0


    jal     x0, concurrent_place_loop



concurrent_gpio_new_press:

    beq     t1, x0, concurrent_place_loop


    li      s2, 1


    andi    t2, t1, BTN_UP

    bne     t2, x0, concurrent_up


    andi    t2, t1, BTN_DOWN

    bne     t2, x0, concurrent_down


    andi    t2, t1, BTN_LEFT

    bne     t2, x0, concurrent_left


    andi    t2, t1, BTN_RIGHT

    bne     t2, x0, concurrent_right


    andi    t2, t1, BTN_SELECT

    bne     t2, x0, concurrent_select


    andi    t2, t1, BTN_OK

    bne     t2, x0, concurrent_ok


    jal     x0, concurrent_place_loop



# ===========================================================================
# MOVIMIENTO LOCAL
# ===========================================================================

concurrent_up:

    beq     s8, x0, concurrent_place_loop

    addi    s8, s8, -1

    jal     ra, render_local_cursor

    jal     x0, concurrent_place_loop



concurrent_down:

    li      t0, 7

    beq     s8, t0, concurrent_place_loop

    addi    s8, s8, 1

    jal     ra, render_local_cursor

    jal     x0, concurrent_place_loop



concurrent_left:

    beq     s9, x0, concurrent_place_loop

    addi    s9, s9, -1

    jal     ra, render_local_cursor

    jal     x0, concurrent_place_loop



concurrent_right:

    li      t0, 7

    beq     s9, t0, concurrent_place_loop

    addi    s9, s9, 1

    jal     ra, render_local_cursor

    jal     x0, concurrent_place_loop



concurrent_select:

    xori    s11, s11, 1

    jal     ra, render_local_cursor

    jal     x0, concurrent_place_loop



# ===========================================================================
# CONFIRMAR BARCO LOCAL
# ===========================================================================

concurrent_ok:

    mv      a0, s0
    mv      a1, s8
    mv      a2, s9
    mv      a3, s11
    mv      a4, s10

    jal     ra, validate_place


    bne     a0, x0, concurrent_local_invalid


    # Escribir barco

    mv      a0, s0
    mv      a1, s8
    mv      a2, s9
    mv      a3, s11
    mv      a4, s10

    jal     ra, write_ship


    jal     ra, render_boards


    # Siguiente barco

    addi    s10, s10, 1


    li      t0, 3

    beq     s10, t0, concurrent_place_loop


    # Reiniciar cursor

    li      s8, 0
    li      s9, 0
    li      s11, 0


    jal     ra, render_local_cursor


    jal     x0, concurrent_place_loop



concurrent_local_invalid:

    li      a0, 4

    jal     ra, buzzer_write


    jal     ra, render_local_cursor


    jal     x0, concurrent_place_loop



# ===========================================================================
# PARSER UART NO BLOQUEANTE DURANTE PLACEMENT
# ===========================================================================

placement_uart_feed:

    mv      t6, a0


    li      t0, PLACE_UART_STATE

    lw      t1, 0(t0)


    beq     t1, x0, placement_uart_state_stx


    li      t2, 1

    beq     t1, t2, placement_uart_state_cmd


    li      t2, 2

    beq     t1, t2, placement_uart_state_len


    li      t2, 3

    beq     t1, t2, placement_uart_state_payload


    li      t2, 4

    beq     t1, t2, placement_uart_state_checksum


    li      t2, 5

    beq     t1, t2, placement_uart_state_etx


    sw      x0, 0(t0)


    li      a0, 0

    jalr    x0, 0(ra)



placement_uart_state_stx:

    li      t2, STX

    bne     t6, t2, placement_uart_incomplete


    li      t1, 1

    sw      t1, 0(t0)


    jal     x0, placement_uart_incomplete



placement_uart_state_cmd:

    li      t2, PLACE_UART_CMD

    sw      t6, 0(t2)


    li      t2, PLACE_UART_CHK

    sw      t6, 0(t2)


    li      t1, 2

    sw      t1, 0(t0)


    jal     x0, placement_uart_incomplete



placement_uart_state_len:

    li      t2, 32

    blt     t2, t6, placement_uart_reset


    li      t2, PLACE_UART_LEN

    sw      t6, 0(t2)


    li      t2, PLACE_UART_IDX

    sw      x0, 0(t2)


    li      t2, PLACE_UART_CHK

    lw      t3, 0(t2)


    xor     t3, t3, t6

    sw      t3, 0(t2)


    beq     t6, x0, placement_uart_len_zero


    li      t1, 3

    sw      t1, 0(t0)


    jal     x0, placement_uart_incomplete



placement_uart_len_zero:

    li      t1, 4

    sw      t1, 0(t0)


    jal     x0, placement_uart_incomplete



placement_uart_state_payload:

    li      t2, PLACE_UART_IDX

    lw      t3, 0(t2)


    li      t4, FRAME_BUF

    add     t4, t4, t3


    sb      t6, 0(t4)


    li      t4, PLACE_UART_CHK

    lw      t5, 0(t4)


    xor     t5, t5, t6

    sw      t5, 0(t4)


    addi    t3, t3, 1

    sw      t3, 0(t2)


    li      t4, PLACE_UART_LEN

    lw      t5, 0(t4)


    bne     t3, t5, placement_uart_incomplete


    li      t1, 4

    sw      t1, 0(t0)


    jal     x0, placement_uart_incomplete



placement_uart_state_checksum:

    li      t2, PLACE_UART_CHK

    lw      t3, 0(t2)


    bne     t6, t3, placement_uart_reset


    li      t1, 5

    sw      t1, 0(t0)


    jal     x0, placement_uart_incomplete



placement_uart_state_etx:

    li      t2, ETX

    bne     t6, t2, placement_uart_reset


    sw      x0, 0(t0)


    li      a0, 1

    jalr    x0, 0(ra)



placement_uart_reset:

    li      t0, PLACE_UART_STATE

    sw      x0, 0(t0)


    li      a0, 0

    jalr    x0, 0(ra)



placement_uart_incomplete:

    li      a0, 0

    jalr    x0, 0(ra)



# ===========================================================================
# PROCESAR FRAME DE PLACEMENT
# ===========================================================================

placement_process_frame:

    addi    sp, sp, -4

    sw      ra, 0(sp)


    li      t0, PLACE_UART_CMD

    lw      t1, 0(t0)


    li      t0, CMD_PLACE

    bne     t1, t0, placement_frame_done


    li      t0, PLACE_UART_LEN

    lw      t1, 0(t0)


    li      t0, 4

    bne     t1, t0, placement_frame_done


    # Payload: ID ROW COL ORIENTATION

    li      t5, FRAME_BUF


    lbu     t1, 0(t5)
    lbu     t2, 1(t5)
    lbu     t3, 2(t5)
    lbu     t4, 3(t5)


    # ID debe ser exactamente el siguiente esperado

    beq     t1, s3, placement_remote_id_ok


    li      a0, 2

    jal     x0, placement_remote_invalid



placement_remote_id_ok:

    mv      a0, s1
    mv      a1, t2
    mv      a2, t3
    mv      a3, t4
    mv      a4, t1

    jal     ra, validate_place


    bne     a0, x0, placement_remote_invalid


    li      t5, FRAME_BUF


    lbu     t1, 0(t5)
    lbu     t2, 1(t5)
    lbu     t3, 2(t5)
    lbu     t4, 3(t5)


    mv      a0, s1
    mv      a1, t2
    mv      a2, t3
    mv      a3, t4
    mv      a4, t1

    jal     ra, write_ship


    # ACK

    li      a0, EVT_PLACE_OK
    li      a1, FRAME_BUF
    li      a2, 1

    jal     ra, uart_send_frame


    addi    s3, s3, 1


    jal     ra, render_boards


    li      t0, 3

    beq     s10, t0, placement_frame_done


    jal     ra, render_local_cursor


    jal     x0, placement_frame_done



placement_remote_invalid:

    # 1 overlap -> reason 0
    # 2 rango   -> reason 1

    addi    a0, a0, -1


    li      t5, FRAME_BUF

    sb      a0, 1(t5)


    li      a0, EVT_PLACE_BAD
    li      a1, FRAME_BUF
    li      a2, 2

    jal     ra, uart_send_frame


    # Buzzer tambien para colocacion invalida desde PC

    li      a0, 4

    jal     ra, buzzer_write


    jal     ra, render_boards


    li      t0, 3

    beq     s10, t0, placement_frame_done


    jal     ra, render_local_cursor



placement_frame_done:

    lw      ra, 0(sp)

    addi    sp, sp, 4

    jalr    x0, 0(ra)



# ===========================================================================
# TURNO LOCAL
# ===========================================================================

local_turn:

    li      s8, 0
    li      s9, 0

    jal     ra, render_target_cursor



local_fire_repeat:

    jal     ra, render_target_cursor

    jal     x0, local_fire_input



local_fire_input:

    jal     ra, read_buttons

    mv      t0, a0


    # UP

    andi    t1, t0, BTN_UP

    beq     t1, x0, lf_down

    beq     s8, x0, local_fire_input

    addi    s8, s8, -1

    jal     ra, render_target_cursor

    jal     x0, local_fire_input



lf_down:

    andi    t1, t0, BTN_DOWN

    beq     t1, x0, lf_left

    li      t2, 7

    beq     s8, t2, local_fire_input

    addi    s8, s8, 1

    jal     ra, render_target_cursor

    jal     x0, local_fire_input



lf_left:

    andi    t1, t0, BTN_LEFT

    beq     t1, x0, lf_right

    beq     s9, x0, local_fire_input

    addi    s9, s9, -1

    jal     ra, render_target_cursor

    jal     x0, local_fire_input



lf_right:

    andi    t1, t0, BTN_RIGHT

    beq     t1, x0, lf_ok

    li      t2, 7

    beq     s9, t2, local_fire_input

    addi    s9, s9, 1

    jal     ra, render_target_cursor

    jal     x0, local_fire_input



lf_ok:

    andi    t1, t0, BTN_OK

    beq     t1, x0, local_fire_input


    mv      a0, s1
    mv      a1, s8
    mv      a2, s9

    jal     ra, resolve_shot


    li      t0, 3

    beq     a0, t0, local_fire_repeat


    mv      t6, a0


    addi    s5, s5, 1


    beq     t6, x0, local_fire_sound


    addi    s4, s4, 1


    li      t0, 2

    bne     t6, t0, local_fire_sound


    addi    s10, s10, 1



local_fire_sound:

    # miss

    li      a0, 2

    beq     t6, x0, local_buz


    # hit

    li      a0, 1


    # sunk

    li      t0, 2

    bne     t6, t0, local_buz


    li      a0, 3



local_buz:

    jal     ra, buzzer_write


    mv      a0, s8
    mv      a1, s9
    mv      a2, t6

    jal     ra, send_incoming


    jal     ra, render_boards
    jal     ra, render_hud_battle


    # Victoria J1

    li      t0, 3

    bne     s10, t0, local_continue


    li      a0, 0

    jal     ra, finish_game


    jal     x0, _start



local_continue:

    li      s2, 1


    li      a0, 1

    jal     ra, send_turn


    jal     x0, battle_loop



# ===========================================================================
# TURNO REMOTO
# ===========================================================================

remote_turn:

    jal     ra, uart_recv_frame


    li      t0, CMD_FIRE

    bne     a0, t0, remote_turn


    li      t0, 2

    bne     a1, t0, remote_turn


    li      t5, FRAME_BUF


    lbu     t1, 0(t5)

    lbu     t2, 1(t5)


    li      t0, 7

    bgt     t1, t0, remote_turn

    bgt     t2, t0, remote_turn


    mv      a0, s0
    mv      a1, t1
    mv      a2, t2

    jal     ra, resolve_shot


    li      t0, 3

    beq     a0, t0, remote_turn


    mv      t6, a0


    addi    s5, s5, 1


    beq     t6, x0, remote_sound


    addi    s3, s3, 1


    li      t0, 2

    bne     t6, t0, remote_sound


    addi    s11, s11, 1



remote_sound:

    li      a0, 2

    beq     t6, x0, remote_buz


    li      a0, 1


    li      t0, 2

    bne     t6, t0, remote_buz


    li      a0, 3



remote_buz:

    jal     ra, buzzer_write



remote_result:

    li      t5, FRAME_BUF


    lbu     t1, 0(t5)

    lbu     t2, 1(t5)


    mv      a0, t1
    mv      a1, t2
    mv      a2, t6


    jal     ra, send_shot_result


    jal     ra, render_boards
    jal     ra, render_hud_battle


    # Victoria J2

    li      t0, 3

    bne     s11, t0, remote_continue


    li      a0, 1

    jal     ra, finish_game


    jal     x0, _start



remote_continue:

    li      s2, 0


    li      a0, 0

    jal     ra, send_turn


    jal     x0, battle_loop



# ===========================================================================
# TABLEROS
# ===========================================================================

clear_board:

    li      t0, 0



clear_board_loop:

    beq     t0, a1, clear_board_done


    sw      x0, 0(a0)


    addi    a0, a0, 4

    addi    t0, t0, 1


    jal     x0, clear_board_loop



clear_board_done:

    jalr    x0, 0(ra)



# ===========================================================================
# LIMPIAR VGA
# ===========================================================================

clear_vga:

    li      t0, 0

    li      t1, 300



clear_vga_loop:

    beq     t0, t1, clear_vga_done


    slli    t2, t0, 2

    add     t2, t2, tp


    sw      x0, 0(t2)


    addi    t0, t0, 1


    jal     x0, clear_vga_loop



clear_vga_done:

    jalr    x0, 0(ra)



# ===========================================================================
# VALIDAR COLOCACION
# ===========================================================================

validate_place:

    # row

    li      t1, 7

    blt     t1, a1, place_out


    # col

    blt     t1, a2, place_out


    # orientation

    li      t1, 1

    blt     t1, a3, place_out


    # ID

    li      t1, 2

    blt     t1, a4, place_out


    # Longitud

    li      t0, 4

    beq     a4, x0, ship_length_done


    li      t0, 3

    li      t1, 1

    beq     a4, t1, ship_length_done


    li      t0, 2



ship_length_done:

    # Vertical

    beq     a3, x0, horizontal_bounds


    add     t1, a1, t0


    li      t2, 8

    blt     t2, t1, place_out


    jal     x0, place_scan



horizontal_bounds:

    add     t1, a2, t0


    li      t2, 8

    blt     t2, t1, place_out



place_scan:

    li      t1, 0



place_scan_loop:

    beq     t1, t0, place_valid


    beq     a3, x0, scan_horizontal


    # Vertical

    add     t2, a1, t1

    mv      t3, a2


    jal     x0, scan_address



scan_horizontal:

    mv      t2, a1

    add     t3, a2, t1



scan_address:

    slli    t4, t2, 3

    add     t4, t4, t3

    slli    t4, t4, 2

    add     t4, a0, t4


    lw      t5, 0(t4)


    bne     t5, x0, place_overlap


    addi    t1, t1, 1


    jal     x0, place_scan_loop



place_valid:

    li      a0, 0

    jalr    x0, 0(ra)



place_overlap:

    li      a0, 1

    jalr    x0, 0(ra)



place_out:

    li      a0, 2

    jalr    x0, 0(ra)



# ===========================================================================
# ESCRIBIR BARCO
# ===========================================================================

write_ship:

    li      t0, 4

    beq     a4, x0, write_length_done


    li      t0, 3

    li      t1, 1

    beq     a4, t1, write_length_done


    li      t0, 2



write_length_done:

    li      t1, 0



write_ship_loop:

    beq     t1, t0, write_ship_done


    beq     a3, x0, write_horizontal


    add     t2, a1, t1

    mv      t3, a2


    jal     x0, write_address



write_horizontal:

    mv      t2, a1

    add     t3, a2, t1



write_address:

    slli    t4, t2, 3

    add     t4, t4, t3

    slli    t4, t4, 2

    add     t4, a0, t4


    addi    t5, a4, 1


    sw      t5, 0(t4)


    addi    t1, t1, 1


    jal     x0, write_ship_loop



write_ship_done:

    jalr    x0, 0(ra)



# ===========================================================================
# RESOLVER DISPARO
#
# return:
# 0 miss
# 1 hit
# 2 sunk
# 3 repeated
# ===========================================================================

resolve_shot:

    slli    t0, a1, 3

    add     t0, t0, a2

    slli    t0, t0, 2

    add     t0, a0, t0


    lw      t1, 0(t0)


    beq     t1, x0, shot_miss


    li      t2, 3

    blt     t2, t1, shot_repeat


    mv      t3, t1


    addi    t4, t1, 4

    sw      t4, 0(t0)


    li      t4, 0



shot_scan_ship:

    li      t5, 64

    beq     t4, t5, shot_sunk


    slli    t5, t4, 2

    add     t5, a0, t5


    lw      t6, 0(t5)


    beq     t6, t3, shot_hit


    addi    t4, t4, 1


    jal     x0, shot_scan_ship



shot_hit:

    li      a0, 1

    jalr    x0, 0(ra)



shot_sunk:

    li      a0, 2

    jalr    x0, 0(ra)



shot_miss:

    li      t2, 4

    sw      t2, 0(t0)


    li      a0, 0

    jalr    x0, 0(ra)



shot_repeat:

    li      a0, 3

    jalr    x0, 0(ra)



# ===========================================================================
# VGA - TABLEROS
# ===========================================================================

render_boards:

    addi    sp, sp, -12


    sw      ra, 8(sp)

    sw      s8, 4(sp)

    sw      s9, 0(sp)


    li      s8, 0



render_row:

    li      s9, 0



render_col:

    slli    t2, s8, 3

    add     t2, t2, s9

    slli    t3, t2, 2


    # LOCAL

    add     t4, s0, t3

    lw      t5, 0(t4)


    beq     t5, x0, local_tile_ready


    li      t0, 4

    beq     t5, t0, local_tile_miss


    li      t0, 5

    bge     t5, t0, local_tile_hit


    li      t5, 1

    jal     x0, local_tile_ready



local_tile_hit:

    li      t5, 2

    jal     x0, local_tile_ready



local_tile_miss:

    li      t5, 3



local_tile_ready:

    addi    t6, s8, 2


    slli    a0, t6, 4

    slli    t0, t6, 2

    add     a0, a0, t0


    addi    a0, a0, 1

    add     a0, a0, s9


    mv      a1, t5

    jal     ra, vga_write


    # REMOTE

    add     t4, s1, t3

    lw      t5, 0(t4)


    beq     t5, x0, remote_tile_ready


    li      t0, 4

    beq     t5, t0, remote_tile_miss


    li      t0, 5

    bge     t5, t0, remote_tile_hit


    # barcos intactos del rival ocultos

    li      t5, 0

    jal     x0, remote_tile_ready



remote_tile_hit:

    li      t5, 2

    jal     x0, remote_tile_ready



remote_tile_miss:

    li      t5, 3



remote_tile_ready:

    addi    t6, s8, 2


    slli    a0, t6, 4

    slli    t0, t6, 2

    add     a0, a0, t0


    addi    a0, a0, 11

    add     a0, a0, s9


    mv      a1, t5

    jal     ra, vga_write


    addi    s9, s9, 1


    li      t2, 8

    bne     s9, t2, render_col


    addi    s8, s8, 1


    li      t2, 8

    bne     s8, t2, render_row


    lw      s9, 0(sp)

    lw      s8, 4(sp)

    lw      ra, 8(sp)


    addi    sp, sp, 12


    jalr    x0, 0(ra)



# ===========================================================================
# HUD INICIAL
#
# Fila VGA 0:
#
# J1   barco barco barco
# J2   barco barco barco
#
# bits [2:0] = color
# bits [7:3] = glifo
#
# Glifos:
# 1 = J
# 2 = 1
# 3 = 2
# 4 = mini barco
# ===========================================================================

render_hud_initial:

    addi    sp, sp, -4
    sw      ra, 0(sp)


    # J1 BLANCO

    li      a0, 1
    li      a1, 11
    jal     ra, vga_write

    li      a0, 2
    li      a1, 19
    jal     ra, vga_write


    # J2 BLANCO

    li      a0, 11
    li      a1, 11
    jal     ra, vga_write

    li      a0, 12
    li      a1, 27
    jal     ra, vga_write


    # Barcos J1

    li      a1, 33

    li      a0, 4
    jal     ra, vga_write

    li      a0, 5
    jal     ra, vga_write

    li      a0, 6
    jal     ra, vga_write


    # Barcos J2

    li      a0, 14
    jal     ra, vga_write

    li      a0, 15
    jal     ra, vga_write

    li      a0, 16
    jal     ra, vga_write


    lw      ra, 0(sp)
    addi    sp, sp, 4

    jalr    x0, 0(ra)



# ===========================================================================
# HUD BATALLA
#
# s10 = barcos de J2 hundidos por J1
# s11 = barcos de J1 hundidos por J2
# ===========================================================================

render_hud_battle:

    addi    sp, sp, -4
    sw      ra, 0(sp)


    # NOMBRES BLANCOS

    li      a0, 1
    li      a1, 11
    jal     ra, vga_write

    li      a0, 2
    li      a1, 19
    jal     ra, vga_write


    li      a0, 11
    li      a1, 11
    jal     ra, vga_write

    li      a0, 12
    li      a1, 27
    jal     ra, vga_write


    # Limpiar los iconos anteriores

    li      a1, 0

    li      a0, 4
    jal     ra, vga_write

    li      a0, 5
    jal     ra, vga_write

    li      a0, 6
    jal     ra, vga_write


    li      a0, 14
    jal     ra, vga_write

    li      a0, 15
    jal     ra, vga_write

    li      a0, 16
    jal     ra, vga_write


    # =======================================================
    # BARCOS RESTANTES J1
    # s11 = barcos de J1 hundidos
    # =======================================================

    li      t5, 3
    beq     s11, t5, hud_j2_remaining


    # Uno o mas vivos

    li      a0, 4
    li      a1, 33
    jal     ra, vga_write


    li      t5, 2
    beq     s11, t5, hud_j2_remaining


    # Dos o mas vivos

    li      a0, 5
    li      a1, 33
    jal     ra, vga_write


    li      t5, 1
    beq     s11, t5, hud_j2_remaining


    # Los tres vivos

    li      a0, 6
    li      a1, 33
    jal     ra, vga_write



hud_j2_remaining:

    # =======================================================
    # BARCOS RESTANTES J2
    # s10 = barcos de J2 hundidos
    # =======================================================

    li      t5, 3
    beq     s10, t5, hud_battle_done


    li      a0, 14
    li      a1, 33
    jal     ra, vga_write


    li      t5, 2
    beq     s10, t5, hud_battle_done


    li      a0, 15
    li      a1, 33
    jal     ra, vga_write


    li      t5, 1
    beq     s10, t5, hud_battle_done


    li      a0, 16
    li      a1, 33
    jal     ra, vga_write



hud_battle_done:

    lw      ra, 0(sp)
    addi    sp, sp, 4

    jalr    x0, 0(ra)



# ===========================================================================
# CURSOR LOCAL
# ===========================================================================

render_local_cursor:

    addi    sp, sp, -4

    sw      ra, 0(sp)


    jal     ra, render_boards


    addi    t0, s8, 2


    slli    a0, t0, 4

    slli    t1, t0, 2

    add     a0, a0, t1


    addi    t1, s9, 1

    add     a0, a0, t1


    li      a1, 5


    beq     s11, x0, local_cursor_write


    li      a1, 6



local_cursor_write:

    jal     ra, vga_write


    lw      ra, 0(sp)

    addi    sp, sp, 4


    jalr    x0, 0(ra)



# ===========================================================================
# CURSOR DISPARO
# ===========================================================================

render_target_cursor:

    addi    sp, sp, -4

    sw      ra, 0(sp)


    jal     ra, render_boards


    addi    t0, s8, 2


    slli    a0, t0, 4

    slli    t1, t0, 2

    add     a0, a0, t1


    addi    t1, s9, 11

    add     a0, a0, t1


    li      a1, 5


    jal     ra, vga_write


    lw      ra, 0(sp)

    addi    sp, sp, 4


    jalr    x0, 0(ra)



# ===========================================================================
# VGA WRITE
# ===========================================================================

vga_write:

    slli    t0, a0, 2

    add     t0, t0, tp


    sw      a1, 0(t0)


    jalr    x0, 0(ra)



# ===========================================================================
# VGA GAME OVER
#
# a0:
# 0 = gana J1
# 1 = gana J2
#
# Ganador  -> negro
# Perdedor -> rojo
#
# Los tableros y barcos restantes permanecen visibles.
# ===========================================================================

render_game_over:

    addi    sp, sp, -8

    sw      ra, 4(sp)
    sw      s8, 0(sp)

    mv      s8, a0


    # Mantener estado final

    jal     ra, render_boards
    jal     ra, render_hud_battle


    # J1 ganador?

    beq     s8, x0, game_over_j1_winner



# ===========================================================================
# J2 GANA
# ===========================================================================

game_over_j2_winner:

    # J1 ROJO

    li      a0, 1
    li      a1, 10
    jal     ra, vga_write

    li      a0, 2
    li      a1, 18
    jal     ra, vga_write


    # J2 NEGRO

    li      a0, 11
    li      a1, 15
    jal     ra, vga_write

    li      a0, 12
    li      a1, 31
    jal     ra, vga_write


    jal     x0, game_over_done



# ===========================================================================
# J1 GANA
# ===========================================================================

game_over_j1_winner:

    # J1 NEGRO

    li      a0, 1
    li      a1, 15
    jal     ra, vga_write

    li      a0, 2
    li      a1, 23
    jal     ra, vga_write


    # J2 ROJO

    li      a0, 11
    li      a1, 10
    jal     ra, vga_write

    li      a0, 12
    li      a1, 26
    jal     ra, vga_write



game_over_done:

    lw      s8, 0(sp)
    lw      ra, 4(sp)

    addi    sp, sp, 8

    jalr    x0, 0(ra)



# ===========================================================================
# UART TX BYTE
# ===========================================================================

uart_send_byte:

uart_tx_wait:

    lw      t1, UART_CTRL(gp)

    andi    t1, t1, 1


    bne     t1, x0, uart_tx_wait


    sw      a0, UART_TX(gp)


    jalr    x0, 0(ra)



# ===========================================================================
# UART SEND FRAME
# ===========================================================================

uart_send_frame:

    addi    sp, sp, -36


    sw      ra, 32(sp)

    sw      s8, 28(sp)

    sw      s9, 24(sp)

    sw      s10, 20(sp)

    sw      s11, 16(sp)


    mv      s8, a0

    mv      s9, a1

    mv      s10, a2


    xor     s11, s8, s10


    # STX

    li      a0, STX

    jal     ra, uart_send_byte


    # CMD

    mv      a0, s8

    jal     ra, uart_send_byte


    # LEN

    mv      a0, s10

    jal     ra, uart_send_byte


    li      t2, 0



send_payload_loop:

    beq     t2, s10, send_payload_done


    add     t4, s9, t2

    lbu     a0, 0(t4)


    xor     s11, s11, a0


    mv      s8, t2


    jal     ra, uart_send_byte


    mv      t2, s8


    addi    t2, t2, 1


    jal     x0, send_payload_loop



send_payload_done:

    mv      a0, s11

    jal     ra, uart_send_byte


    li      a0, ETX

    jal     ra, uart_send_byte


    lw      s11, 16(sp)

    lw      s10, 20(sp)

    lw      s9, 24(sp)

    lw      s8, 28(sp)

    lw      ra, 32(sp)


    addi    sp, sp, 36


    jalr    x0, 0(ra)



# ===========================================================================
# UART GET BYTE
# ===========================================================================

uart_get_byte:

uart_rx_wait:

    lw      t1, UART_CTRL(gp)

    andi    t1, t1, 2


    beq     t1, x0, uart_rx_wait


    lw      a0, UART_RX(gp)

    andi    a0, a0, 0xff


    jalr    x0, 0(ra)



# ===========================================================================
# UART RECEIVE FRAME
# ===========================================================================

uart_recv_frame:

    addi    sp, sp, -20


    sw      ra, 16(sp)

    sw      s8, 12(sp)

    sw      s9, 8(sp)

    sw      s10, 4(sp)

    sw      s11, 0(sp)



recv_stx:

    jal     ra, uart_get_byte


    li      t0, STX

    bne     a0, t0, recv_stx


    jal     ra, uart_get_byte

    mv      s8, a0


    jal     ra, uart_get_byte

    mv      s9, a0


    li      t3, 32

    blt     t3, s9, recv_stx


    li      s10, 0

    li      t5, FRAME_BUF


    xor     s11, s8, s9



recv_payload:

    beq     s10, s9, recv_checksum


    jal     ra, uart_get_byte


    sb      a0, 0(t5)


    xor     s11, s11, a0


    addi    t5, t5, 1

    addi    s10, s10, 1


    jal     x0, recv_payload



recv_checksum:

    jal     ra, uart_get_byte


    bne     a0, s11, recv_stx


    jal     ra, uart_get_byte


    li      t0, ETX

    bne     a0, t0, recv_stx


    mv      a0, s8

    mv      a1, s9


    lw      s11, 0(sp)

    lw      s10, 4(sp)

    lw      s9, 8(sp)

    lw      s8, 12(sp)

    lw      ra, 16(sp)


    addi    sp, sp, 20


    jalr    x0, 0(ra)



# ===========================================================================
# EVENT TURN
# ===========================================================================

send_turn:

    li      t0, FRAME_BUF


    sb      a0, 0(t0)


    li      a0, EVT_TURN

    li      a1, FRAME_BUF

    li      a2, 1


    jal     x0, uart_send_frame



# ===========================================================================
# EVENT SHOT RESULT
# ===========================================================================

send_shot_result:

    li      t0, FRAME_BUF


    sb      a0, 0(t0)

    sb      a1, 1(t0)

    sb      a2, 2(t0)


    li      a0, EVT_SHOT_RESULT

    li      a1, FRAME_BUF

    li      a2, 3


    jal     x0, uart_send_frame



# ===========================================================================
# EVENT INCOMING
# ===========================================================================

send_incoming:

    li      t0, FRAME_BUF


    sb      a0, 0(t0)

    sb      a1, 1(t0)

    sb      a2, 2(t0)


    li      a0, EVT_INCOMING

    li      a1, FRAME_BUF

    li      a2, 3


    jal     x0, uart_send_frame



# ===========================================================================
# BOTONES
# ===========================================================================

read_buttons:

    lw      a0, GPIO_OFF(gp)

    andi    a0, a0, 0x7f



wait_release:

    lw      t1, GPIO_OFF(gp)

    andi    t1, t1, 0x3f


    bne     t1, x0, wait_release


    jalr    x0, 0(ra)



# ===========================================================================
# LED
# ===========================================================================

led_write:

    sw      a0, LED_OFF(gp)

    jalr    x0, 0(ra)



# ===========================================================================
# DISPLAY
# ===========================================================================

display_write:

    sw      a0, DISPLAY_OFF(gp)

    jalr    x0, 0(ra)



# ===========================================================================
# SCORE DISPLAY
# ===========================================================================

update_score_display:

    # J1

    mv      t0, s6

    li      t1, 0



score_j1_loop:

    li      t2, 10


    blt     t0, t2, score_j1_done


    addi    t0, t0, -10

    addi    t1, t1, 1


    jal     x0, score_j1_loop



score_j1_done:

    slli    t3, t1, 12

    slli    t4, t0, 8

    or      t3, t3, t4


    # J2

    mv      t0, s7

    li      t1, 0



score_j2_loop:

    li      t2, 10


    blt     t0, t2, score_j2_done


    addi    t0, t0, -10

    addi    t1, t1, 1


    jal     x0, score_j2_loop



score_j2_done:

    slli    t4, t1, 4

    or      t3, t3, t4


    or      t3, t3, t0


    mv      a0, t3


    jal     x0, display_write



# ===========================================================================
# BUZZER
# ===========================================================================

buzzer_write:

    sw      a0, BUZZER_OFF(gp)

    jalr    x0, 0(ra)



# ===========================================================================
# GAME OVER
#
# a0:
# 0 J1
# 1 J2
# ===========================================================================

finish_game:

    # Guardar winner

    li      t0, FRAME_BUF

    sb      a0, 0(t0)


    beq     a0, x0, winner_local


    # J2 gana

    li      t3, 99

    bge     s7, t3, winner_remote_max


    addi    s7, s7, 1



winner_remote_max:

    jal     x0, winner_common



winner_local:

    # J1 gana

    li      t3, 99

    bge     s6, t3, winner_local_max


    addi    s6, s6, 1



winner_local_max:



winner_common:

    # Persistir J1

    li      t0, P1_WINS

    sw      s6, 0(t0)


    # Persistir J2

    li      t0, P2_WINS

    sw      s7, 0(t0)


    # LED game over

    li      a0, 2

    jal     ra, led_write


    # Buzzer victoria

    li      a0, 5

    jal     ra, buzzer_write


    # Display

    jal     ra, update_score_display


    # VGA ganador

    li      t0, FRAME_BUF

    lbu     a0, 0(t0)

    jal     ra, render_game_over


    # -------------------------------------------------------
    # GAME_OVER
    #
    # [0] winner
    # [1] shots MSB
    # [2] shots LSB
    # [3] ships sunk by J1
    # [4] ships sunk by J2
    # -------------------------------------------------------

    li      t2, FRAME_BUF


    srli    t1, s5, 8

    sb      t1, 1(t2)


    andi    t1, s5, 0xff

    sb      t1, 2(t2)


    sb      s10, 3(t2)


    sb      s11, 4(t2)


    li      a0, EVT_GAME_OVER

    li      a1, FRAME_BUF

    li      a2, 5


    jal     ra, uart_send_frame



# ===========================================================================
# ESPERAR RESET FISICO
# ===========================================================================

finish_wait_reset:

    jal     x0, finish_wait_reset