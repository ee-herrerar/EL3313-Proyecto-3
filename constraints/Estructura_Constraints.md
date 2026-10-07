# Estructura de constraints por etapa

Cada archivo XDC debe asociarse al top-level que corresponda. La carga de todos los archivos de constraints de una vez no es recomendada ni representa el uso final del sistema.

| Etapa | Top-level | XDC | Uso |
|---|---|---|---|
| Demo VGA | `vga_top_dut_board` | `vga_top_dut_basys3.xdc` | Verificación visual de tiles y render en la Basys 3. |
| SoC final del proyecto | `soc_top` | `ConstraintsTop.xdc` | Integración completa del juego: CPU, memoria, periféricos y VGA. |
| Interfaz serial PC | No aplica a un top físico | Ninguno | La terminal del Jugador 2 se conecta por USB-UART con el periférico UART del SoC. |

## Reglas de uso

- `vga_top_dut_board` y `soc_top` tienen puertos y lógica diferentes; no se deben mezclar sus XDC en la misma configuración.
- `uart_top` es un periférico del sistema, no un top de placa independiente.
- El proyecto final utiliza el reloj de 100 MHz de la Basys 3, con salida del Clocking Wizard a 100 MHz para el sistema y 25 MHz para VGA.

## Mapeo de GPIO y periféricos

El SoC mapea los periféricos de la siguiente manera:

| Periférico | Base | Rango |
|---|---|---|
| UART | `0x0001_0040` | 12 bytes |
| GPIO / botones | `0x0001_0120` | 4 bytes |
| Display 7 segmentos | `0x0001_0130` | 4 bytes |
| LED | `0x0001_0138` | 4 bytes |
| Buzzer | `0x0001_0140` | 4 bytes |
| VGA | `0x0001_1000` | 2048 bytes |

El GPIO del Jugador 1 expone los 7 bits de entrada del juego:

- `btnC` / reset general (bit 6)
- `btnU` / arriba (bit 5)
- `btnD` / abajo (bit 4)
- `btnL` / izquierda (bit 3)
- `btnR` / derecha (bit 2)
- `sw[1]` / rotar (bit 1)
- `sw[0]` / confirmar (bit 0)

## Requisitos del flujo de implementación

Para la implementación reproducible en Vivado:

1. conservar el nombre `clk_wiz_0` para el Clocking Wizard;
2. mantener `clk_in1` a 100 MHz;
3. habilitar `clk_fpga` a 100 MHz y `clk_vga` a 25 MHz;
4. mantener el reset y la salida `locked` en el wrapper generado;
5. incluir el IP `batalla_naval_mem` según corresponda a la ROM del firmware;
6. cargar el XDC apropiado a cada top-level.

La documentación de restricciones funcionales del proyecto queda en `constraints/README.md` y se complementa con la estructura de cada top en este archivo.
