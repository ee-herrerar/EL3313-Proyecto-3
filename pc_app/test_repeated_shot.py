from unittest.mock import patch

from battleship_uart import (
    blank_board,
    read_unfired_coordinate,
)


def main():

    board = blank_board()

    # Casillas donde J2 ya disparo
    board[3][5] = "X"   # hit
    board[2][4] = "o"   # miss

    print("========================================")
    print(" TEST REPEATED SHOT J2")
    print("========================================")

    # Simulamos que el usuario intenta:
    #
    # 1. (3,5) -> ya fue HIT
    # 2. (2,4) -> ya fue MISS
    # 3. (6,7) -> nunca disparada
    #
    # La funcion debe rechazar las primeras dos
    # y devolver solamente (6,7).

    with patch(
        "builtins.input",
        side_effect=[
            "3 5",
            "2 4",
            "6 7",
        ],
    ):

        row, col = read_unfired_coordinate(
            "Disparo: ",
            board,
        )

    if (row, col) != (6, 7):

        print(
            f"FAIL: se esperaba (6, 7), "
            f"pero se obtuvo ({row}, {col})"
        )

        raise SystemExit(1)

    print("")
    print(
        "PASS: HIT repetido fue rechazado"
    )

    print(
        "PASS: MISS repetido fue rechazado"
    )

    print(
        "PASS: casilla nueva fue aceptada"
    )

    print("")
    print(
        "Repeated shot protection: PASS"
    )


if __name__ == "__main__":
    main()