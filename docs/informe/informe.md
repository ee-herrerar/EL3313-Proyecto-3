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
#### Periférico: VGA
VGA (Video Graphics Array) es un estándar de visualización en monitores analógicos con una resolución de 640x480@60Hz (resolución que se usara en este caso), que indica 640 pixeles de ancho y 480 pixeles de alto con una frecuencia de actualización de pantalla de 60Hz. La FPGA basys 3 sintetiza el controlador de la VGA, este se encarga de generar pulsos de sincronización verticales y horizontales que coordinen la presentación de video en la pantalla (sincronismos), también se encarga de acceder a la memoria de video y aplicar los datos conforme se va recorriendo cada pixel, actualizando la información de cada uno []. El controlador realiza la coordinación según el reloj la VGA de 25MHz, el cual también es generado por la FPGA.    

Para la aplicación de este periférico se genero un modulo de sincronismos "sync", este en encarga de recorrer la direcciones de cada pixel, para actualizar en la pantalla los cambios que realice el CPU en la memoria de video (continuar) 

#### Protocolo UART y aplicación PC
#### Periféricos
##### Displays
##### Botones
##### Buzzer 

### Presentación de Resultados 

### Análisis e interpretación de resultados 

### Conclusiones  

 
