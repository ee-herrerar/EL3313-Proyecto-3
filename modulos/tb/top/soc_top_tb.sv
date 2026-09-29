`timescale 1ns/1ps
module soc_top_tb;
    logic clk100mhz = 0, btnC = 1;
    logic btnU = 0, btnD = 0, btnL = 0, btnR = 0;
    logic [1:0] sw = 0;
    logic uart_rx = 1, uart_tx;
    logic [3:0] vgaRed, vgaGreen, vgaBlue;
    logic hsync, vsync, buzzer;
    logic [15:0] led;
    logic [6:0] seg;
    logic dp;
    logic [3:0] an;

    soc_top dut (.*);
    always #5 clk100mhz = ~clk100mhz;

    initial begin
        repeat (3) @(posedge clk100mhz);
        btnC = 0;
        repeat (20) @(posedge clk100mhz);
        assert (!$isunknown(uart_tx)) else $fatal(1, "SoC UART TX unknown");
        assert (!$isunknown(led)) else $fatal(1, "SoC LEDs unknown");
        $display("soc_top_tb: PASS (structural reset/elaboration)");
        $finish;
    end
endmodule
