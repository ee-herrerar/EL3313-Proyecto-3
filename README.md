# EL3313 Proyecto 3: Batalla Naval sobre RISC-V con periféricos VGA y UART

Repositorio del proyecto final de Batalla Naval desarrollado sobre un microprocesador RV32I con memorias, periféricos mapeados en memoria y comunicación serial con una aplicación de PC. El diseño del SoC queda implementado en `modulos/src/top/soc_top.sv` y la lógica del juego se ejecuta en firmware de ensamblador cargado en la ROM del sistema.

## Resumen del proyecto

El proyecto ya quedó consolidado como una solución completa de juego distribuido para dos jugadores:

- El Jugador 1 interactúa con la FPGA usando botones locales y observa el estado del juego en un monitor VGA.
- El Jugador 2 se conecta mediante una terminal en Python por UART para comunicar sus movimientos y recibir actualizaciones del estado del tablero.
- La lógica del juego, validación de disparos, colocación de barcos, control de turnos y condición de victoria se ejecuta en el microprocesador, no en la aplicación PC.
- El hardware se ocupa de la interfaz con periféricos y del acceso de memoria mediante bus mapeado en memoria.

## Estructura del repositorio

- `modulos/src/cpu/`: núcleo del RV32I, decodificador, ALU, banco de registros y datapath.
- `modulos/src/top/`: `soc_top`, interconexión MMIO y reloj VGA.
- `modulos/src/peripheral/`: GPIO, display 7 segmentos, buzzer, VGA, y módulos auxiliares.
- `modulos/src/uart/`: UART RX/TX y periférico serial.
- `modulos/ensamblador/assembly.py`: ensamblador/encoder para la ROM del juego.
- `modulos/tb/`: bancos de prueba para CPU, memoria, UART, GPIO y periféricos VGA.
- `pc_app/battleship_uart.py`: aplicación de terminal del Jugador 2.
- `pc_app/uart_protocol.py`: protocolo de trama serial del juego.
- `docs/diseño/planteamiento.md`: especificación y arquitectura del sistema.
- `docs/informe/informe.md`: documento técnico final del proyecto.
- `constraints/`: restricciones para la Basys 3 y documentación de uso.

## Arquitectura del sistema

El top de integración es `soc_top`. Instancia los siguientes bloques principales:

- `cpu`: procesador RV32I uniciclo.
- `instr_mem`: ROM con el firmware del juego.
- `soc_data_ram`: RAM de datos del sistema.
- `soc_interconnect`: decodificación de direcciones y multiplexación de lectura.
- `j1_input`: lectura de botones y switches del Jugador 1.
- `uart_top`: interfaz serial USB-UART.
- `display_7seg`: contador de victorias por jugador.
- `led_perifico`: LED de estado.
- `buzzer_perifico`: retroalimentación sonora.
- `vga_periph`: memoria de video y render del tablero.
- `vga_clock_gen`: generador de reloj para VGA.

La arquitectura usa dos rutas separadas:

- Bus de instrucciones: `ProgAddress_o` -> ROM -> `ProgInstr_i`.
- Bus de datos: `DataAddress_o`, `DataOut_o`, `DataIn_i`, `DataWriteEnable_o` con expansión MMIO.

El juego no depende de un controlador externo para validar el flujo. Todo el estado del partido, reglas del tablero y decisiones del juego se resuelven en firmware sobre la CPU.

## Aplicación del Jugador 2

El Jugador 2 trabaja con la terminal serial en Python. La interfaz requiere Python 3.10 o superior y una conexión USB-UART. La aplicación usa 115200 baudios, 8N1.

```bash
python -m pip install -r pc_app/requirements.txt
python pc_app/battleship_uart.py
```

También puede listarse el puerto disponible sin entrar al juego:

```bash
python pc_app/battleship_uart.py --list-ports
```

La terminal serial no reemplaza la lógica del juego; solo entrega comandos del jugador, recibe eventos del FPGA y representa el estado visible del tablero.

## Reproducción y síntesis

El repositorio incluye la jerarquía RTL del SoC y la documentación de restricciones del hardware, pero no incorpora un proyecto Vivado `.xpr` ni los archivos de IP generados. Para sintetizar o ejecutar la implementación física con Vivado, es necesario:

- abrir el proyecto o recrearlo con la jerarquía del repositorio,
- generar o importar los IP `clk_wiz_0` y `batalla_naval_mem` con los nombres y señales esperadas por RTL,
- cargar la XDC correcta para el top elegido (`soc_top` o `vga_top_dut_board`, según la etapa de prueba).

La documentación de restricciones queda en `constraints/README.md` y `constraints/Estructura_Constraints.md`.

## Archivos clave

- `modulos/src/top/soc_top.sv`: integración del sistema completo.
- `modulos/src/top/soc_interconnect.sv`: decodificación de direcciones y selección de periféricos.
- `modulos/src/peripheral/vga/vga_periph.sv`: periférico VGA y lógica de render.
- `modulos/src/uart/uart_top.sv`: periférico UART del sistema.
- `modulos/src/cpu/cpu.sv`: núcleo del procesador.
- `modulos/ensamblador/assembly.py`: assembler del proyecto.
- `pc_app/battleship_uart.py`: terminal del Jugador 2.

## Estado del proyecto

El proyecto se entrega en su versión final de documentación y RTL. La estructura de módulos, el firmware y la interfase de PC están alineados con la definición del diseño: el juego es funcional en términos de arquitectura del sistema, integración de periféricos y flujo de dos jugadores.
