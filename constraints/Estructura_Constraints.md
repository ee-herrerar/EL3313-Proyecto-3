# Constraints por etapa

Cada archivo XDC debe corresponder al top-level seleccionado en Vivado. No
cargue todos los XDC del directorio en un mismo proyecto.

| Etapa | Top-level | XDC | Uso |
|---|---|---|---|
| Demo VGA en Basys 3 | `vga_top_dut_board` | `vga_top_dut_basys3.xdc` | Reloj de 100 MHz, reset central y salidas VGA. Es una prueba de tiles, no integra CPU ni UART. |
| Terminal UART de PC | No hay top físico de prueba en RTL | Ninguno | `uart_top` es un periférico con bus; no es un top directamente conectable a la placa. |
| Integración RTL del SoC en Basys 3 | `soc_top` | `ConstraintsTop.xdc` | Integración de CPU, ROM, RAM, bus y periféricos de placa. Es el top general disponible en RTL; no representa por sí mismo una partida completa ni una configuración Vivado reproducible. |

El XDC de demo VGA no debe reutilizarse con `soc_top`: sus nombres y puertos
corresponden únicamente a `vga_top_dut_board`. No cargue ambos XDC en una
misma configuración.

El top general asigna pines para los cinco pulsadores, dos switches, UART
integrada USB-UART, VGA, display, LED y buzzer en JA1. `ConstraintsTop.xdc`
todavía necesita una restricción `create_clock` de 100 MHz para análisis de
timing. Además, verifique en `constraints/README.md` la discrepancia entre el
orden actual de las entradas GPIO en RTL y el orden funcional documentado.

Para sintetizar `soc_top` también deben estar disponibles los IP
`clk_wiz_0` y `batalla_naval_mem`, instanciados desde RTL pero sin configuración
Vivado registrada en este repositorio.
