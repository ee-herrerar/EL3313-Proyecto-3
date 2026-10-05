#   - Registros base fijos (no se modifican en todo el programa):
#       gp = 0x00010000  base de perifericos
#       tp = 0x00011000  base de memoria de video VGA
#       s0 = 0x00002000  base de RAM (tablero local); s1 = s0+0x100 (tablero remoto)
#
# Mapa de RAM (offsets desde s0):
#   0x000 tablero local (64 palabras)   0x100 tablero remoto (64 palabras)
#   0x200 FRAME_BUF (hasta 32 palabras) 0x300 P1_WINS   0x304 P2_WINS
#   pila: STACK_TOP = 0x2FFC (crece hacia abajo)
#
# GPIO: bit6 RST, bit5 arriba, bit4 abajo, bit3 izq, bit2 der, bit1 SEL, bit0 OK
# Casilla: 0 agua, 1 barco propio, 2 impacto, 3 fallo
# Trama UART: STX(02) CMD LEN PAYLOAD CHECKSUM(xor CMD,LEN,PAYLOAD) ETX(03)
# UART ctrl: bit0 = TX ocupado, bit1 = RX listo 

# ---- offsets desde gp (perifericos) ----
.eqv UART_CTRL,   0x40
.eqv UART_TX,     0x44
.eqv UART_RX,     0x48
.eqv GPIO_OFF,    0x120
.eqv DISPLAY_OFF, 0x130
.eqv LED_OFF,     0x138
.eqv BUZZER_OFF,  0x140

# ---- offsets desde s0 (RAM) ----
.eqv REMOTE_OFF,  0x100
.eqv FRAME_OFF,   0x200
.eqv P1_OFF,      0x300
.eqv P2_OFF,      0x304

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

# Codigos de buzzer: 1 impacto, 2 fallo, 3 hundido (reservado), 4 invalida, 5 victoria

.globl _start
.globl main

main:
_start:
    li      sp, 0x2FFC
    li      s0, 0x2000             # base RAM / tablero local
    addi    s1, s0, REMOTE_OFF     # tablero remoto
    li      gp, 0x10000            # base perifericos
    li      tp, 0x11000            # base VGA
    li      s2, 0                  # turno: 0 local, 1 remoto
    li      s3, 0                  # impactos sobre tablero local
    li      s4, 0                  # impactos sobre tablero remoto
    li      s5, 0                  # disparos validos totales
    lw      s6, P1_OFF(s0)         # victorias Jugador 1 (RAM debe iniciar en 0)
    lw      s7, P2_OFF(s0)         # victorias Jugador 2

    mv      a0, s0
    li      a1, 64
    jal     ra, clear_board
    mv      a0, s1
    li      a1, 64
    jal     ra, clear_board
    jal     ra, clear_vga

    li      a0, 0
    jal     ra, led_write          # fase de colocacion
    jal     ra, update_score_display
    jal     ra, render_boards

    li      a0, EVT_PLACE_START
    addi    a1, s0, FRAME_OFF
    li      a2, 0
    jal     ra, uart_send_frame

    jal     ra, place_local_fleet
    jal     ra, receive_remote_fleet

    li      a0, 1
    jal     ra, led_write          # fase de batalla
    li      a0, EVT_BATTLE_START
    addi    a1, s0, FRAME_OFF
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

    # validate_place usa registros temporales t1-t5.
    # Recuperar los datos originales antes de write_ship.
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
    jal     ra, write_ship

    # FRAME_BUF[0] conserva el identificador original.
    li      a0, EVT_PLACE_OK
    mv      a1, t5
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
    # FRAME_BUF[0] conserva el identificador original.
    addi    a0, a0, -1
    li      t5, FRAME_BUF
    sb      a0, 1(t5)
    li      a0, EVT_PLACE_BAD
    mv      a1, t5
    li      a2, 2
    jal     ra, uart_send_frame
    jal     x0, remote_ship_loop

# ---------------------------------------------------------------------------
# Turnos y disparos
# ---------------------------------------------------------------------------

local_turn:
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
    beq     a0, t0, local_fire_input  # casilla ya disparada: no consume turno
    mv      t6, a0
    addi    s5, s5, 1
    li      t0, 1
    bne     t6, t0, local_fire_sound
    addi    s4, s4, 1
local_fire_sound:
    li      a0, 2                     # fallo
    beq     t6, x0, local_buz
    li      a0, 1                     # impacto
local_buz:
    jal     ra, buzzer_write
    mv      a0, s8
    mv      a1, s9
    mv      a2, t6
    # J1 dispara sobre J2: para la PC es un disparo recibido.
    jal     ra, send_incoming
    jal     ra, render_boards
    li      t0, 9
    bne     s4, t0, local_continue
    li      a0, 0
    jal     ra, finish_game
    jal     x0, _start
local_continue:
    li      s2, 1
    li      a0, 1
    jal     ra, send_turn
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
    bne     t6, t0, remote_sound
    addi    s3, s3, 1
remote_result:
    # resolve_shot usa registros temporales. Recuperar coordenadas originales.
    li      t5, FRAME_BUF
    lbu     t1, 0(t5)
    lbu     t2, 1(t5)
    mv      a0, t1
    mv      a1, t2
remote_sound:
    li      a0, 2                     # fallo
    beq     t6, x0, remote_buz
    li      a0, 1                     # impacto
remote_buz:
    jal     ra, buzzer_write
    mv      a0, s8
    mv      a1, s9
    mv      a2, t6
    # J2 dispara sobre J1: para la PC es el resultado de su disparo propio.
    jal     ra, send_shot_result
    jal     ra, render_boards
    li      t0, 9
    bne     s3, t0, remote_continue
    li      a0, 1
    jal     ra, finish_game
    jal     x0, _start
remote_continue:
    li      s2, 0
    li      a0, 0
    jal     ra, send_turn
    jal     x0, battle_loop

# ---------------------------------------------------------------------------
# Tableros
# ---------------------------------------------------------------------------

# a0=direccion inicial, a1=numero de palabras
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

# Limpia las 20x15 = 300 casillas de la memoria de video
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

# a0=tablero, a1=fila, a2=columna, a3=orientacion, a4=id
# retorna a0: 0 valido, 1 traslape, 2 fuera de tablero
validate_place:
    li      t1, 7
    blt     t1, a1, place_out         # fila > 7
    blt     t1, a2, place_out         # columna > 7
    li      t1, 1
    blt     t1, a3, place_out         # orientacion > 1
    li      t1, 2
    blt     t1, a4, place_out         # id > 2
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

# a0=tablero, a1=fila, a2=columna
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

# ---------------------------------------------------------------------------
# VGA (cuadricula de 20 columnas; tablero local en cols 1-8, remoto en 11-18)
# ---------------------------------------------------------------------------

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
    li      t0, 1
    bne     t5, t0, remote_tile_ready
    li      t5, 0                    # barcos rivales no descubiertos se ven como agua
remote_tile_ready:
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

# a0=indice de casilla, a1=valor
vga_write:
    slli    t0, a0, 2
    add     t0, t0, tp
    sw      a1, 0(t0)
    jalr    x0, 0(ra)

# ---------------------------------------------------------------------------
# UART y eventos
# ---------------------------------------------------------------------------

uart_send_byte:
uart_tx_wait:
    lw      t1, UART_CTRL(gp)
    andi    t1, t1, 1
    bne     t1, x0, uart_tx_wait
    sw      a0, UART_TX(gp)
    jalr    x0, 0(ra)

# a0=comando, a1=payload (1 byte por palabra), a2=longitud
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
    slli    t3, t2, 2
    add     t4, s9, t3
    lw      a0, 0(t4)
    andi    a0, a0, 0xff
    xor     s11, s11, a0
    mv      s8, t2                 # t2 no sobrevive a la llamada: guardar indice
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

uart_get_byte:
uart_rx_wait:
    lw      t1, UART_CTRL(gp)
    andi    t1, t1, 2
    beq     t1, x0, uart_rx_wait
    lw      a0, UART_RX(gp)
    andi    a0, a0, 0xff
    jalr    x0, 0(ra)

# Recibe una trama valida; retorna a0=CMD, a1=LEN, payload en FRAME_BUF.
# Cualquier trama invalida (STX/checksum/ETX/longitud) se descarta.
uart_recv_frame:
    addi    sp, sp, -20
    sw      ra, 16(sp)             # ra se guarda: se llama a uart_get_byte
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
    blt     t3, s9, recv_stx       # longitud > 32
    li      s10, 0
    xor     s11, s8, s9
recv_payload:
    beq     s10, s9, recv_checksum
    jal     ra, uart_get_byte
    slli    t3, s10, 2
    addi    t5, s0, FRAME_OFF
    add     t5, t5, t3
    sw      a0, 0(t5)
    xor     s11, s11, a0
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

# a0 = jugador con el turno (0 local/J1, 1 remoto/J2)
send_turn:
    addi    t0, s0, FRAME_OFF
    sw      a0, 0(t0)
    li      a0, EVT_TURN
    mv      a1, t0
    li      a2, 1
    jal     x0, uart_send_frame

# a0=fila, a1=columna, a2=resultado (tiro del J2 sobre tablero local)
send_shot_result:
    addi    t0, s0, FRAME_OFF
    sw      a0, 0(t0)
    sw      a1, 4(t0)
    sw      a2, 8(t0)
    li      a0, EVT_SHOT_RESULT
    mv      a1, t0
    li      a2, 3
    jal     x0, uart_send_frame

# a0=fila, a1=columna, a2=resultado (tiro del J1 sobre tablero del J2)
send_incoming:
    addi    t0, s0, FRAME_OFF
    sw      a0, 0(t0)
    sw      a1, 4(t0)
    sw      a2, 8(t0)
    li      a0, EVT_INCOMING
    mv      a1, t0
    li      a2, 3
    jal     x0, uart_send_frame

# ---------------------------------------------------------------------------
# Indicadores y utilidades
# ---------------------------------------------------------------------------

# Retorna a0 = botones (bits 0-5). Espera a soltar. BTN_RST reinicia en
# cualquier punto donde se consulten botones.
read_buttons:
    lw      a0, GPIO_OFF(gp)
    andi    a0, a0, 0x7f
    andi    t1, a0, 0x40
    beq     t1, x0, rb_no_reset
    jal     x0, _start             # BTN_RST: reinicia conservando victorias
rb_no_reset:
wait_release:
    lw      t1, GPIO_OFF(gp)
    andi    t1, t1, 0x3f
    bne     t1, x0, wait_release
    jalr    x0, 0(ra)

led_write:
    sw      a0, LED_OFF(gp)
    jalr    x0, 0(ra)

display_write:
    sw      a0, DISPLAY_OFF(gp)
    jalr    x0, 0(ra)

# Actualiza los cuatro digitos del display con el marcador acumulado.
# s6 = victorias J1 (0-99), s7 = victorias J2 (0-99).
# Empaquetado fisico esperado: [J1 decenas][J1 unidades][J2 decenas][J2 unidades].
update_score_display:
    # J1: separar decenas y unidades sin usar DIV/REM (RV32I sin extension M).
    mv      t0, s6
    li      t1, 0
score_j1_loop:
    li      t2, 10
    blt     t0, t2, score_j1_done
    addi    t0, t0, -10
    addi    t1, t1, 1
    jal     x0, score_j1_loop
score_j1_done:
    slli    t3, t1, 12             # J1 decenas -> bits [15:12]
    slli    t4, t0, 8              # J1 unidades -> bits [11:8]
    or      t3, t3, t4

    # J2: separar decenas y unidades.
    mv      t0, s7
    li      t1, 0
score_j2_loop:
    li      t2, 10
    blt     t0, t2, score_j2_done
    addi    t0, t0, -10
    addi    t1, t1, 1
    jal     x0, score_j2_loop
score_j2_done:
    slli    t4, t1, 4              # J2 decenas -> bits [7:4]
    or      t3, t3, t4
    or      t3, t3, t0             # J2 unidades -> bits [3:0]

    mv      a0, t3
    jal     x0, display_write       # tail-call: retorna al llamador original

buzzer_write:
    sw      a0, BUZZER_OFF(gp)
    jalr    x0, 0(ra)

# a0 ganador: 0 local (J1), 1 remoto (J2).
finish_game:
    # Guardar ganador en el payload antes de reutilizar a0.
    li      t0, FRAME_BUF
    sb      a0, 0(t0)

    # Incrementar el marcador del ganador con saturacion en 99.
    beq     a0, x0, winner_local

    li      t3, 99
    bge     s7, t3, winner_remote_max
    addi    s7, s7, 1
winner_remote_max:
    jal     x0, winner_common

winner_local:
    li      t3, 99
    bge     s6, t3, winner_local_max
    addi    s6, s6, 1
winner_local_max:

winner_common:
    # Persistir victorias en RAM. Esta RAM no se borra con BTN_RST.
    li      t0, P1_WINS
    sw      s6, 0(t0)
    li      t0, P2_WINS
    sw      s7, 0(t0)

    # Estado visual/sonoro de fin de partida.
    li      a0, 2                   # LED: resultado de partida
    jal     ra, led_write
    li      a0, 5                   # sonido de victoria
    jal     ra, buzzer_write
    jal     ra, update_score_display

    # Payload GAME_OVER:
    # [0] ganador, [1:2] disparos totales (MSB primero),
    # [3] barcos hundidos J1, [4] barcos hundidos J2.
    srli    t1, s5, 8
    sw      t1, 4(t2)              # disparos totales (alto)
    andi    t1, s5, 0xff
    sb      t1, 2(t2)
    sb      x0, 3(t2)              # pendiente del bloque de hundimientos
    sb      x0, 4(t2)
    li      a0, EVT_GAME_OVER
    mv      a1, t2
    li      a2, 5
    jal     ra, uart_send_frame

# BTN_RST esta conectado al reset de hardware del CPU en soc_top.
# Por eso el firmware solo permanece aqui hasta que el boton fuerce PC=0.
finish_wait_reset:
    jal     x0, finish_wait_reset
