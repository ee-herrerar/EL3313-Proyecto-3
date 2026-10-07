# EL3313 Proyecto 3: Batalla Naval

Repositorio de trabajo para el proyecto de Batalla Naval sobre RISC-V y
perifericos mapeados en memoria. El top `soc_top` integra el CPU, ROM, RAM,
interconnect MMIO y periféricos; el firmware del juego se encuentra en
`modulos/ensamblador/batalla_naval.s`.
Repositorio del proyecto de Batalla Naval sobre un microprocesador RISC-V,
periféricos mapeados en memoria y una aplicación serial para el Jugador 2.

`modulos/src/top/soc_top.sv` es el top RTL del SoC: integra el CPU, la ROM, la
RAM de datos, la decodificación del bus y los periféricos de placa. Esta
integración de hardware no equivale todavía a una partida funcional completa:
el firmware del juego, su validación integral y el proyecto reproducible de
Vivado deben verificarse por separado.

## Estructura actual

- `modulos/src/cpu/`: núcleo y bloques del procesador.
- `modulos/src/peripheral/`: periféricos GPIO, display, buzzer y VGA.
- `modulos/src/uart/`: transmisor, receptor y periférico UART.
- `modulos/src/top/`: SoC Basys3, interconnect y generación del reloj VGA.
- `modulos/src/uart/`: UART RX/TX, `uart_top` (instanciado por `soc_top`) y
  `uart_peripheral` (módulo alternativo, no instanciado por el SoC).
- `modulos/src/top/`: top del SoC, RAM de datos y envoltura del reloj VGA.
- `modulos/tb/`: bancos de prueba existentes; contiene modelos de simulación
  para la BRAM de Vivado (`cpu/batalha_naval_mem_model.sv`) y el reloj VGA IP
  (`top/clk_wiz_0_model.sv`).
- `pc_app/vga_interactive.py`: consola de prueba del mapa de tiles VGA.
- `pc_app/battleship_uart.py`: terminal serial del Jugador 2.
- `pc_app/uart_protocol.py`: codec del protocolo de aplicación binario.
- `constraints/`: restricciones separadas por top y etapa; ver su README.
- `docs/diseño/planteamiento.md`: arquitectura, interfaces y estado del diseño.
- `docs/informe/informe.md`: plantilla pendiente del informe técnico.

## Estado de Vivado

El top de integración es `soc_top`; `vga_top_dut_board` es un top independiente
para la demostración VGA. El SoC instancia `clk_wiz_0`: desde `clk_in1` de
100 MHz genera `clk_fpga` de 100 MHz para el sistema y `clk_vga` de 25 MHz
para VGA. También instancia `batalla_naval_mem` para la ROM. No se encontró en
el repositorio un proyecto `.xpr` ni los archivos de configuración de esos IP;
deben estar disponibles o regenerarse en Vivado para reproducir la síntesis.
Consulte [`constraints/README.md`](constraints/README.md) para las
restricciones y pendientes de cada top.

## Aplicación del Jugador 2

Requiere Python 3.10 o posterior y una conexión USB-UART. La aplicación usa
115200 baudios (8N1), igual que el periférico UART del SoC, y permite elegir
el puerto detectado al iniciar.

```bash
python -m pip install -r pc_app/requirements.txt
python pc_app/battleship_uart.py
```

Para listar los puertos sin iniciar la aplicación, ejecute
`python pc_app/battleship_uart.py --list-ports`. Abra la terminal antes de
iniciar o reiniciar la partida para recibir el evento de colocación. El firmware
de la FPGA debe implementar el mismo protocolo descrito en
`docs/diseño/planteamiento.md` y notificar `0x80` para iniciar la colocación.
