# EL3313 Proyecto 3: Batalla Naval

Repositorio de trabajo para el proyecto de Batalla Naval sobre RISC-V y
perifericos mapeados en memoria. El CPU se conserva como bloque existente; la
integracion completa del SoC y el firmware del juego deben incorporarse para
la demostracion final.

## Estructura actual

- `modulos/src/cpu/`: núcleo y bloques del procesador.
- `modulos/src/peripheral/`: periféricos GPIO, display, buzzer y VGA.
- `modulos/src/uart/`: transmisor, receptor y periférico UART.
- `modulos/tb/`: bancos de prueba existentes.
- `pc_app/vga_interactive.py`: consola de prueba del mapa de tiles VGA.
- `pc_app/battleship_uart.py`: terminal serial del Jugador 2.
- `pc_app/uart_protocol.py`: codec del protocolo de aplicación binario.
- `constraints/`: restricciones separadas por top y etapa; ver su README.
- `docs/diseño/planteamiento.md`: arquitectura propuesta y etapas de avance.
- `docs/informe/informe.md`: plantilla pendiente del informe técnico.

## Aplicacion del Jugador 2

Requiere Python 3.10 o posterior y una conexión USB-UART a 115200 baudios.

```bash
python -m pip install -r pc_app/requirements.txt
python pc_app/battleship_uart.py --port COM5
```

Cambie `COM5` por el puerto asignado por el sistema operativo. Abra la
terminal antes de iniciar o reiniciar la partida para recibir el evento de
colocacion. El firmware de la FPGA debe implementar el mismo protocolo descrito en
`docs/diseño/planteamiento.md` y notificar `0x80` para iniciar la colocación.

## Vivado y Basys 3

La restricción `constraints/vga_top_dut_basys3.xdc` corresponde solo al
top-level `vga_top_dut_board`, usado para la demostración de video. No
seleccione ese XDC para un SoC. El repositorio aún no contiene un top-level
SoC Basys 3 ni el XDC final de botones, UART, displays, LED y buzzer.

No se documenta un flujo de síntesis final hasta que se incorpore ese top y se
defina el mapeo de pines de sus puertos.
