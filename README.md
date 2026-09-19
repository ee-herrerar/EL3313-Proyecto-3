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
│   │   ├── alu.sv            # Unidad aritmético-lógica rv32i
│   │   ├── branch_comp.sv    # Comparador de saltos condicionales
│   │   ├── control_unit.sv   # Decodificador de control combinacional
│   │   ├── imm_gen.sv        # Generador de inmediatos (I, S, B, U, J)
│   │   ├── pc_reg.sv         # Contador de programa y lógica de siguiente PC
│   │   ├── register_file.sv  # Banco de 32 registros de 32 bits
│   │   └── riscv_core.sv     # Top del procesador (datapath + control)
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
│   ├── sistema_computo.sv     # Integración SoC (Core + Memorias + Interconexión)
│   └── basys3_top.sv          # Top RTL físico para la FPGA Basys 3
├── constraints/
│   └── basys3_master.xdc      # Mapeo de pines y restricciones temporales
├── tb/
│   ├── Testbench x Módulo y Top
├── docs/
│   ├── informe.md             # Documentación técnica final del sistema
│   ├── planteamiento.md       # Planteamiento de arquitectura top-down
└── README.md                  # Guía general del repositorio y flujo de trabajo
```