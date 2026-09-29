# Batalla Naval - firmware RV32I
#
# Ensamblado esperado: RV32I, sin extensiones M/C.
# El programa usa el mapa de memoria definido en el enunciado.
#
# Convencion de entradas GPIO (registro GPIO_BASE):
#   bit 6 BTN_RST, bit 5 arriba, bit 4 abajo, bit 3 izquierda,
#   bit 2 derecha, bit 1 seleccionar/orientacion, bit 0 confirmar.
#
# Estados de casilla: 0 agua, 1 barco propio, 2 impacto, 3 fallo.
# Tramas UART: STX(02) CMD LEN PAYLOAD CHECKSUM ETX(03).

.eqv RAM_BASE,       0x00002000
.eqv LOCAL_BOARD,     0x00002000
.eqv REMOTE_BOARD,    0x00002100
.eqv FRAME_BUF,       0x00002E00
.eqv P1_WINS,         0x00002F00
.eqv P2_WINS,         0x00002F04
.eqv STACK_TOP,       0x00002FFC

.eqv UART_BASE,       0x00010040
.eqv GPIO_BASE,       0x00010120
.eqv DISPLAY_BASE,    0x00010130
.eqv LED_BASE,        0x00010138
.eqv BUZZER_BASE,     0x00010140
.eqv VGA_BASE,        0x00011000

.eqv STX,             0x02
.eqv ETX,             0x03
.eqv CMD_PLACE,       0x01
.eqv CMD_FIRE,        0x02
.eqv EVT_PLACE_START, 0x80
.eqv EVT_PLACE_OK,    0x81
.eqv EVT_PLACE_BAD,   0x82
.eqv EVT_BATTLE_START,0x83
.eqv EVT_TURN,        0x84
.eqv EVT_SHOT_RESULT, 0x85
.eqv EVT_INCOMING,    0x86
.eqv EVT_GAME_OVER,   0x87

.eqv BTN_UP,          0x20
.eqv BTN_DOWN,        0x10
.eqv BTN_LEFT,        0x08
.eqv BTN_RIGHT,       0x04
.eqv BTN_SELECT,      0x02
.eqv BTN_OK,          0x01

.globl _start
.globl main

main:
_start:
    li      sp, STACK_TOP
    li      s0, LOCAL_BOARD       # tablero del Jugador 1
    li      s1, REMOTE_BOARD      # tablero conocido del Jugador 2
    li      s2, 0                  # turno: 0 local, 1 remoto
    li      s3, 0                  # impactos sobre tablero local
    li      s4, 0                  # impactos sobre tablero remoto
    li      s5, 0                  # disparos validos totales
    li      t0, P1_WINS
    lw      s6, 0(t0)              # victorias Jugador 1
    li      t0, P2_WINS
    lw      s7, 0(t0)              # victorias Jugador 2

    li      a0, LOCAL_BOARD
    li      a1, 64
    jal     ra, clear_board
    li      a0, REMOTE_BOARD
    li      a1, 64
    jal     ra, clear_board

    li      a0, 0
    jal     ra, led_write          # fase de colocacion
    li      a0, 0
    jal     ra, display_write
    jal     ra, render_boards

    li      a0, EVT_PLACE_START
    li      a1, FRAME_BUF
    li      a2, 0
    jal     ra, uart_send_frame

    # La colocacion local se hace con botones.
    jal     ra, place_local_fleet

    # La PC recibe y envia las tres colocaciones del Jugador 2.
    jal     ra, receive_remote_fleet

    li      a0, 1
    jal     ra, led_write          # fase de batalla
    li      a0, EVT_BATTLE_START
    li      a1, FRAME_BUF
    li      a2, 0
    jal     ra, uart_send_frame

    li      s2, 0
    li      a0, 0
    jal     ra, send_turn

battle_loop:
    beq     s2, x0, local_turn
    jal     x0, remote_turn

# ---------------------------------------------------------------------------
# Colocacion local y remota
# ---------------------------------------------------------------------------

place_local_fleet:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s8, 8(sp)
    sw      s9, 4(sp)
    sw      s10, 0(sp)
    li      s10, 0                 # barco actual: 0, 1, 2

local_ship_loop:
    li      s8, 0                  # fila del cursor
    li      s9, 0                  # columna del cursor
    li      s11, 0                 # 0 horizontal, 1 vertical

local_input_loop:
    jal     ra, read_buttons
    mv      t0, a0
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

    mv      a0, s0
    mv      a1, s8
    mv      a2, s9
    mv      a3, s11
    mv      a4, s10
    jal     ra, validate_place
    bne     a0, x0, local_invalid

    mv      a0, s0
    mv      a1, s8
    mv      a2, s9
    mv      a3, s11
    mv      a4, s10
    jal     ra, write_ship
    jal     ra, render_boards
    addi    s10, s10, 1
    li      t0, 3
    bne     s10, t0, local_ship_loop

    lw      s10, 0(sp)
    lw      s9, 4(sp)
    lw      s8, 8(sp)
    lw      ra, 12(sp)
    addi    sp, sp, 16
    jalr    x0, 0(ra)

local_invalid:
    li      a0, 4                  # sonido de colocacion invalida
    jal     ra, buzzer_write
    jal     x0, local_input_loop

receive_remote_fleet:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    li      s10, 0

remote_ship_loop:
    jal     ra, uart_recv_frame
    li      t0, CMD_PLACE
    bne     a0, t0, remote_ship_loop
    li      t0, 4
    bne     a1, t0, remote_ship_loop

    li      t5, FRAME_BUF
    lbu     t1, 0(t5)               # identificador
    lbu     t2, 1(t5)               # fila
    lbu     t3, 2(t5)               # columna
    lbu     t4, 3(t5)               # orientacion
    mv      a0, s1
    mv      a1, t2
    mv      a2, t3
    mv      a3, t4
    mv      a4, t1
    jal     ra, validate_place
    bne     a0, x0, remote_invalid

    mv      a0, s1
    mv      a1, t2
    mv      a2, t3
    mv      a3, t4
    mv      a4, t1
    jal     ra, write_ship

    li      t5, FRAME_BUF
    sb      t1, 0(t5)
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
    # validate_place retorna 1 por traslape y 2 por fuera del tablero.
    li      t5, FRAME_BUF
    sb      t1, 0(t5)
    addi    a0, a0, -1
    sb      a0, 1(t5)
    li      a0, EVT_PLACE_BAD
    li      a1, FRAME_BUF
    li      a2, 2
    jal     ra, uart_send_frame
    jal     x0, remote_ship_loop

# ---------------------------------------------------------------------------
# Turnos y disparos
# ---------------------------------------------------------------------------

local_turn:
    addi    sp, sp, -8
    sw      ra, 4(sp)
    li      s8, 0
    li      s9, 0

local_fire_input:
    jal     ra, read_buttons
    mv      t0, a0
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

    mv      a0, s1
    mv      a1, s8
    mv      a2, s9
    jal     ra, resolve_shot
    li      t0, 3
    beq     a0, t0, local_fire_input  # casilla ya disparada
    mv      t6, a0
    addi    s5, s5, 1
    li      t0, 1
    bne     t6, t0, local_fire_result
    addi    s4, s4, 1
local_fire_result:
    mv      a0, s8
    mv      a1, s9
    mv      a2, t6
    jal     ra, send_shot_result
    jal     ra, render_boards
    li      t0, 9
    bne     s4, t0, local_continue
    li      a0, 0
    jal     ra, finish_game
    lw      ra, 4(sp)
    addi    sp, sp, 8
    jalr    x0, 0(ra)
local_continue:
    li      s2, 1
    li      a0, 1
    jal     ra, send_turn
    lw      ra, 4(sp)
    addi    sp, sp, 8
    jal     x0, battle_loop

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
    li      t0, 1
    bne     t6, t0, remote_result
    addi    s3, s3, 1
remote_result:
    mv      a0, t1
    mv      a1, t2
    mv      a2, t6
    jal     ra, send_incoming
    jal     ra, render_boards
    li      t0, 9
    bne     s3, t0, remote_continue
    li      a0, 1
    jal     ra, finish_game
    jal     x0, battle_loop
remote_continue:
    li      s2, 0
    li      a0, 0
    jal     ra, send_turn
    jal     x0, battle_loop

# ---------------------------------------------------------------------------
# Tableros
# ---------------------------------------------------------------------------

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

# a0=tablero, a1=fila, a2=columna, a3=orientacion, a4=id
validate_place:
    li      t0, 4
    beq     a4, x0, ship_length_done
    li      t0, 3
    li      t1, 1
    beq     a4, t1, ship_length_done
    li      t0, 2
ship_length_done:
    beq     a3, x0, horizontal_bounds
    add     t1, a1, t0
    li      t2, 8
    bgt     t1, t2, place_out
    jal     x0, place_scan
horizontal_bounds:
    add     t1, a2, t0
    li      t2, 8
    bgt     t1, t2, place_out
place_scan:
    li      t1, 0
place_scan_loop:
    beq     t1, t0, place_valid
    beq     a3, x0, scan_horizontal
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

# Escribe las casillas de un barco con valor 1.
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
    li      t5, 1
    sw      t5, 0(t4)
    addi    t1, t1, 1
    jal     x0, write_ship_loop
write_ship_done:
    jalr    x0, 0(ra)

# Retorna 0 fallo, 1 impacto, 3 casilla ya usada.
resolve_shot:
    slli    t0, a1, 3
    add     t0, t0, a2
    slli    t0, t0, 2
    add     t0, a0, t0
    lw      t1, 0(t0)
    li      t2, 1
    beq     t1, t2, shot_hit
    beq     t1, x0, shot_miss
    li      a0, 3
    jalr    x0, 0(ra)
shot_hit:
    li      t2, 2
    sw      t2, 0(t0)
    li      a0, 1
    jalr    x0, 0(ra)
shot_miss:
    li      t2, 3
    sw      t2, 0(t0)
    li      a0, 0
    jalr    x0, 0(ra)

# Actualiza las dos zonas 8x8 en una cuadricula VGA de 20 columnas.
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
    add     t4, s0, t3
    lw      t5, 0(t4)
    addi    t6, s8, 2
    slli    a0, t6, 4
    slli    t0, t6, 2
    add     a0, a0, t0
    addi    a0, a0, 1
    add     a0, a0, s9
    mv      a1, t5
    jal     ra, vga_write
    add     t4, s1, t3
    lw      t5, 0(t4)
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

vga_write:
    slli    t0, a0, 2
    li      t1, VGA_BASE
    add     t0, t0, t1
    sw      a1, 0(t0)
    jalr    x0, 0(ra)

# ---------------------------------------------------------------------------
# UART y eventos
# ---------------------------------------------------------------------------

uart_send_byte:
    li      t0, UART_BASE
uart_tx_wait:
    lw      t1, 0(t0)
    andi    t1, t1, 1
    bne     t1, x0, uart_tx_wait
    sw      a0, 4(t0)
    jalr    x0, 0(ra)

# a0=comando, a1=payload, a2=longitud
uart_send_frame:
    addi    sp, sp, -36
    sw      ra, 32(sp)
    sw      s8, 28(sp)
    sw      s9, 24(sp)
    sw      s10, 20(sp)
    sw      s11, 16(sp)
    mv      s8, a0                 # comando
    mv      s9, a1                 # payload
    mv      s10, a2                # longitud
    xor     s11, s8, s10           # checksum parcial
    li      a0, STX
    jal     ra, uart_send_byte
    mv      a0, s8
    jal     ra, uart_send_byte
    mv      a0, s10
    jal     ra, uart_send_byte
    li      t2, 0
send_payload_loop:
    beq     t2, s10, send_payload_done
    add     t4, s9, t2
    lbu     a0, 0(t4)
    xor     s11, s11, a0
    jal     ra, uart_send_byte
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

uart_get_byte:
    li      t0, UART_BASE
uart_rx_wait:
    lw      t1, 0(t0)
    andi    t1, t1, 2
    beq     t1, x0, uart_rx_wait
    lw      a0, 8(t0)
    andi    a0, a0, 0xff
    jalr    x0, 0(ra)

# Recibe una trama valida; retorna a0=CMD, a1=LEN y guarda payload en FRAME_BUF.
uart_recv_frame:
    addi    sp, sp, -16
    sw      s8, 12(sp)
    sw      s9, 8(sp)
    sw      s10, 4(sp)
    sw      s11, 0(sp)
recv_stx:
    jal     ra, uart_get_byte
    li      t0, STX
    bne     a0, t0, recv_stx
    jal     ra, uart_get_byte
    mv      s8, a0                 # comando
    jal     ra, uart_get_byte
    mv      s9, a0                 # longitud
    li      t3, 32
    bgt     s9, t3, recv_stx
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
    addi    sp, sp, 16
    jalr    x0, 0(ra)

send_turn:
    li      t0, FRAME_BUF
    sb      a0, 0(t0)
    li      a0, EVT_TURN
    li      a1, FRAME_BUF
    li      a2, 1
    jal     x0, uart_send_frame

send_shot_result:
    li      t0, FRAME_BUF
    sb      a0, 0(t0)
    sb      a1, 1(t0)
    sb      a2, 2(t0)
    li      a0, EVT_SHOT_RESULT
    li      a1, FRAME_BUF
    li      a2, 3
    jal     x0, uart_send_frame

send_incoming:
    li      t0, FRAME_BUF
    sb      a0, 0(t0)
    sb      a1, 1(t0)
    sb      a2, 2(t0)
    li      a0, EVT_INCOMING
    li      a1, FRAME_BUF
    li      a2, 3
    jal     x0, uart_send_frame

# ---------------------------------------------------------------------------
# Indicadores y utilidades
# ---------------------------------------------------------------------------

read_buttons:
    li      t0, GPIO_BASE
    lw      a0, 0(t0)
    andi    a0, a0, 0x7f
wait_release:
    li      t0, GPIO_BASE
    lw      t1, 0(t0)
    andi    t1, t1, 0x3f
    bne     t1, x0, wait_release
    jalr    x0, 0(ra)

led_write:
    li      t0, LED_BASE
    sw      a0, 0(t0)
    jalr    x0, 0(ra)

display_write:
    li      t0, DISPLAY_BASE
    sw      a0, 0(t0)
    jalr    x0, 0(ra)

buzzer_write:
    li      t0, BUZZER_BASE
    sw      a0, 0(t0)
    jalr    x0, 0(ra)

# a0 ganador: 0 local, 1 remoto.
finish_game:
    li      t0, FRAME_BUF
    sb      a0, 0(t0)
    beq     a0, x0, winner_local
    addi    s7, s7, 1
    li      s11, 1                  # protocolo: 1 = Jugador 2
    jal     x0, winner_common
winner_local:
    addi    s6, s6, 1
    li      s11, 0                  # protocolo: 0 = Jugador 1
winner_common:
    li      t0, P1_WINS
    sw      s6, 0(t0)
    li      t0, P2_WINS
    sw      s7, 0(t0)
    li      a0, 2                   # LED: resultado de partida
    jal     ra, led_write
    li      a0, 5
    jal     ra, buzzer_write
    slli    t1, s6, 4
    or      t1, t1, s7
    mv      a0, t1
    jal     ra, display_write
    li      t0, FRAME_BUF
    lbu     t0, 0(t0)
    srli    t1, s5, 8
    li      t2, FRAME_BUF
    sb      t1, 1(t2)
    andi    t1, s5, 0xff
    sb      t1, 2(t2)
    sb      x0, 3(t2)              # barcos hundidos: contador opcional
    sb      x0, 4(t2)
    li      a0, EVT_GAME_OVER
    li      a1, FRAME_BUF
    li      a2, 5
    jal     ra, uart_send_frame
finish_wait_reset:
    jal     ra, read_buttons
    andi    t1, a0, 0x40         # BTN_RST reinicia conservando victorias
    beq     t1, x0, finish_wait_reset
    jalr    x0, 0(ra)
