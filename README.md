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

Requiere Python 3.10 o posterior y una conexión USB-UART. La aplicación usa
115200 baudios (8N1), igual que el periférico UART del SoC, y permite elegir
el puerto detectado al iniciar.

```bash
python -m pip install -r pc_app/requirements.txt
python pc_app/battleship_uart.py
```

Para listar los puertos sin iniciar la aplicación, ejecute
`python pc_app/battleship_uart.py --list-ports`. Abra la terminal antes de
iniciar o reiniciar la partida para recibir el evento de colocacion. El firmware
de la FPGA debe implementar el mismo protocolo descrito en
`docs/diseño/planteamiento.md` y notificar `0x80` para iniciar la colocación.

## Vivado y Basys 3

La restricción `constraints/vga_top_dut_basys3.xdc` corresponde solo al
top-level `vga_top_dut_board`, usado para la demostración de video. Para la
integración general debe seleccionarse `modulos/src/top/soc_top.sv` como top y
`constraints/ConstraintsTop.xdc` como archivo de restricciones.

El top general incorpora el armazón de CPU y los periféricos de placa. La
interconexión completa del bus del CPU con esos periféricos sigue siendo una
etapa posterior.
