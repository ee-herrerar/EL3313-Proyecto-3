#!/usr/bin/env python3
"""Terminal de entrada/salida para el Jugador 2 por UART."""

from __future__ import annotations

import argparse
import sys
import time

from uart_protocol import Command, Frame, FrameParser, encode_frame

BOARD_SIZE = 8
SHIP_LENGTHS = (4, 3, 2)
UNKNOWN = "?"
UART_BAUD_RATE = 115_200


def blank_board() -> list[list[str]]:
    return [[UNKNOWN for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]


def read_coordinate(prompt: str) -> tuple[int, int]:
    while True:
        raw = input(prompt).strip().replace(",", " ").split()

        if len(raw) == 2:
            try:
                row, column = map(int, raw)

                if 0 <= row < BOARD_SIZE and 0 <= column < BOARD_SIZE:
                    return row, column

            except ValueError:
                pass

        print("Use dos coordenadas entre 0 y 7: fila columna.")


def read_unfired_coordinate(
    prompt: str,
    rival_board: list[list[str]],
) -> tuple[int, int]:
    """
    Pide una coordenada de disparo que no haya sido utilizada antes.

    '?' = desconocido / disponible para disparar
    'o' = fallo conocido
    'X' = impacto conocido
    """

    while True:
        row, column = read_coordinate(prompt)

        if rival_board[row][column] == UNKNOWN:
            return row, column

        print(
            f"Ya se disparo a ({row}, {column}). "
            "Seleccione otra casilla."
        )


def print_boards(
    own: list[list[str]],
    rival: list[list[str]],
) -> None:

    heading = "     " + " ".join(
        str(index)
        for index in range(BOARD_SIZE)
    )

    print(
        "\nTablero propio (Jugador 2)".ljust(30)
        + "Tablero rival conocido"
    )

    print(
        heading
        + "       "
        + heading
    )

    for row in range(BOARD_SIZE):

        left = " ".join(own[row])
        right = " ".join(rival[row])

        print(
            f"{row:2}   {left}       "
            f"{row:2}   {right}"
        )


class BattleshipTerminal:

    def __init__(
        self,
        serial_port,
        inter_byte_delay: float,
    ) -> None:

        self.serial = serial_port

        self.inter_byte_delay = inter_byte_delay

        self.parser = FrameParser()

        self.pending_frames: list[Frame] = []

        self.own_board = blank_board()

        self.rival_board = blank_board()

        self.turn: int | None = None


    # ----------------------------------------------------------------------
    # UART TX
    # ----------------------------------------------------------------------

    def send(
        self,
        command: int,
        payload: bytes = b"",
    ) -> None:

        # La pausa entre bytes da tiempo al CPU de la FPGA
        # para vaciar el registro RX.

        for byte in encode_frame(
            command,
            payload,
        ):

            self.serial.write(
                bytes((byte,))
            )

            if self.inter_byte_delay:

                time.sleep(
                    self.inter_byte_delay
                )

        self.serial.flush()


    # ----------------------------------------------------------------------
    # UART RX
    # ----------------------------------------------------------------------

    def read_frame(self) -> Frame:

        while True:

            if self.pending_frames:

                return self.pending_frames.pop(0)


            data = self.serial.read(64)


            self.pending_frames.extend(
                self.parser.feed(data)
            )


    # ----------------------------------------------------------------------
    # MARCAR BARCO LOCAL
    # ----------------------------------------------------------------------

    def mark_ship(
        self,
        ship_id: int,
        row: int,
        column: int,
        orientation: int,
    ) -> None:

        length = SHIP_LENGTHS[ship_id]


        for offset in range(length):

            ship_row = (
                row + offset
                if orientation
                else row
            )

            ship_column = (
                column
                if orientation
                else column + offset
            )


            if (
                0 <= ship_row < BOARD_SIZE
                and
                0 <= ship_column < BOARD_SIZE
            ):

                self.own_board[
                    ship_row
                ][
                    ship_column
                ] = "S"


    # ----------------------------------------------------------------------
    # EVENTOS FPGA -> PC
    # ----------------------------------------------------------------------

    def handle_event(
        self,
        frame: Frame,
    ) -> None:

        payload = frame.payload


        # ==============================================================
        # BATTLE START
        # ==============================================================

        if frame.command == Command.BATTLE_START:

            print(
                "La FPGA indica el inicio de la batalla."
            )


        # ==============================================================
        # TURN CHANGED
        # ==============================================================

        elif (
            frame.command == Command.TURN_CHANGED
            and
            len(payload) == 1
        ):

            if payload[0] not in (0, 1):

                print(
                    "Evento de turno invalido; "
                    "se descarta."
                )

                return


            self.turn = payload[0]


            player = (
                "Jugador 2 (PC)"
                if self.turn == 1
                else
                "Jugador 1 (FPGA)"
            )


            print(
                f"Turno activo: {player}."
            )


            # ----------------------------------------------------------
            # Turno del Jugador 2
            # ----------------------------------------------------------

            if self.turn == 1:

                print_boards(
                    self.own_board,
                    self.rival_board,
                )


                # ------------------------------------------------------
                # IMPORTANTE:
                #
                # No permitir disparar nuevamente a una casilla
                # conocida.
                #
                # Esto evita que la FPGA ignore el disparo repetido
                # mientras Python queda esperando una respuesta.
                # ------------------------------------------------------

                row, column = read_unfired_coordinate(
                    "Disparo (fila columna): ",
                    self.rival_board,
                )


                self.send(
                    Command.FIRE,
                    bytes(
                        (
                            row,
                            column,
                        )
                    ),
                )


        # ==============================================================
        # RESULTADO DEL DISPARO DE J2
        # ==============================================================

        elif (
            frame.command == Command.SHOT_RESULT
            and
            len(payload) == 3
        ):

            row, column, result = payload


            if (
                row < BOARD_SIZE
                and
                column < BOARD_SIZE
                and
                result in (0, 1, 2)
            ):

                # fallo

                if result == 0:

                    self.rival_board[
                        row
                    ][
                        column
                    ] = "o"


                # hit / sunk

                else:

                    self.rival_board[
                        row
                    ][
                        column
                    ] = "X"


                print(
                    "Resultado del disparo propio:",
                    self.result_name(result),
                )


                print_boards(
                    self.own_board,
                    self.rival_board,
                )


            else:

                print(
                    "Resultado de disparo invalido; "
                    "se descarta."
                )


        # ==============================================================
        # DISPARO RECIBIDO DE J1
        # ==============================================================

        elif (
            frame.command == Command.INCOMING_SHOT
            and
            len(payload) == 3
        ):

            row, column, result = payload


            if (
                row < BOARD_SIZE
                and
                column < BOARD_SIZE
                and
                result in (0, 1, 2)
            ):

                # fallo

                if result == 0:

                    self.own_board[
                        row
                    ][
                        column
                    ] = "o"


                # hit / sunk

                else:

                    self.own_board[
                        row
                    ][
                        column
                    ] = "X"


                print(
                    f"Disparo recibido en "
                    f"({row}, {column}): "
                    f"{self.result_name(result)}."
                )


                print_boards(
                    self.own_board,
                    self.rival_board,
                )


            else:

                print(
                    "Notificacion de disparo invalida; "
                    "se descarta."
                )


        # ==============================================================
        # GAME OVER
        # ==============================================================

        elif (
            frame.command == Command.GAME_OVER
            and
            len(payload) == 5
        ):

            if payload[0] not in (0, 1):

                print(
                    "Evento de ganador invalido; "
                    "se descarta."
                )

                return


            winner = (
                "Jugador 1"
                if payload[0] == 0
                else
                "Jugador 2"
            )


            shots = int.from_bytes(
                payload[1:3],
                "big",
            )


            print(
                f"Fin de partida. "
                f"Ganador: {winner}; "
                f"disparos: {shots}; "
                f"barcos hundidos J1/J2: "
                f"{payload[3]}/{payload[4]}."
            )


        # ==============================================================
        # EVENTO DESCONOCIDO
        # ==============================================================

        else:

            print(
                f"Evento UART ignorado: "
                f"comando 0x{frame.command:02X}."
            )


    # ----------------------------------------------------------------------
    # NOMBRE DE RESULTADO
    # ----------------------------------------------------------------------

    @staticmethod
    def result_name(
        result: int,
    ) -> str:

        return {
            0: "fallo",
            1: "impacto",
            2: "barco hundido",
        }.get(
            result,
            f"resultado desconocido ({result})",
        )


    # ----------------------------------------------------------------------
    # ESPERAR RESPUESTA DE COLOCACION
    # ----------------------------------------------------------------------

    def wait_placement_reply(
        self,
        ship_id: int,
    ) -> bool:

        while True:

            frame = self.read_frame()


            # ----------------------------------------------------------
            # Aceptado
            # ----------------------------------------------------------

            if (
                frame.command
                == Command.PLACE_ACCEPTED
                and
                frame.payload
                == bytes((ship_id,))
            ):

                return True


            # ----------------------------------------------------------
            # Rechazado
            # ----------------------------------------------------------

            if (
                frame.command
                == Command.PLACE_REJECTED
                and
                len(frame.payload) == 2
            ):

                rejected_id, reason = frame.payload


                if rejected_id == ship_id:

                    reason_text = {
                        0: "traslape",
                        1: (
                            "parametro invalido, "
                            "barco fuera del tablero "
                            "o ID fuera de orden"
                        ),
                    }.get(
                        reason,
                        f"motivo {reason}",
                    )


                    print(
                        f"La FPGA rechazo el barco "
                        f"{ship_id}: "
                        f"{reason_text}. "
                        f"Reintente."
                    )


                    return False


            # ----------------------------------------------------------
            # Otro evento
            # ----------------------------------------------------------

            if frame.command not in (
                Command.PLACE_ACCEPTED,
                Command.PLACE_REJECTED,
            ):

                self.handle_event(frame)


    # ----------------------------------------------------------------------
    # COLOCACION DE FLOTA
    # ----------------------------------------------------------------------

    def place_fleet(self) -> None:

        self.own_board = blank_board()


        print(
            "Colocacion remota: "
            "barcos de longitudes 4, 3 y 2."
        )


        for ship_id, length in enumerate(
            SHIP_LENGTHS
        ):

            while True:

                row, column = read_coordinate(
                    f"Barco {ship_id} "
                    f"(longitud {length}), "
                    f"fila y columna: "
                )


                # ------------------------------------------------------
                # Orientacion
                # ------------------------------------------------------

                while True:

                    orientation_text = input(
                        "Orientacion [h/v]: "
                    ).strip().lower()


                    if orientation_text in {
                        "h",
                        "v",
                    }:

                        orientation = int(
                            orientation_text == "v"
                        )

                        break


                    print(
                        "Indique h para horizontal "
                        "o v para vertical."
                    )


                # ------------------------------------------------------
                # Payload:
                #
                # ID
                # row
                # column
                # orientation
                # ------------------------------------------------------

                payload = bytes(
                    (
                        ship_id,
                        row,
                        column,
                        orientation,
                    )
                )


                self.send(
                    Command.PLACE_SHIP,
                    payload,
                )


                # ------------------------------------------------------
                # Esperar validacion de FPGA
                # ------------------------------------------------------

                if self.wait_placement_reply(
                    ship_id
                ):

                    self.mark_ship(
                        ship_id,
                        row,
                        column,
                        orientation,
                    )


                    print_boards(
                        self.own_board,
                        self.rival_board,
                    )


                    break


    # ----------------------------------------------------------------------
    # LOOP PRINCIPAL
    # ----------------------------------------------------------------------

    def run(self) -> None:

        print(
            "Esperando evento de colocacion "
            "de la FPGA (0x80); "
            "Ctrl+C termina la aplicacion."
        )


        while True:

            frame = self.read_frame()


            # ----------------------------------------------------------
            # Nueva partida
            # ----------------------------------------------------------

            if (
                frame.command
                == Command.PLACEMENT_START
                and
                not frame.payload
            ):

                self.own_board = blank_board()

                self.rival_board = blank_board()

                self.turn = None


                print(
                    "La FPGA inicio una nueva "
                    "fase de colocacion."
                )


                self.place_fleet()


            # ----------------------------------------------------------
            # Evento normal
            # ----------------------------------------------------------

            elif frame.command not in (
                Command.PLACE_ACCEPTED,
                Command.PLACE_REJECTED,
            ):

                self.handle_event(frame)


# ===========================================================================
# PUERTOS SERIALES
# ===========================================================================

def show_serial_ports(
    ports,
) -> None:

    if not ports:

        print(
            "No se detectaron puertos seriales."
        )

        return


    for index, port in enumerate(
        ports,
        start=1,
    ):

        description = (
            port.description
            or
            "Sin descripcion"
        )


        print(
            f"{index}. "
            f"{port.device} - "
            f"{description}"
        )


def select_serial_port(
    ports,
) -> str | None:

    if not ports:

        print(
            "No se detectaron puertos seriales. "
            "Conecte la Basys 3 e intente de nuevo."
        )

        return None


    show_serial_ports(ports)


    while True:

        selection = input(
            "Seleccione el numero del puerto "
            "(o q para cancelar): "
        ).strip()


        if selection.lower() == "q":

            return None


        if (
            selection.isdigit()
            and
            1 <= int(selection) <= len(ports)
        ):

            return ports[
                int(selection) - 1
            ].device


        print(
            f"Elija un numero entre "
            f"1 y {len(ports)}, "
            f"o q para cancelar."
        )


# ===========================================================================
# MAIN
# ===========================================================================

def main() -> int:

    parser = argparse.ArgumentParser(
        description=(
            "Terminal serial para el Jugador 2"
        )
    )


    parser.add_argument(
        "--port",
        help=(
            "Puerto serial; si se omite, "
            "se muestra una lista"
        ),
    )


    parser.add_argument(
        "--list-ports",
        action="store_true",
        help=(
            "Lista los puertos seriales "
            "y termina"
        ),
    )


    parser.add_argument(
        "--inter-byte-delay",
        type=float,
        default=0.002,
        help=(
            "Pausa entre bytes para permitir "
            "el polling del CPU (segundos)"
        ),
    )


    args = parser.parse_args()


    if args.inter_byte_delay < 0:

        parser.error(
            "inter-byte-delay "
            "no puede ser negativo"
        )


    # ----------------------------------------------------------------------
    # PySerial
    # ----------------------------------------------------------------------

    try:

        import serial

        from serial.tools import list_ports


    except ImportError:

        print(
            "Falta pyserial. "
            "Instale las dependencias con: "
            "pip install -r pc_app/requirements.txt"
        )

        return 2


    # ----------------------------------------------------------------------
    # Buscar puertos
    # ----------------------------------------------------------------------

    ports = sorted(
        list_ports.comports(),
        key=lambda port: port.device.casefold(),
    )


    if args.list_ports:

        show_serial_ports(ports)

        return 0


    # ----------------------------------------------------------------------
    # Elegir puerto
    # ----------------------------------------------------------------------

    try:

        port = (
            args.port
            or
            select_serial_port(ports)
        )


    except (
        KeyboardInterrupt,
        EOFError,
    ):

        print(
            "\nSeleccion cancelada."
        )

        return 0


    if not port:

        return 1


    # ----------------------------------------------------------------------
    # Abrir UART
    # ----------------------------------------------------------------------

    try:

        with serial.Serial(
            port,
            UART_BAUD_RATE,
            timeout=0.1,
        ) as serial_port:

            print(
                f"Conectado a {port} "
                f"a {UART_BAUD_RATE} baudios "
                f"(8N1)."
            )


            BattleshipTerminal(
                serial_port,
                args.inter_byte_delay,
            ).run()


    except KeyboardInterrupt:

        print(
            "\nAplicacion finalizada."
        )


    except serial.SerialException as error:

        print(
            f"No se pudo abrir o mantener "
            f"{port}: {error}",
            file=sys.stderr,
        )

        return 1


    return 0


if __name__ == "__main__":
    raise SystemExit(
        main()
    )