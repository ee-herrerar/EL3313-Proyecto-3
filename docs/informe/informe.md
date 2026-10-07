# Informe técnico final — Proyecto 3: Batalla Naval sobre microprocesador RISC-V

## Resumen

Este proyecto implementa un sistema completo de Batalla Naval para dos jugadores sobre un SoC basado en RISC-V RV32I. El diseño integra un procesador uniciclo, memoria ROM/RAM, periféricos mapeados en memoria, UART para comunicación con una aplicación de PC, lógica VGA para la representación del tablero y un conjunto de periféricos de entrada/salida para la interacción del Jugador 1. La lógica del juego se ejecuta en firmware de ensamblador sobre el microprocesador; la aplicación en Python funciona únicamente como terminal remota del Jugador 2.

## 1. Introducción

El objetivo principal del proyecto es integrar, en una sola plataforma digital, la lógica del juego, el procesamiento de instrucciones del microprocesador y la interfaz con periféricos. El sistema final contempla dos modos de interacción:

- Jugador 1: utiliza la FPGA, observa el juego en VGA y accede al sistema con botones y switches.
- Jugador 2: interactúa desde una PC con una aplicación serial basada en Python.

La solución se apoya en la arquitectura de un SoC con buses de programa y de datos separados. La ROM contiene el firmware con la máquina de estados del juego, mientras que la RAM y los periféricos se acceden mediante memoria mapeada.

## 2. Arquitectura general del sistema

El diseño está centrado en el top-level `soc_top`, que integra:

- `cpu`: procesador RV32I uniciclo.
- `instr_mem`: ROM de instrucciones.
- `soc_data_ram`: RAM de datos.
- `soc_interconnect`: decodificador de direcciones y multiplexor de lectura.
- `j1_input`: GPIO de entrada para botones/switches.
- `uart_top`: periférico UART para la comunicación con la PC.
- `display_7seg`: contador acumulado de victorias.
- `led_perifico`: salida de estado general.
- `buzzer_perifico`: señales sonoras de eventos.
- `vga_periph`: memoria de video y generación de video para el tablero.
- `vga_clock_gen`: reloj de 25 MHz para la salida VGA.

### 2.1 Buses del sistema

El sistema usa dos rutas principales:

- Bus de instrucciones: `ProgAddress_o` -> ROM -> `ProgInstr_i`.
- Bus de datos: direccionamiento MMIO para RAM y periféricos.

La interconexión utiliza selección por rango de dirección y multiplexación de lectura. La lógica del juego no se ejecuta en el PC; solo se interpreta en la CPU.

## 3. Microprocesador RV32I

El núcleo del proyecto es un procesador en una sola etapa (uniciclo), con soporte para las instrucciones del conjunto base RV32I requerido por el firmware del juego. El flujo sigue el esquema clásico:

1. fetch desde ROM;
2. decodificación en la unidad de control;
3. acceso a registros y memoria;
4. ejecución en la ALU;
5. escritura de resultados y control de flujo.

Los módulos relevantes son:

- `main_decoder.sv`
- `alu_decoder.sv`
- `control_unit.sv`
- `datapath.sv`
- `reg_file.sv`
- `ALU.sv`
- `Extend.sv`

La ALU cubre operaciones aritméticas, lógicas y comparaciones; el datapath y la unidad de control resuelven la toma de decisiones del flujo del programa, incluyendo saltos condicionales y de subrutina.

## 4. Memoria y mapeo de periféricos

La RAM y los periféricos se acceden mediante direcciones mapeadas en memoria. La tabla muestra los rangos definidos en `soc_interconnect.sv`.

| Periférico | Base | Rango de acceso |
|---|---|---|
| UART | `0x0001_0040` | `0x0001_0040` a `0x0001_004B` |
| GPIO / botones | `0x0001_0120` | `0x0001_0120` a `0x0001_0123` |
| Display 7 segmentos | `0x0001_0130` | `0x0001_0130` a `0x0001_0133` |
| LED | `0x0001_0138` | `0x0001_0138` a `0x0001_013B` |
| Buzzer | `0x0001_0140` | `0x0001_0140` a `0x0001_0143` |
| VGA | `0x0001_1000` | `0x0001_1000` a `0x0001_17FF` |

La RAM de datos se usa para el estado del juego, contadores, tableros y variables del firmware. La arquitectura hace que la aplicación del Jugador 2 sólo envíe entradas al sistema por UART; la validación final se mantiene en la CPU.

## 5. Interfaz del Jugador 1

El periférico de entrada `j1_input` sincroniza, filtra y convierte la señal física de los botones/switches en palabras de 32 bits accesibles desde el bus MMIO. Los bits funcionales del sistema son:

- bit 6: `btnC` / reset general
- bit 5: `btnU` / arriba
- bit 4: `btnD` / abajo
- bit 3: `btnL` / izquierda
- bit 2: `btnR` / derecha
- bit 1: `sw[1]` / rotar
- bit 0: `sw[0]` / confirmar

La lógica de debouncing y sincronización evita rebotes y metabilidad al conectar señales asíncronas de la placa con el dominio del reloj del sistema.

## 6. Periféricos de salida

### 6.1 UART

El módulo `uart_top` representa la capa de comunicación entre la FPGA y la aplicación en PC. La terminal serial se configura en 115200 baudios, 8N1, y usa una capa de protocolo para tramas de comando y respuesta. El diseño es compatible con la estructura del programa del Jugador 2 y la lógica del juego en ensamblador.

### 6.2 VGA

El módulo `vga_periph` maneja la memoria de video, el render del tablero y las señales de sincronización `hsync` y `vsync`. Se integra con el reloj de 25 MHz generado por `vga_clock_gen`, y trabaja sobre una memoria de tiles por celda para mostrar el estado del tablero, impactos, barcos y mensajes del HUD.

### 6.3 Display y buzzer

El display 7 segmentos sirve como marcador de victorias por jugador. El buzzer ofrece retroalimentación sonora para eventos del juego como impacto, fallo, colocación inválida, barco hundido y victoria.

## 7. Firmware y lógica del juego

La programación del juego se desarrolla en lenguaje ensamblador y se genera con el script `modulos/ensamblador/assembly.py`. La ROM del sistema se alimenta con ese firmware; la lógica del juego incluye:

- colocación inicial de barcos,
- turnos alternados,
- validación de entradas del Jugador 1 y del Jugador 2,
- control del tablero,
- detección de impactos y hundimientos,
- manejo del estado final del partido,
- interacción con periféricos de salida.

La aplicación Python no implementa la lógica del juego; es una terminal de entrada/salida del Jugador 2. El control de reglas se mantiene dentro del microprocesador para cumplir el planteamiento del proyecto.

## 8. Protocolo de aplicación para UART

El protocolo serial se define en `pc_app/uart_protocol.py` y en la aplicación hija `battleship_uart.py`. El flujo del sistema incluye tramas de comando y eventos de estado, con delimitadores, longitud y control de errores. La comunicación se realiza con formato compacto para evitar sobrecarga del CPU y mantener un flujo determinista del juego.

## 9. Bancos de prueba y validación

El repositorio incluye una batería de tests SystemVerilog en `modulos/tb` para validar módulos clave del diseño:

- `cpu/`: ALU, datapath, decodificadores, control unit, registros, memoria de instrucciones, memoria de datos, instrucciones RV32I.
- `peripheral/gpio/`: sincronizador, debouncer y entrada de botones.
- `peripheral/uart/`: transmisor, receptor, generador de baudios, UART de sistema.
- `peripheral/vga/`: tiles, render, sync y top de demostración VGA.
- `top/`: RAM de datos, interconexión MMIO y top del SoC.

Estos testbenches son la base de la validación funcional del diseño y cubren los módulos de CPU, periféricos y top-level del sistema.

## 10. Conclusión

El proyecto final queda documentado como una implementación coherente de un SoC de Batalla Naval sobre RISC-V con periféricos VGA y UART. La documentación, la infraestructura de módulos y la arquitectura expuesta en el repositorio están alineadas con la versión final del sistema: el diseño del hardware y la lógica del firmware resuelven el juego completo bajo un modelo de dos jugadores y memoria mapeada en la FPGA.
