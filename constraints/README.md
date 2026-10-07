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
Basys 3. `btnC` actúa como reset general y GPIO bit 6; `btnU`, `btnD`, `btnL` y
`btnR` son las direcciones (arriba bit 5, abajo bit 4, izquierda bit 3,
derecha bit 2); `sw[1]` rota (bit 1) y `sw[0]` confirma (bit 0). La
correspondencia coincide con las máscaras del firmware ensamblador y está
implementada en `soc_top`. Los switches son entradas mantenidas, por lo que el
jugador debe devolverlos a cero para generar una nueva pulsación. El XDC
asigna el buzzer a JA1 y la UART al puente USB-UART integrado.

El XDC declara el oscilador de entrada de 100 MHz. `clk_wiz_0` debe tener
`clk_in1` a 100 MHz y dos salidas: `clk_fpga` a 100 MHz para el sistema y
`clk_vga` a 25 MHz para VGA. El Clocking Wizard propaga las restricciones de
los relojes generados a partir de este reloj primario.

Al crear/configurar el IP en Vivado, use el nombre de componente `clk_wiz_0`,
habilite las salidas `clk_fpga` y `clk_vga` con esas frecuencias, y exponga
`reset` (activo en alto) y `locked`. El wrapper RTL conecta directamente esos
puertos; no renombre la entrada `clk_in1`.
## Pendientes para una configuración reproducible

- `soc_top` instancia los IP `clk_wiz_0` y `batalla_naval_mem`. El repositorio
  no incluye un `.xpr` ni la configuración/fuentes generadas de esos IP; deben
  agregarse o regenerarse en Vivado.
- `clk_wiz_0` y `batalla_naval_mem` no tienen archivos de configuración Vivado
  versionados en el repositorio. Configure el Clocking Wizard según los nombres
  y frecuencias anteriores antes de sintetizar.
- Las fuentes marcadas como deshabilitadas para síntesis del SoC no deben
  excluirse del conjunto de simulación si se necesitan para sus testbenches.

La tabla de top/XDC y los límites por etapa se mantienen también en
[`Estructura_Constraints.md`](Estructura_Constraints.md).
