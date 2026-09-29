# Constraints por etapa

Cada archivo XDC debe corresponder al top-level seleccionado en Vivado. No
cargue todos los XDC del directorio en un mismo proyecto.

| Etapa | Top-level | XDC | Uso |
|---|---|---|---|
| Demo VGA en Basys 3 | `vga_top_dut_board` | `vga_top_dut_basys3.xdc` | Reloj de 100 MHz, reset central y salidas VGA. Es una prueba de tiles, no integra CPU ni UART. |
| Terminal UART de PC | No hay top físico de prueba en RTL | Ninguno | `uart_top` es un periférico con bus; no es un top directamente conectable a la placa. |
| SoC final | Aún no existe en el árbol | Pendiente | Crear el XDC cuando se defina el top y sus nombres de puertos para botones, UART, VGA, displays, LED y buzzer. |

El XDC de demo VGA no debe reutilizarse para la integración final: sus nombres
y puertos corresponden únicamente a `vga_top_dut_board`.

La Basys 3 dispone de cinco pulsadores, mientras que la interfaz del juego
requiere siete controles independientes. Antes de cerrar el top y el XDC final
se debe acordar si los dos controles restantes se asignan a switches o a
entradas externas, y validar esa decisión con el curso.