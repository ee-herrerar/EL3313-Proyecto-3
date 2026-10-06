# Documentación técnica

## Informe técnico — Proyecto 3:  Batalla Naval
Curso: EL3313 Taller de Diseño Digital

Semestre: II Semestre 2026

Proyecto: Batalla Naval: juego de dos jugadores sobre un microprocesador RISC-V con periférico VGA

Plataforma FPGA: Digilent Basys 3

### Resumen 
### Introducción 
El objetivo de este proyecto es la implementación del juego batalla naval ("Battleship") integrando elementos como un microprocesador basado en la arquitectura RISC-V, lógica del juego en lenguaje ensamblador, periféricos mapeados a memoria y la generación de video con VGA. El batalla naval puede ser jugado por dos jugadores a la vez, donde de el jugador 1 interactúa por medio de la FPGA, utilizando los botones locales para colocar barcos y disparar, mientras observa el transcurso de la partida desde el monitor VGA, por otro lado, el jugador 2 interactúa con el juego por medio de una aplicación de PC (Python) que se comunica con la FPGA mediante protocolo UART.   

Para este proyecto la lógica del juego reside únicamente en el programa escrito en ensamblador y ejecutado por el microprocesador, este ultimo se comunica con el resto de periféricos, recibiendo y enviando señales por medio de un bus de datos de tres líneas (address, write, read), lo que permite a los jugadores interactuar con el juego a través de los botones de la FPGA o la PC y observar el desarrollo de la partida. A lo largo de este trabajo se usaran conceptos aprendidos en cursos anteriores, en proyectos pasados o que se investigaron para esta implementación. (continuar)  
### Fundamentación Teórica

#### Juego en ensamblador 
#### Microprocesador 
#### ALU
La unidad aritmética lógica en un procesador es la encargada de realizar operaciones aritméticas, lógicas o desplazamientos, esta tiene 3 entradas, 2 para cada operando de 32 bits (`SrcA` y `SrcB`) y una señal de control de 4 bits para indicar la operación (`ALUControl`), a partir de estas genera una señal de salida de 32 bits (`ALUResult`). Para evaluar condiciones de salto la ALU también genera las señales `less` y `zero`, estas son evaluados en la unidad de control. 

<p align="center">
  <b>Figura 1. Diagrama de unidad aritmética lógica  </b> 
</p>
<p align="center">
  <img src="../diseño/Imagenes/ALU.png" width="200">
</p>

#### Banco de registros   
La unidad de registros esta compuesta por 32 registros cada uno de 32 bits y funciona para escritura y lectura. Existen varios tipos de registro: registros temporales, registros de guardado, punteros, cero, etc. En modo lectura con la instrucción `lw` se pueden recuperar elementos almacenados en el registro utilizando su dirección, en el modo de escritura por otro lado, se pueden escribir los datos usando `sw`. En este proyecto el nombre del modulo es `reg_file`, este permite dos lecturas simultáneas mediante las salidas `RD1` y `RD2`, y una escritura mediante la entrada `WD3`, las direcciones de registro se indican con las señales `A1`, `A2` y `A3`.  
La estructura se realiza por medio de las señales `RegWrite` (de la unidad de control) y `WD3` las cuales determinan si se debe realizar una escritura, al realizarse, se escribe el valor de la señal `Result` en el registro designado. Las salidas `RD1` y `RD2` corresponden al contenido de los registros seleccionados por `A1` y `A2`, `RD1` es el primer operando del ALU y `RD2` puede usarse como segundo operando o para escritura en memoria. Cuándo `A1` o `A2` seleccionan al registro `x0` la salida respectiva es 0, aunque las operaciones de escritura sobre 0 son ignoradas. 

<p align="center">
  <b>Figura 2. Diagrama de banco de registros </b> 
</p>
<p align="center">
  <img src="../diseño/Imagenes/BancoReg.png" width="300">
</p>

##### Generador de inmediatos


##### Comparador de branch

##### Contador de programa
Este modulo recibe la dirección de la instrucción y la mantiene durante el periodo, una vez se completa la instrucción el contador aumenta cuatro. El modulo mantiene la dirección de 32 bits llamada `PC` en el código y la actualiza en cada flanco de reloj `clk`, el valor nuevo que se almacenara tiene por nombre `PCnext` y es generado por el mux del datapath `u_pcmux`. En la siguiente figura se presenta la relación de estas señales con el contador:

<p align="center">
  <b>Figura 3. Diagrama del contador del programa </b> 
</p>
<p align="center">
  <img src="../diseño/Imagenes/PC.png" width="300">
</p>


##### Unidad de control
Esta unidad se encarga de controlar el resto de módulos por medio de señales de control basadas en la instrucción actual recibida del datapath, a partir de esto guía el comportamiento del mismo. 


#### Periférico: VGA
VGA (Video Graphics Array) es un estándar de visualización en monitores analógicos con una resolución de 640x480@60Hz (resolución que se usara en este caso), que indica 640 pixeles de ancho y 480 pixeles de alto con una frecuencia de actualización de pantalla de 60Hz. La FPGA basys 3 sintetiza el controlador de la VGA, este se encarga de generar pulsos de sincronización verticales y horizontales que coordinen la presentación de video en la pantalla (sincronismos), también se encarga de acceder a la memoria de video y aplicar los datos conforme se va recorriendo cada pixel, actualizando la información de cada uno []. El controlador realiza la coordinación según el reloj la VGA de 25MHz, el cual también es generado por la FPGA.    

Para la aplicación de este periférico se genero un modulo de sincronismos `vga_sync`, este en encarga de recorrer las direcciones de cada pixel, para la actualización en la pantalla los cambios que realice el CPU en la memoria de video, también es el modulo que genera las señales de sincronización horizontal y vertical `vsync` y `hsync`. Para la memoria de video se genero el modulo `tile_map_ram`, la cual es una memoria de doble puerto que recibe los datos del CPU desde el modulo `vga_periph` como escritura y para luego ser leídos por el modulo que renderiza los tiles `tile_renderer`. `tile_renderer` se encarga de generar las señales RGB a partir del la información de la memoria de video y de del pixel que se este recorriendo en un momento especifico. `vga_periph` funciona como una interfaz que recibe la información del CPU y envía la información de RGB, `hsync` y `vsync` a los pines del conector VGA. En la tabla 1 se muestra la información utilizada para la coordinación del video en `vga_sync`:

Tabla 1. Tiempos y pixeles de VGA.
| Description | Time | Pixels |
| :--- | :--- | :--- |
| Visible area (Horizontal) | 25.422 μs | 640 |
| Horizontal Sync Time | 3.813 μs | 96 |
| Horizontal Back Porch | 1.907 μs | 48 |
| Horizontal Front Porch | 0.636 μs | 16 |
| Whole Horizontal Line | 31.777 μs | 800 |
| Visible area (Vertical) | 15.253 ms | 480 Lines |
| Vertical Sync Time | 0.064 ms | 2 Lines |
| Vertical Back Porch | 1.048 ms | 33 Lines |
| Vertical Front Porch | 0.318 ms | 10 Lines |
| Whole Vertical Line | 16.683 μs | 525 | 

#### Protocolo UART y aplicación PC

La UART (Universal Asynchronous Receiver/Transmitter) es un enlace serial asíncrono sin línea de reloj compartida. Cada byte se encapsula en una trama 8N1: 1 bit de inicio (nivel bajo), 8 bits de datos enviados LSB primero, ningún bit de paridad y 1 bit de parada (nivel alto). La línea en reposo permanece en alto.

Como transmisor y receptor no comparten reloj, el receptor debe reconstruir la temporización a partir del flanco de bajada del bit de inicio. Para ello se usa sobremuestreo 16×: un generador produce un pulso s_tick a 16 veces la tasa de baudios, y el receptor cuenta ticks para ubicar el muestreo en el centro de cada bit, donde la señal es más estable y se maximiza la tolerancia a errores de frecuencia.

Además, rx es una entrada asíncrona al dominio de reloj de 100 MHz, por lo que debe pasar por un sincronizador de dos flip-flops para reducir la probabilidad de metaestabilidad.

En este proyecto la UART es el único canal del Jugador 2 con la partida, a 115200 baudios (requisito de la sección 4.5.3 del enunciado). Se reutiliza el diseño del Proyecto 2 con la interfaz de registros solicitada.


| Módulo	| Función |
| :--- | :--- |
|uart_generador_baudios |	Divisor de frecuencia que genera s_tick a 16 × BAUD_RATE. |
|uart_rx |	Receptor: sincronizador de 2 FF + FSM de 4 estados + registro de desplazamiento. |
|uart_tx | Transmisor: FSM de 4 estados + registro de desplazamiento. |
|uart_top |	Envoltura con interfaz estándar de periféricos, banderas de estado y mapeo en memoria. |

Generador de baudios:

Parámetros: SYS_CLK_FREQ = 100 MHz, BAUD_RATE = 115200, OVERSAMPLE = 16.

$$\text{DIVISOR} = \left\lfloor \frac{100\,000\,000}{115\,200 \times 16} \right\rfloor = \lfloor 54{,}25 \rfloor = 54$$

Un contador de $clog2(54) = 6 bits cuenta de 0 a DIVISOR-1 = 53 y emite s_tick durante un ciclo de reloj al llegar al final, reiniciándose a 0.

El truncamiento a entero introduce un error de 0,47 %, muy inferior a la tolerancia típica de una UART 8N1 (≈ ±3 a ±5 % acumulado en la trama), por lo que no se requiere un divisor fraccionario. La comunicación con pyserial a 115200 es compatible.

Diagrama de estados receceptor:

<img width="491" height="451" alt="fsm_receptor" src="https://github.com/user-attachments/assets/5db07a30-931b-4e23-87f5-145742e62fc7" />


Sincronización: rx_sync_0 → rx_sync (dos FF, inicializados en 1 para que el reset equivalga a línea en reposo).

IDLE: espera el flanco de bajada (rx_sync = 0) y reinicia el contador de ticks.

START: cuenta 8 ticks (SB_TICK/2) para posicionarse en el centro del bit de inicio. Esto sirve además de filtro de glitches de corta duración.

DATA: cada 16 ticks (un bit completo, es decir, el centro del siguiente bit) desplaza rx_sync por el extremo MSB de b_reg (desplazamiento a la derecha, LSB llega primero). Tras 8 bits pasa a STOP.

STOP: espera 16 ticks más y emite rx_done_tick durante un ciclo. Los datos quedan disponibles en dout.

Todos los puntos de muestreo caen a 8 + 16·k ticks del flanco detectado, es decir, en el centro de cada bit con una incertidumbre de ±1 tick (±1/16 de bit) por la asincronía entre el flanco y s_tick.

Diagrama de estados transmisor:

<img width="358" height="278" alt="fsm_transmisor" src="https://github.com/user-attachments/assets/ca1636fa-58b1-4787-8114-3cbf65c93238" />


La salida tx proviene de un registro (tx_reg), lo que evita glitches en el pin físico.

El byte se captura en b_reg en el ciclo en que llega tx_start, por lo que wdata_i solo debe ser válido durante la escritura.

tx_start se ignora si la FSM no está en IDLE; por eso el software debe consultar tx_busy antes de escribir.


Interfaz con el CPU y mapa de registros:

Interfaz estándar de periféricos: clk_i, rst_i, write_enable_i, addr_i[1:0], wdata_i[31:0], rdata_o[31:0]. Los pines físicos son rx_pin y tx_pin.

| Módulo	| offset | Direccion | addr_i | Acceso | Lectura| 
| :--- | :--- | :--- | :--- |  :--- | :--- |
|Control/Estado |	0x00 |	0x0001_0040	| 00 |	Lectura | bit 0 = tx_busy, bit 1 = rx_valid, resto 0|
|Datos TX |	0x04|	0x0001_0044	| 01	| Escritura	| bits [7:0] = byte a transmitir (lectura devuelve 0)|
|Datos RX |	0x08|	0x0001_0048 |	10	| Lectura	| bits [7:0] = último byte recibido|

Decisiones de diseño y justificación:

Sobremuestreo 16×: permite muestrear en el centro del bit y tolerar el desajuste entre relojes; es la estructura clásica para UART en FPGA y reutiliza el diseño validado en el Proyecto 2.

Sincronizador de 2 FF en rx: la señal proviene de otro dominio (PC); sin él puede haber metaestabilidad.

FSM de dos procesos (registro + lógica combinacional) con valores por defecto: evita latches y facilita el análisis, tal como exige el enunciado.

Limpieza de rx_valid por lectura: el software no necesita un acceso de escritura adicional para reconocer el dato, lo que simplifica el lazo de sondeo en ensamblador.

Sondeo (polling) en lugar de interrupciones: el subconjunto rv32i requerido no incluye CSR ni manejo de interrupciones; el programa único y determinístico consulta las banderas.

El periférico solo forma tramas a nivel de bit: no conoce el protocolo de aplicación ni las reglas del juego, cumpliendo la sección 4.1 del enunciado.

Consideraciones de integración y limitaciones:

Sin FIFO ni detección de sobreescritura: el periférico tiene un único registro de recepción. Un byte llega cada 86,4 µs como mínimo (≈ 8 640 ciclos); el programa debe sondear rx_valid con una frecuencia mayor y leer el byte antes de que llegue el siguiente. 

Las tramas del protocolo de aplicación deben diseñarse con esto en mente (por ejemplo, respuestas de la FPGA cortas y fáciles de procesar).

Sin bit de error de trama: uart_rx no valida el bit de parada. Cualquier byte inválido se descarta en la capa de aplicación (requisito de la sección 4.5.3).
Efecto de lectura: como la limpieza de rx_valid ocurre ante cualquier ciclo de lectura con addr_i = 10, el decodificador de direcciones del top debe calificar el acceso con la selección de periférico (rango 0x0001_0040–0x0001_004F). De lo contrario, la lectura de otro periférico cuyo offset coincida en addr_i[1:0] (por ejemplo, el LED en 0x0001_0138) borraría la bandera sin que el CPU haya leído el dato.

Reset: el diseño usa reset asíncrono en activo alto (posedge rst_i). Se recomienda que el top sincronice la liberación del reset al reloj del sistema.
Condición de carrera en tx_busy: una escritura a Datos TX con la FSM en STOP justo en el ciclo de tx_done_tick dejaría tx_busy en 1 sin transmisión. No ocurre si el software respeta el sondeo de tx_busy antes de escribir.


[insertar diagramas]

#### Periféricos
##### Displays

Los displays de 7 segmentos de la tarjeta (ánodo común) comparten las líneas de segmentos entre los dígitos, y cada dígito se habilita con su propio ánodo. Para mostrar varios dígitos con pocos pines se emplea multiplexación temporal: en cada instante solo un dígito está encendido, y la persistencia de la visión da la ilusión de que todos permanecen activos si la tasa de refresco supera aproximadamente 60 Hz por dígito.

Ánodos y segmentos son activos en bajo (an = 0 habilita el dígito; seg[i] = 0 enciende el segmento). El orden de seg es {g,f,e,d,c,b,a}.

En el proyecto, los displays muestran el contador acumulado de partidas ganadas (00–99) de cada jugador desde el último reinicio general.

##### Botones

El periférico j1_input implementa la interfaz de lectura de las entradas físicas del Jugador 1 (botones de la tarjeta FPGA) siguiendo la interfaz estándar de periféricos de registros definida en la especificación del proyecto: clk_i, rst_i, write_enable_i, addr_i[1:0], wdata_i[31:0] y rdata_o[31:0]. El periférico expone un único registro de ESTADO en la dirección addr_i = 2'b00, correspondiente a la dirección mapeada 0x0001_0120 del mapa de memoria del sistema.

Las entradas físicas se reciben por el puerto btns_in[6:0], que agrupa los siete botones requeridos por la especificación: navegación (arriba, abajo, izquierda, derecha), selección/rotación (BTN_SEL), confirmación (BTN_OK) y reinicio (BTN_RST). El mapeo exacto de bits 
##### Buzzer 

El periférico buzzer implementa la generación de retroalimentación sonora distintiva para los cinco eventos requeridos por la especificación: impacto, fallo, barco hundido, colocación inválida y victoria. Sigue la interfaz estándar de periféricos de registros y expone un único registro de CONTROL en addr_i = 2'b00, correspondiente a la dirección mapeada 0x0001_0140.

El CPU escribe en el registro de control un código de evento de 3 bits (wdata_i[2:0]) para disparar la señal sonora correspondiente. La Tabla 2 documenta la codificación.

### Presentación de Resultados 

### Análisis e interpretación de resultados 

### Conclusiones  

 
