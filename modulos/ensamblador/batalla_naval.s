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
# Perifericos: offsets desde gp = 0x00010000
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

.eqv FRAME_BUF,   0x00002E00
.eqv P1_WINS,     0x00002F00
.eqv P2_WINS,     0x00002F04


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


# Codigos de buzzer:
#   1 = impacto
#   2 = fallo
#   3 = hundido
#   4 = colocacion invalida
#   5 = victoria


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

    li      s2, 0                  # turno: 0 local, 1 remoto
    li      s3, 0                  # impactos sobre tablero local
    li      s4, 0                  # impactos sobre tablero remoto
    li      s5, 0                  # disparos validos totales


    # Recuperar marcador persistente

    li      t0, P1_WINS
    lw      s6, 0(t0)

    li      t0, P2_WINS
    lw      s7, 0(t0)


    # Limpiar tablero local

    mv      a0, s0
    li      a1, 64
    jal     ra, clear_board


    # Limpiar tablero remoto

    mv      a0, s1
    li      a1, 64
    jal     ra, clear_board


    # Limpiar VGA

    jal     ra, clear_vga


    # Fase de colocacion

    li      a0, 0
    jal     ra, led_write

    jal     ra, update_score_display
    jal     ra, render_boards


    # Avisar inicio de colocacion

    li      a0, EVT_PLACE_START
    li      a1, FRAME_BUF
    li      a2, 0
    jal     ra, uart_send_frame


    # Flota local

    jal     ra, place_local_fleet


    # Flota remota

    jal     ra, receive_remote_fleet


    # -------------------------------------------------------
    # Contadores de barcos hundidos
    #
    # s10 = barcos hundidos por J1
    # s11 = barcos hundidos por J2
    # -------------------------------------------------------

    li      s10, 0
    li      s11, 0


    # Fase de batalla

    li      a0, 1
    jal     ra, led_write


    # Avisar inicio de batalla

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
# COLOCACION LOCAL
# ===========================================================================

place_local_fleet:

    addi    sp, sp, -16

    sw      ra, 12(sp)
    sw      s8, 8(sp)
    sw      s9, 4(sp)
    sw      s10, 0(sp)


    li      s10, 0                 # barco actual



local_ship_loop:

    li      s8, 0                  # fila
    li      s9, 0                  # columna
    li      s11, 0                 # orientacion



local_input_loop:

    jal     ra, read_buttons

    mv      t0, a0


    # Arriba

    andi    t1, t0, BTN_UP

    beq     t1, x0, check_down
    beq     s8, x0, local_input_loop

    addi    s8, s8, -1

    jal     x0, local_input_loop



check_down:

    andi    t1, t0, BTN_DOWN

    beq     t1, x0, check_left

    li      t2, 7

    beq     s8, t2, local_input_loop

    addi    s8, s8, 1

    jal     x0, local_input_loop



check_left:

    andi    t1, t0, BTN_LEFT

    beq     t1, x0, check_right

    beq     s9, x0, local_input_loop

    addi    s9, s9, -1

    jal     x0, local_input_loop



check_right:

    andi    t1, t0, BTN_RIGHT

    beq     t1, x0, check_select

    li      t2, 7

    beq     s9, t2, local_input_loop

    addi    s9, s9, 1

    jal     x0, local_input_loop



check_select:

    andi    t1, t0, BTN_SELECT

    beq     t1, x0, check_ok

    xori    s11, s11, 1

    jal     x0, local_input_loop



check_ok:

    andi    t1, t0, BTN_OK

    beq     t1, x0, local_input_loop


    # Validar colocacion

    mv      a0, s0
    mv      a1, s8
    mv      a2, s9
    mv      a3, s11
    mv      a4, s10

    jal     ra, validate_place

    bne     a0, x0, local_invalid


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

    bne     s10, t0, local_ship_loop


    # Restaurar

    lw      s10, 0(sp)
    lw      s9, 4(sp)
    lw      s8, 8(sp)
    lw      ra, 12(sp)

    addi    sp, sp, 16

    jalr    x0, 0(ra)



local_invalid:

    li      a0, 4

    jal     ra, buzzer_write

    jal     x0, local_input_loop



# ===========================================================================
# COLOCACION REMOTA
# ===========================================================================

receive_remote_fleet:

    addi    sp, sp, -4

    sw      ra, 0(sp)

    li      s10, 0



remote_ship_loop:

    jal     ra, uart_recv_frame


    # CMD_PLACE

    li      t0, CMD_PLACE

    bne     a0, t0, remote_ship_loop


    # Payload = 4 bytes

    li      t0, 4

    bne     a1, t0, remote_ship_loop


    # FRAME_BUF:
    # [0] ID
    # [1] fila
    # [2] columna
    # [3] orientacion

    li      t5, FRAME_BUF

    lbu     t1, 0(t5)
    lbu     t2, 1(t5)
    lbu     t3, 2(t5)
    lbu     t4, 3(t5)


    # Validar

    mv      a0, s1
    mv      a1, t2
    mv      a2, t3
    mv      a3, t4
    mv      a4, t1

    jal     ra, validate_place

    bne     a0, x0, remote_invalid


    # Recuperar datos porque validate_place usa temporales

    li      t5, FRAME_BUF

    lbu     t1, 0(t5)
    lbu     t2, 1(t5)
    lbu     t3, 2(t5)
    lbu     t4, 3(t5)


    # Escribir barco

    mv      a0, s1
    mv      a1, t2
    mv      a2, t3
    mv      a3, t4
    mv      a4, t1

    jal     ra, write_ship


    # Confirmacion

    li      a0, EVT_PLACE_OK
    li      a1, FRAME_BUF
    li      a2, 1

    jal     ra, uart_send_frame


    addi    s10, s10, 1

    li      t0, 3

    bne     s10, t0, remote_ship_loop


    lw      ra, 0(sp)

    addi    sp, sp, 4

    jalr    x0, 0(ra)



remote_invalid:

    # validate_place:
    # 1 = traslape
    # 2 = fuera de tablero
    #
    # Protocolo:
    # 0 = traslape
    # 1 = fuera de tablero

    addi    a0, a0, -1


    li      t5, FRAME_BUF

    sb      a0, 1(t5)


    li      a0, EVT_PLACE_BAD
    li      a1, FRAME_BUF
    li      a2, 2

    jal     ra, uart_send_frame

    jal     x0, remote_ship_loop



# ===========================================================================
# TURNO LOCAL
# ===========================================================================

local_turn:

    li      s8, 0                  # fila objetivo
    li      s9, 0                  # columna objetivo



local_fire_input:

    jal     ra, read_buttons

    mv      t0, a0


    # Arriba

    andi    t1, t0, BTN_UP

    beq     t1, x0, lf_down
    beq     s8, x0, local_fire_input

    addi    s8, s8, -1

    jal     x0, local_fire_input



lf_down:

    andi    t1, t0, BTN_DOWN

    beq     t1, x0, lf_left

    li      t2, 7

    beq     s8, t2, local_fire_input

    addi    s8, s8, 1

    jal     x0, local_fire_input



lf_left:

    andi    t1, t0, BTN_LEFT

    beq     t1, x0, lf_right

    beq     s9, x0, local_fire_input

    addi    s9, s9, -1

    jal     x0, local_fire_input



lf_right:

    andi    t1, t0, BTN_RIGHT

    beq     t1, x0, lf_ok

    li      t2, 7

    beq     s9, t2, local_fire_input

    addi    s9, s9, 1

    jal     x0, local_fire_input



lf_ok:

    andi    t1, t0, BTN_OK

    beq     t1, x0, local_fire_input


    # Resolver disparo sobre tablero remoto

    mv      a0, s1
    mv      a1, s8
    mv      a2, s9

    jal     ra, resolve_shot


    # Casilla repetida

    li      t0, 3

    beq     a0, t0, local_fire_input


    mv      t6, a0


    # Disparo valido

    addi    s5, s5, 1


    # -------------------------------------------------------
    # Resultado 1 o 2 = nueva casilla impactada
    # -------------------------------------------------------

    beq     t6, x0, local_fire_sound

    addi    s4, s4, 1


    # -------------------------------------------------------
    # Resultado 2 = barco hundido por J1
    # -------------------------------------------------------

    li      t0, 2

    bne     t6, t0, local_fire_sound

    addi    s10, s10, 1



local_fire_sound:

    # Fallo

    li      a0, 2

    beq     t6, x0, local_buz


    # Impacto

    li      a0, 1


    # Hundido

    li      t0, 2

    bne     t6, t0, local_buz

    li      a0, 3



local_buz:

    jal     ra, buzzer_write


    # J1 dispara sobre J2:
    # para la PC corresponde a EVT_INCOMING

    mv      a0, s8
    mv      a1, s9
    mv      a2, t6

    jal     ra, send_incoming


    jal     ra, render_boards


    # -------------------------------------------------------
    # Victoria cuando J1 ha hundido los 3 barcos
    # -------------------------------------------------------

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


    # CMD_FIRE

    li      t0, CMD_FIRE

    bne     a0, t0, remote_turn


    # Payload fila + columna

    li      t0, 2

    bne     a1, t0, remote_turn


    li      t5, FRAME_BUF

    lbu     t1, 0(t5)
    lbu     t2, 1(t5)


    # Validar rango

    li      t0, 7

    bgt     t1, t0, remote_turn
    bgt     t2, t0, remote_turn


    # Resolver disparo

    mv      a0, s0
    mv      a1, t1
    mv      a2, t2

    jal     ra, resolve_shot


    # Repetido

    li      t0, 3

    beq     a0, t0, remote_turn


    mv      t6, a0


    # Disparo valido

    addi    s5, s5, 1


    # -------------------------------------------------------
    # Resultado 1 o 2 = impacto
    # -------------------------------------------------------

    beq     t6, x0, remote_sound

    addi    s3, s3, 1


    # -------------------------------------------------------
    # Resultado 2 = barco hundido por J2
    # -------------------------------------------------------

    li      t0, 2

    bne     t6, t0, remote_sound

    addi    s11, s11, 1



remote_sound:

    # Fallo

    li      a0, 2

    beq     t6, x0, remote_buz


    # Impacto

    li      a0, 1


    # Hundido

    li      t0, 2

    bne     t6, t0, remote_buz

    li      a0, 3



remote_buz:

    jal     ra, buzzer_write



remote_result:

    # Recuperar coordenadas originales

    li      t5, FRAME_BUF

    lbu     t1, 0(t5)
    lbu     t2, 1(t5)


    mv      a0, t1
    mv      a1, t2
    mv      a2, t6


    # Resultado del disparo propio de J2

    jal     ra, send_shot_result


    jal     ra, render_boards


    # -------------------------------------------------------
    # Victoria cuando J2 ha hundido los 3 barcos
    # -------------------------------------------------------

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

# a0 = direccion inicial
# a1 = numero de palabras

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



# ---------------------------------------------------------------------------
# Limpiar VGA
# 20 x 15 = 300 tiles
# ---------------------------------------------------------------------------

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



# ---------------------------------------------------------------------------
# Validar colocacion
#
# a0 = tablero
# a1 = fila
# a2 = columna
# a3 = orientacion
# a4 = ID
#
# Retorna:
#   a0 = 0 valido
#   a0 = 1 traslape
#   a0 = 2 fuera de tablero / parametro invalido
# ---------------------------------------------------------------------------

validate_place:

    # Fila <= 7

    li      t1, 7

    blt     t1, a1, place_out


    # Columna <= 7

    blt     t1, a2, place_out


    # Orientacion <= 1

    li      t1, 1

    blt     t1, a3, place_out


    # ID <= 2

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

    # indice = fila*8 + columna

    slli    t4, t2, 3

    add     t4, t4, t3


    # palabra

    slli    t4, t4, 2

    add     t4, a0, t4


    lw      t5, 0(t4)


    # Debe estar vacia

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



# ---------------------------------------------------------------------------
# Escribir barco
#
# a0 = tablero
# a1 = fila
# a2 = columna
# a3 = orientacion
# a4 = ID
#
# Valor interno:
#
#   barco 0 -> 1
#   barco 1 -> 2
#   barco 2 -> 3
# ---------------------------------------------------------------------------

write_ship:

    # Barco 0 = longitud 4

    li      t0, 4

    beq     a4, x0, write_length_done


    # Barco 1 = longitud 3

    li      t0, 3

    li      t1, 1

    beq     a4, t1, write_length_done


    # Barco 2 = longitud 2

    li      t0, 2



write_length_done:

    li      t1, 0



write_ship_loop:

    beq     t1, t0, write_ship_done


    beq     a3, x0, write_horizontal


    # Vertical

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


    # ID interno = ID + 1

    addi    t5, a4, 1

    sw      t5, 0(t4)


    addi    t1, t1, 1

    jal     x0, write_ship_loop



write_ship_done:

    jalr    x0, 0(ra)



# ---------------------------------------------------------------------------
# Resolver disparo
#
# a0 = tablero
# a1 = fila
# a2 = columna
#
# Representacion:
#
#   0 = agua
#
#   1 = barco 0 intacto
#   2 = barco 1 intacto
#   3 = barco 2 intacto
#
#   4 = fallo
#
#   5 = impacto barco 0
#   6 = impacto barco 1
#   7 = impacto barco 2
#
# Retorna:
#
#   0 = fallo
#   1 = impacto
#   2 = barco hundido
#   3 = casilla ya disparada
# ---------------------------------------------------------------------------

resolve_shot:

    # Direccion de casilla

    slli    t0, a1, 3

    add     t0, t0, a2

    slli    t0, t0, 2

    add     t0, a0, t0


    lw      t1, 0(t0)


    # Agua

    beq     t1, x0, shot_miss


    # 4-7 = casilla ya disparada

    li      t2, 3

    blt     t2, t1, shot_repeat


    # -------------------------------------------------------
    # t1 = ID interno del barco:
    # 1, 2 o 3
    # -------------------------------------------------------

    mv      t3, t1


    # -------------------------------------------------------
    # Marcar impacto:
    #
    # 1 -> 5
    # 2 -> 6
    # 3 -> 7
    # -------------------------------------------------------

    addi    t4, t1, 4

    sw      t4, 0(t0)


    # -------------------------------------------------------
    # Buscar partes intactas del mismo barco
    # -------------------------------------------------------

    li      t4, 0



shot_scan_ship:

    li      t5, 64

    beq     t4, t5, shot_sunk


    slli    t5, t4, 2

    add     t5, a0, t5


    lw      t6, 0(t5)


    # Si queda una parte intacta del mismo barco

    beq     t6, t3, shot_hit


    addi    t4, t4, 1

    jal     x0, shot_scan_ship



# -----------------------------------------------------------
# Impacto, pero no hundido
# -----------------------------------------------------------

shot_hit:

    li      a0, 1

    jalr    x0, 0(ra)



# -----------------------------------------------------------
# Barco hundido
# -----------------------------------------------------------

shot_sunk:

    li      a0, 2

    jalr    x0, 0(ra)



# -----------------------------------------------------------
# Fallo
# -----------------------------------------------------------

shot_miss:

    li      t2, 4

    sw      t2, 0(t0)

    li      a0, 0

    jalr    x0, 0(ra)



# -----------------------------------------------------------
# Disparo repetido
# -----------------------------------------------------------

shot_repeat:

    li      a0, 3

    jalr    x0, 0(ra)



# ===========================================================================
# VGA
#
# Tiles enviados al VGA:
#
#   0 = agua
#   1 = barco
#   2 = impacto
#   3 = fallo
#
# Los barcos remotos intactos se ocultan.
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

    # indice tablero = fila*8 + columna

    slli    t2, s8, 3

    add     t2, t2, s9

    slli    t3, t2, 2


    # =======================================================
    # TABLERO LOCAL
    # =======================================================

    add     t4, s0, t3

    lw      t5, 0(t4)


    # -------------------------------------------------------
    # Traducir valor interno -> tile VGA
    # -------------------------------------------------------

    # Agua

    beq     t5, x0, local_tile_ready


    # Fallo

    li      t0, 4

    beq     t5, t0, local_tile_miss


    # Impacto

    li      t0, 5

    bge     t5, t0, local_tile_hit


    # Barco intacto 1-3

    li      t5, 1

    jal     x0, local_tile_ready



local_tile_hit:

    li      t5, 2

    jal     x0, local_tile_ready



local_tile_miss:

    li      t5, 3



local_tile_ready:

    # fila VGA = fila + 2

    addi    t6, s8, 2


    # fila * 20

    slli    a0, t6, 4

    slli    t0, t6, 2

    add     a0, a0, t0


    # Tablero local empieza en columna 1

    addi    a0, a0, 1

    add     a0, a0, s9


    mv      a1, t5

    jal     ra, vga_write


    # =======================================================
    # TABLERO REMOTO
    # =======================================================

    add     t4, s1, t3

    lw      t5, 0(t4)


    # Agua

    beq     t5, x0, remote_tile_ready


    # Fallo

    li      t0, 4

    beq     t5, t0, remote_tile_miss


    # Impacto

    li      t0, 5

    bge     t5, t0, remote_tile_hit


    # -------------------------------------------------------
    # 1-3 = barco remoto intacto
    # Se oculta como agua
    # -------------------------------------------------------

    li      t5, 0

    jal     x0, remote_tile_ready



remote_tile_hit:

    li      t5, 2

    jal     x0, remote_tile_ready



remote_tile_miss:

    li      t5, 3



remote_tile_ready:

    addi    t6, s8, 2


    # fila * 20

    slli    a0, t6, 4

    slli    t0, t6, 2

    add     a0, a0, t0


    # Tablero remoto inicia en columna 11

    addi    a0, a0, 11

    add     a0, a0, s9


    mv      a1, t5

    jal     ra, vga_write


    # Siguiente columna

    addi    s9, s9, 1

    li      t2, 8

    bne     s9, t2, render_col


    # Siguiente fila

    addi    s8, s8, 1

    li      t2, 8

    bne     s8, t2, render_row


    # Restaurar

    lw      s9, 0(sp)
    lw      s8, 4(sp)
    lw      ra, 8(sp)

    addi    sp, sp, 12

    jalr    x0, 0(ra)



# ---------------------------------------------------------------------------
# Cursor de colocacion local
# ---------------------------------------------------------------------------

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



# ---------------------------------------------------------------------------
# Cursor de disparo
# ---------------------------------------------------------------------------

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



# ---------------------------------------------------------------------------
# Escribir tile VGA
#
# a0 = indice de casilla
# a1 = valor
# ---------------------------------------------------------------------------

vga_write:

    slli    t0, a0, 2

    add     t0, t0, tp

    sw      a1, 0(t0)

    jalr    x0, 0(ra)



# ===========================================================================
# UART
# ===========================================================================

uart_send_byte:

uart_tx_wait:

    lw      t1, UART_CTRL(gp)

    andi    t1, t1, 1

    bne     t1, x0, uart_tx_wait


    sw      a0, UART_TX(gp)

    jalr    x0, 0(ra)



# ---------------------------------------------------------------------------
# Enviar trama
#
# a0 = comando
# a1 = payload
# a2 = longitud
#
# Payload almacenado en bytes consecutivos
# ---------------------------------------------------------------------------

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


    # checksum inicial = CMD XOR LEN

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


    # Payload

    li      t2, 0



send_payload_loop:

    beq     t2, s10, send_payload_done


    add     t4, s9, t2

    lbu     a0, 0(t4)


    xor     s11, s11, a0


    # Preservar indice

    mv      s8, t2

    jal     ra, uart_send_byte

    mv      t2, s8


    addi    t2, t2, 1

    jal     x0, send_payload_loop



send_payload_done:

    # Checksum

    mv      a0, s11

    jal     ra, uart_send_byte


    # ETX

    li      a0, ETX

    jal     ra, uart_send_byte


    # Restaurar

    lw      s11, 16(sp)
    lw      s10, 20(sp)
    lw      s9, 24(sp)
    lw      s8, 28(sp)
    lw      ra, 32(sp)

    addi    sp, sp, 36

    jalr    x0, 0(ra)



# ---------------------------------------------------------------------------
# Recibir byte
# ---------------------------------------------------------------------------

uart_get_byte:

uart_rx_wait:

    lw      t1, UART_CTRL(gp)

    andi    t1, t1, 2

    beq     t1, x0, uart_rx_wait


    lw      a0, UART_RX(gp)

    andi    a0, a0, 0xff

    jalr    x0, 0(ra)



# ---------------------------------------------------------------------------
# Recibir trama
#
# Retorna:
#   a0 = CMD
#   a1 = LEN
#
# Payload en FRAME_BUF como bytes consecutivos
# ---------------------------------------------------------------------------

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


    # CMD

    jal     ra, uart_get_byte

    mv      s8, a0


    # LEN

    jal     ra, uart_get_byte

    mv      s9, a0


    # Maximo 32 bytes

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
# EVENTOS UART
# ===========================================================================

# ---------------------------------------------------------------------------
# Turno
#
# a0:
#   0 J1
#   1 J2
# ---------------------------------------------------------------------------

send_turn:

    li      t0, FRAME_BUF

    sb      a0, 0(t0)


    li      a0, EVT_TURN
    li      a1, FRAME_BUF
    li      a2, 1

    jal     x0, uart_send_frame



# ---------------------------------------------------------------------------
# Resultado de disparo del J2
#
# a0 = fila
# a1 = columna
# a2:
#   0 fallo
#   1 impacto
#   2 hundido
# ---------------------------------------------------------------------------

send_shot_result:

    li      t0, FRAME_BUF


    sb      a0, 0(t0)

    sb      a1, 1(t0)

    sb      a2, 2(t0)


    li      a0, EVT_SHOT_RESULT
    li      a1, FRAME_BUF
    li      a2, 3

    jal     x0, uart_send_frame



# ---------------------------------------------------------------------------
# Disparo de J1 recibido por J2
#
# a0 = fila
# a1 = columna
# a2 = resultado
# ---------------------------------------------------------------------------

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
# ENTRADAS E INDICADORES
# ===========================================================================

read_buttons:

    lw      a0, GPIO_OFF(gp)

    andi    a0, a0, 0x7f


    # BTN_RST

    andi    t1, a0, 0x40

    beq     t1, x0, rb_no_reset


    # Reiniciar conservando score

    jal     x0, _start



rb_no_reset:

wait_release:

    lw      t1, GPIO_OFF(gp)

    andi    t1, t1, 0x3f

    bne     t1, x0, wait_release


    jalr    x0, 0(ra)



# ---------------------------------------------------------------------------
# LED
# ---------------------------------------------------------------------------

led_write:

    sw      a0, LED_OFF(gp)

    jalr    x0, 0(ra)



# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

display_write:

    sw      a0, DISPLAY_OFF(gp)

    jalr    x0, 0(ra)



# ---------------------------------------------------------------------------
# Marcador acumulado
#
# s6 = victorias J1
# s7 = victorias J2
#
# [J1 decenas][J1 unidades][J2 decenas][J2 unidades]
# ---------------------------------------------------------------------------

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



# ---------------------------------------------------------------------------
# Buzzer
# ---------------------------------------------------------------------------

buzzer_write:

    sw      a0, BUZZER_OFF(gp)

    jalr    x0, 0(ra)



# ===========================================================================
# FIN DE PARTIDA
#
# a0:
#   0 = ganador J1
#   1 = ganador J2
# ===========================================================================

finish_game:

    # Guardar ganador

    li      t0, FRAME_BUF

    sb      a0, 0(t0)


    # -------------------------------------------------------
    # Actualizar score
    # -------------------------------------------------------

    beq     a0, x0, winner_local


    # Gano J2

    li      t3, 99

    bge     s7, t3, winner_remote_max


    addi    s7, s7, 1



winner_remote_max:

    jal     x0, winner_common



winner_local:

    # Gano J1

    li      t3, 99

    bge     s6, t3, winner_local_max


    addi    s6, s6, 1



winner_local_max:



winner_common:

    # -------------------------------------------------------
    # Persistir score
    # -------------------------------------------------------

    li      t0, P1_WINS

    sw      s6, 0(t0)


    li      t0, P2_WINS

    sw      s7, 0(t0)


    # -------------------------------------------------------
    # Estado visual / sonoro
    # -------------------------------------------------------

    li      a0, 2

    jal     ra, led_write


    li      a0, 5

    jal     ra, buzzer_write


    jal     ra, update_score_display


    # -------------------------------------------------------
    # GAME_OVER
    #
    # [0] ganador
    # [1] disparos totales MSB
    # [2] disparos totales LSB
    # [3] barcos hundidos por J1
    # [4] barcos hundidos por J2
    # -------------------------------------------------------

    li      t2, FRAME_BUF


    # MSB disparos

    srli    t1, s5, 8

    sb      t1, 1(t2)


    # LSB disparos

    andi    t1, s5, 0xff

    sb      t1, 2(t2)


    # Barcos hundidos por J1

    sb      s10, 3(t2)


    # Barcos hundidos por J2

    sb      s11, 4(t2)


    li      a0, EVT_GAME_OVER
    li      a1, FRAME_BUF
    li      a2, 5

    jal     ra, uart_send_frame



# ---------------------------------------------------------------------------
# Esperar BTN_RST
#
# BTN_RST tambien esta conectado al reset del CPU en soc_top.
# ---------------------------------------------------------------------------

finish_wait_reset:

    jal     x0, finish_wait_reset