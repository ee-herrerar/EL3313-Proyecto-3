# Constraints por etapa

Cada archivo XDC debe corresponder al top-level seleccionado en Vivado. No
cargue todos los XDC del directorio en un mismo proyecto.

| Etapa | Top-level | XDC | Uso |
|---|---|---|---|
| Demo VGA en Basys 3 | `vga_top_dut_board` | `vga_top_dut_basys3.xdc` | Reloj de 100 MHz, reset central y salidas VGA. Es una prueba de tiles, no integra CPU ni UART. |
| Terminal UART de PC | No hay top físico de prueba en RTL | Ninguno | `uart_top` es un periférico con bus; no es un top directamente conectable a la placa. |
| SoC Basys 3 | `soc_top` | `ConstraintsTop.xdc` | CPU, ROM, RAM, interconnect MMIO, UART, GPIO, VGA, displays, LED y buzzer. |

El XDC de demo VGA no debe reutilizarse para la integración final: sus nombres
y puertos corresponden únicamente a `vga_top_dut_board`.

La interfaz de juego se asigna a los cinco pulsadores y dos switches de la
Basys 3. `btnC` actúa como reset general; `btnU`, `btnD`, `btnL` y `btnR` son
las direcciones; `sw[1]` selecciona/rota y `sw[0]` confirma. Los switches son
entradas mantenidas, por lo que el jugador debe devolverlos a cero para
generar una nueva pulsación. El XDC asigna el buzzer a JA1 y la UART al puente
USB-UART integrado.