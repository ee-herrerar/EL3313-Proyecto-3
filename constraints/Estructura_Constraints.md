# Constraints por etapa

Cada archivo XDC debe corresponder al top-level seleccionado en Vivado. No
cargue todos los XDC del directorio en un mismo proyecto.

| Etapa | Top-level | XDC | Uso |
|---|---|---|---|
| Demo VGA en Basys 3 | `vga_top_dut_board` | `vga_top_dut_basys3.xdc` | Reloj de 100 MHz, reset central y salidas VGA. Es una prueba de tiles, no integra CPU ni UART. |
| Terminal UART de PC | No hay top físico de prueba en RTL | Ninguno | `uart_top` es un periférico con bus; no es un top directamente conectable a la placa. |
| Top general de placa | `soc_top` | `ConstraintsTop.xdc` | Armazón de integración Basys3 con CPU, GPIO, UART, VGA, displays, LED y buzzer. |

El XDC de demo VGA no debe reutilizarse para la integración final: sus nombres
y puertos corresponden únicamente a `vga_top_dut_board`.

El top general usa los cinco pulsadores y dos switches como las siete entradas
del periférico GPIO. La conexión del buzzer se asigna a JA1 y la UART usa el
puente USB-UART integrado de la Basys3.