## ========================================================================
## ConstraintsTop.xdc
## Proyecto: Batalla Naval
## FPGA: Basys 3 - XC7A35T-1CPG236C
## Top-level: soc_top
## ========================================================================


## ========================================================================
## CLOCK - 100 MHz
## ========================================================================

set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk100mhz]

create_clock \
    -name sys_clk \
    -period 10.000 \
    -waveform {0 5} \
    [get_ports clk100mhz]


## ========================================================================
## PUSH BUTTONS
##
## btnC = Reset
## btnU = Arriba
## btnD = Abajo
## btnL = Izquierda
## btnR = Derecha
## ========================================================================

set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btnC]

set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports btnU]

set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports btnD]

set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports btnL]

set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports btnR]


## ========================================================================
## SWITCHES
##
## sw[0] = Confirmar
## sw[1] = Rotar barco
## ========================================================================

set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]

set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]


## ========================================================================
## USB UART
##
## IMPORTANTE:
##
## B18 = datos PC -> FPGA = uart_rx
## A18 = datos FPGA -> PC = uart_tx
## ========================================================================

set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports uart_rx]

set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports uart_tx]


## ========================================================================
## LEDs
## ========================================================================

set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]

set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]

set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]

set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {led[4]}]

set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {led[5]}]

set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {led[6]}]

set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {led[7]}]

set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {led[8]}]

set_property -dict { PACKAGE_PIN V3 IOSTANDARD LVCMOS33 } [get_ports {led[9]}]

set_property -dict { PACKAGE_PIN W3 IOSTANDARD LVCMOS33 } [get_ports {led[10]}]

set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports {led[11]}]

set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS33 } [get_ports {led[12]}]

set_property -dict { PACKAGE_PIN N3 IOSTANDARD LVCMOS33 } [get_ports {led[13]}]

set_property -dict { PACKAGE_PIN P1 IOSTANDARD LVCMOS33 } [get_ports {led[14]}]

set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS33 } [get_ports {led[15]}]


## ========================================================================
## 7-SEGMENT DISPLAY
##
## seg[0] = A
## seg[1] = B
## seg[2] = C
## seg[3] = D
## seg[4] = E
## seg[5] = F
## seg[6] = G
## ========================================================================

set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]

set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]

set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]

set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]

set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]

set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]

set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]


## Decimal point

set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports dp]


## Digit enables

set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports {an[0]}]

set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports {an[1]}]

set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports {an[2]}]

set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports {an[3]}]


## ========================================================================
## BUZZER
##
## Pmod JA1
##
## Basys 3:
## JA1 = FPGA package pin J1
## ========================================================================

set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports buzzer]


## ========================================================================
## VGA - RED
## ========================================================================

set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {vgaRed[0]}]

set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {vgaRed[1]}]

set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports {vgaRed[2]}]

set_property -dict { PACKAGE_PIN N19 IOSTANDARD LVCMOS33 } [get_ports {vgaRed[3]}]


## ========================================================================
## VGA - GREEN
## ========================================================================

set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[0]}]

set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[1]}]

set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[2]}]

set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[3]}]


## ========================================================================
## VGA - BLUE
## ========================================================================

set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[0]}]

set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[1]}]

set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[2]}]

set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[3]}]


## ========================================================================
## VGA SYNCHRONIZATION
## ========================================================================

set_property -dict { PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports hsync]

set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports vsync]


## ========================================================================
## FPGA CONFIGURATION
## ========================================================================

set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property CFGBVS VCCO [current_design]