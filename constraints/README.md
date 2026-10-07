# Constraints del proyecto final

Este documento consolidado describe la asignación de señales y la configuración final del SoC para la plataforma Digilent Basys 3. Los archivos de restricciones deben cargarse de forma selectiva según el top seleccionado; no se deben combinar todos los XDC en un mismo proyecto.

## Top-levels y uso

| Etapa | Top-level | XDC | Uso |
|---|---|---|---|
| Demostración VGA | `vga_top_dut_board` | `vga_top_dut_basys3.xdc` | Prueba de tiles y render VGA sin CPU ni UART. |
| SoC final | `soc_top` | `ConstraintsTop.xdc` | Integración completa del juego: CPU, ROM, RAM, MMIO, UART, GPIO, display, buzzer y VGA. |
| Terminal serial en PC | No hay top físico de prueba directo | Ninguno | La aplicación del Jugador 2 se comunica con el SoC a través del módulo UART del hardware. |

## Mapa de señales del SoC

El top `soc_top` usa las siguientes señales físicas de la Basys 3:

- `clk100mhz`: reloj principal de 100 MHz.
- `btnC`: reset general / validación de reinicio.
- `btnU`, `btnD`, `btnL`, `btnR`: movimiento del cursor y control del tablero.
- `sw[1]`: acción de rotación / selección secundaria.
- `sw[0]`: confirmación / acción final.
- `uart_rx` / `uart_tx`: comunicación serial USB-UART.
- `led[15:0]`: LED de estado del sistema.
- `seg[6:0]`, `an[3:0]`, `dp`: display 7 segmentos del marcador.
- `buzzer`: salida de retroalimentación sonora.
- `hsync`, `vsync`, `vgaRed[3:0]`, `vgaGreen[3:0]`, `vgaBlue[3:0]`: señales de VGA.

La asignación funcional del GPIO del Jugador 1 queda así:

- bit 6: `btnC` / reset general
- bit 5: `btnU` / arriba
- bit 4: `btnD` / abajo
- bit 3: `btnL` / izquierda
- bit 2: `btnR` / derecha
- bit 1: `sw[1]` / rotar
- bit 0: `sw[0]` / confirmar

## Requisitos de reloj y IP

La integración final usa un Clocking Wizard con la siguiente estructura:

- `clk_in1`: 100 MHz
- `clk_fpga`: 100 MHz para el sistema digital
- `clk_vga`: 25 MHz para el periférico VGA
- `reset`: activo en alto
- `locked`: señal de reloj estable

El nombre del componente debe conservarse como `clk_wiz_0` para que el wrapper RTL de `soc_top` funcione sin cambios. La ROM del proyecto usa el IP `batalla_naval_mem`, cuyo contenido corresponde al firmware del juego.

## Consideraciones de reproducción

El repositorio no incluye un proyecto Vivado `.xpr` ni archivos de configuración generados de IP. Para reproducir físicamente la referencia o sintetizar el diseño desde cero, debe ejecutarse la regeneración o importación del IP en Vivado según la jerarquía de `modulos/src` y la estructura de `constraints`.

Los archivos de CDGO/XDC deben mantenerse separados por top-level. El diseño general del SoC se valida con la arquitectura final y con los testbenches disponibles en `modulos/tb`, pero la configuración concreta del proyecto de implementación depende del entorno de Vivado y de los IP a generar en ese laboratorio.
