# EL3313-Proyecto-3

El siguiente proyecto es para el desarrollo del proyecto 3 del curso _EL3313:  Taller de Diseño Digital_.

Distribución tentativa de archivos:
```bash
.
├── asm/
│   ├── battleship.asm        # Código fuente en ensamblador RISC-V (rv32i)
│   └── program.mem           # Archivo hexadecimal para inicialización de ROM
├── pc_app/
│   ├── main.py               # Interfaz remota en Python para el Jugador 2
│   └── requirements.txt      # Dependencias de la aplicación (pyserial)
├── rtl/
│   ├── core/
│   │   ├── ALU.sv              # Unidad aritmético-lógica
│   │   ├── Extend.sv           # Generador de inmediatos
│   │   ├── adder.sv            # Sumador genérico de 32 bits
│   │   ├── alu_decoder.sv      # Decodificación de operación de la ALU
│   │   ├── control_unit.sv     # Unidad de control del procesador
│   │   ├── datapath.sv         # Camino de datos del procesador uniciclo
│   │   ├── main_decoder.sv     # Decodificador principal de instrucciones
│   │   ├── mux21.sv            # Multiplexor 2:1 de 32 bits
│   │   ├── mux41.sv            # Multiplexor 4:1 de 32 bits
│   │   ├── pc.sv               # Registro del contador de programa
│   │   ├── reg_file.sv         # Banco de 32 registros de 32 bits
│   │   └── riscv_core.sv       # Top del procesador uniciclo    # Top del procesador (datapath + control)
│   ├── memory/
│   │   ├── ram.sv            # Memoria RAM de datos (0x00002000–0x00002FFF)
│   │   └── rom.sv            # Memoria ROM de programa (0x00000000–0x00001FFF)
│   ├── peripherals/
│   │   ├── audio/
│   │   │   └── buzzer_pwm.sv # Generador PWM de tonos
│   │   ├── display/
│   │   │   ├── display_7seg.sv # Controlador multiplexado de 4 dígitos BCD
│   │   │   └── led_estado.sv   # Registro e indicadores LED de estado
│   │   ├── gpio/
│   │   │   ├── debouncer.sv    # Filtro anti-rebotes para botones
│   │   │   └── player1_input.sv # Registro de estado de entradas del Jugador 1
│   │   ├── uart/
│   │   │   ├── baud_gen.sv     # Generador de reloj a 115200 baudios
│   │   │   ├── uart_periph.sv  # Interfaz de registros Control/Estado, TX, RX
│   │   │   ├── uart_rx.sv      # Receptor serie
│   │   │   └── uart_tx.sv      # Transmisor serie
│   │   └── vga/
│   │       ├── tile_map_ram.sv # Memoria de video Dual-Port (100 MHz / 25 MHz)
│   │       ├── tile_renderer.sv # Generador de pixeles por bloque/HUD
│   │       ├── vga_periph.sv   # Módulo top del periférico VGA
│   │       └── vga_sync.sv     # Sincronismos VGA 640x480@60Hz
│   ├── interconnect/
│   │   └── bus_interconnect.sv # Decodificador de direcciones y MUX de lectura
│   ├── clock/
│   │       └── clock_gen.sv
│   ├── sistema_computo.sv     # Integración SoC: Core + ROM + RAM + Bus + UART + VGA + GPIO + Displays + LED + Buzzer
│   └── basys3_top.sv          # Top RTL físico para la FPGA Basys 3
├── constraints/
│   └── basys3_master.xdc      # Mapeo de pines y restricciones temporales
├── tb/
│   ├── core/
│   │   ├── alu_tb.sv
│   │   ├── register_file_tb.sv
│   │   ├── branch_comp_tb.sv
│   │   ├── riscv_core_tb.sv
│   │   └── imm_gen_tb.sv
│   ├── peripherals/
│   │   ├── uart_tb.sv
│   │   ├── gpio_tb.sv
│   │   ├── buzzer_tb.sv
│   │   └── vga_tb.sv
│   ├── interconnect/
│   │   └── bus_interconnect_tb.sv
│   └── sistema/
│       └── sistema_computo_tb.sv
docs/
├── diseño/
│   └── planteamiento.md
├── informe/
│    └── informe.md       # Planteamiento de arquitectura top-down
└── README.md                  # Guía general del repositorio y flujo de trabajo
```