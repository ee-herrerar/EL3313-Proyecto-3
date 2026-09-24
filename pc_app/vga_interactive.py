#!/usr/bin/env python3
"""Consola de prueba para el mapa de tiles VGA y el top HDL provisional."""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path

ROWS = 15
COLS = 20
COLORS = {
    "water": (".", 0),
    "ship": ("S", 1),
    "hit": ("X", 2),
    "miss": ("o", 3),
    "hud": ("#", 4),
}


class TileConsole:
    def __init__(self) -> None:
        self.tiles = [[0 for _ in range(COLS)] for _ in range(ROWS)]

    def show(self) -> None:
        print("   " + " ".join(f"{column:02}" for column in range(COLS)))
        for row, values in enumerate(self.tiles):
            symbols = " ".join(next(symbol for symbol, value in COLORS.values() if value == tile)
                                for tile in values)
            print(f"{row:02} {symbols}")

    def set_tile(self, row: int, column: int, color: str) -> None:
        if not (0 <= row < ROWS and 0 <= column < COLS):
            raise ValueError("fila y columna deben estar dentro de 0..14 y 0..19")
        if color not in COLORS:
            raise ValueError(f"color invalido: {color}; use {', '.join(COLORS)}")
        self.tiles[row][column] = COLORS[color][1]

    def clear(self) -> None:
        self.tiles = [[0 for _ in range(COLS)] for _ in range(ROWS)]


def run_hdl_test(root: Path) -> int:
    if shutil.which("iverilog") is None or shutil.which("vvp") is None:
        print("No se encontraron iverilog/vvp en PATH")
        return 1
    source = root / "modulos" / "src" / "peripheral" / "vga"
    testbench = root / "modulos" / "tb" / "peripheral" / "vga" / "vga_top_dut_tb.sv"
    output = root / ".vga_top_dut_sim.out"
    files = [source / name for name in (
        "tile_map_ram.sv", "tile_renderer.sv", "vga_sync.sv",
        "vga_periph.sv", "vga_top_dut.sv",
    )]
    command = ["iverilog", "-g2012", "-s", "vga_top_dut_tb", "-o", str(output)]
    command.extend(str(path) for path in (*files, testbench))
    compile_result = subprocess.run(command, cwd=root, text=True)
    if compile_result.returncode:
        return compile_result.returncode
    try:
        result = subprocess.run(["vvp", str(output)], cwd=root, text=True)
        return result.returncode
    finally:
        output.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Prueba interactiva del mapa VGA")
    parser.add_argument("--sim", action="store_true", help="ejecuta tambien el testbench SystemVerilog")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]

    if args.sim:
        status = run_hdl_test(root)
        if status:
            return status

    console = TileConsole()
    print("Comandos: show, set FILA COLUMNA COLOR, clear, sim, quit")
    while True:
        try:
            command = input("vga> ").strip().split()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        if not command:
            continue
        try:
            if command[0] in {"quit", "exit"}:
                return 0
            if command[0] == "show":
                console.show()
            elif command[0] == "clear":
                console.clear()
            elif command[0] == "set" and len(command) == 4:
                console.set_tile(int(command[1]), int(command[2]), command[3])
            elif command[0] == "sim":
                run_hdl_test(root)
            else:
                print("Uso: show | set FILA COLUMNA COLOR | clear | sim | quit")
        except ValueError as error:
            print(error)


if __name__ == "__main__":
    raise SystemExit(main())
