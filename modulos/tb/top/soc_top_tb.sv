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
        @(negedge clk100mhz);
        btnC = 0;
        btnU = 1;
        btnD = 1;
        btnR = 1;
        sw = 2'b01;
        #1;
        assert (dut.btns == 7'b0110101)
            else $fatal(1, "SoC GPIO input mapping mismatch");
        repeat (20) @(posedge clk100mhz);
        assert (dut.clk_fpga === clk100mhz)
            else $fatal(1, "clk_fpga should follow the 100 MHz input");
        assert (dut.clock_locked)
            else $fatal(1, "Clocking Wizard model did not lock");
        assert (!$isunknown(uart_tx)) else $fatal(1, "SoC UART TX unknown");
        assert (!$isunknown(led)) else $fatal(1, "SoC LEDs unknown");
        $display("soc_top_tb: PASS (structural reset/elaboration)");
        $finish;
    end
endmodule
