"""Codificacion y recuperacion de tramas del protocolo del Proyecto 3."""

from __future__ import annotations

from dataclasses import dataclass

STX = 0x02
ETX = 0x03
MAX_PAYLOAD = 32


class Command:
    PLACE_SHIP = 0x01
    FIRE = 0x02
    PLACEMENT_START = 0x80
    PLACE_ACCEPTED = 0x81
    PLACE_REJECTED = 0x82
    BATTLE_START = 0x83
    TURN_CHANGED = 0x84
    SHOT_RESULT = 0x85
    INCOMING_SHOT = 0x86
    GAME_OVER = 0x87


@dataclass(frozen=True)
class Frame:
    command: int
    payload: bytes


def checksum(command: int, payload: bytes) -> int:
    value = command ^ len(payload)
    for byte in payload:
        value ^= byte
    return value


def encode_frame(command: int, payload: bytes = b"") -> bytes:
    if not 0 <= command <= 0xFF:
        raise ValueError("El comando debe estar entre 0 y 255")
    if len(payload) > MAX_PAYLOAD:
        raise ValueError(f"La carga no puede superar {MAX_PAYLOAD} bytes")
    body = bytes((command, len(payload))) + payload
    return bytes((STX,)) + body + bytes((checksum(command, payload), ETX))


class FrameParser:
    """Acumula bytes seriales y entrega solo tramas completas y validas."""

    def __init__(self) -> None:
        self._buffer = bytearray()

    def feed(self, data: bytes) -> list[Frame]:
        self._buffer.extend(data)
        frames: list[Frame] = []

        while True:
            try:
                start = self._buffer.index(STX)
            except ValueError:
                self._buffer.clear()
                break

            if start:
                del self._buffer[:start]
            if len(self._buffer) < 3:
                break

            payload_length = self._buffer[2]
            frame_length = payload_length + 5
            if payload_length > MAX_PAYLOAD:
                del self._buffer[0]
                continue
            if len(self._buffer) < frame_length:
                break

            command = self._buffer[1]
            payload = bytes(self._buffer[3 : 3 + payload_length])
            received_checksum = self._buffer[3 + payload_length]
            end = self._buffer[4 + payload_length]
            if end != ETX or received_checksum != checksum(command, payload):
                del self._buffer[0]
                continue

            frames.append(Frame(command, payload))
            del self._buffer[:frame_length]

        return frames