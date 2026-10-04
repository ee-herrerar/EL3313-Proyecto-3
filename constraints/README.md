# Constraints por etapa

Cada archivo XDC debe corresponder al top-level seleccionado en Vivado. No
cargue todos los XDC del directorio en un mismo proyecto.

| Etapa | Top-level | XDC | Uso |
|---|---|---|---|
| Demo VGA en Basys 3 | `vga_top_dut_board` | `vga_top_dut_basys3.xdc` | Reloj de 100 MHz, reset central y salidas VGA. Es una prueba de tiles, no integra CPU ni UART. |
| Terminal UART de PC | No hay top físico de prueba en RTL | Ninguno | `uart_top` es un periférico con bus; no es un top directamente conectable a la placa. |
| Integración RTL del SoC en Basys 3 | `soc_top` | `ConstraintsTop.xdc` | Asigna pines de reloj, botones/switches, UART, VGA, displays, LED y buzzer. Es el top general disponible en RTL; no implica que el juego completo esté terminado. |

El SoC instancia `uart_top`; `uart_peripheral` es una implementación
alternativa sin instancia en esta jerarquía. La demo VGA usa un top y puertos
distintos, por lo que no se debe combinar su XDC con `ConstraintsTop.xdc`.

La interfaz de juego se asigna a los cinco pulsadores y dos switches de la
Basys 3. `btnC` actúa como reset general; `btnU`, `btnD`, `btnL` y `btnR` son
las direcciones; `sw[1]` selecciona/rota y `sw[0]` confirma. Los switches son
entradas mantenidas, por lo que el jugador debe devolverlos a cero para
generar una nueva pulsación. El XDC asigna el buzzer a JA1 y la UART al puente
USB-UART integrado.
## Pendientes para una configuración reproducible

- `ConstraintsTop.xdc` asigna pines, pero todavía no contiene `create_clock`
  para el reloj de 100 MHz. Añada la restricción de timing antes de considerar
  completo el análisis temporal.
- `soc_top` instancia los IP `clk_wiz_0` y `batalla_naval_mem`. El repositorio
  no incluye un `.xpr` ni la configuración/fuentes generadas de esos IP; deben
  agregarse o regenerarse en Vivado.
- La tarjeta proporciona cinco pulsadores y dos switches para las siete
  entradas de `j1_input`. La concatenación RTL actual conecta
  `btns[6:0] = {btnC, btnU, btnD, btnL, btnR, sw[1:0]}`; este orden no coincide
  con la asignación funcional de navegación, selección y confirmación descrita
  en `docs/diseño/planteamiento.md`. Corrija la conexión RTL o acuerde y
  documente una asignación funcional distinta antes de la demostración.
- Las fuentes marcadas como deshabilitadas para síntesis del SoC no deben
  excluirse del conjunto de simulación si se necesitan para sus testbenches.

La tabla de top/XDC y los límites por etapa se mantienen también en
[`Estructura_Constraints.md`](Estructura_Constraints.md).
