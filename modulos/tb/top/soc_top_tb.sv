`timescale 1ns/1ps
module soc_top_tb;
    logic clk_100mhz = 0, clk_25mhz_tb = 0, btn_rst = 1;
    logic uart_rx = 1, uart_tx;
    logic btn_up = 0, btn_down = 0, btn_left = 0, btn_right = 0, btn_sel = 0, btn_ok = 0;
    logic [3:0] vga_r, vga_g, vga_b;
    logic vga_hsync, vga_vsync, buzzer_out;
    logic [15:0] leds;
    logic [7:0] seg;
    logic [3:0] an;

    soc_top dut (.*);
    always #5 clk_100mhz = ~clk_100mhz;
    always #20 clk_25mhz_tb = ~clk_25mhz_tb;

    initial begin
        force dut.clk_25mhz = clk_25mhz_tb;
        repeat (3) @(posedge clk_100mhz);
        btn_rst = 0;
        repeat (20) @(posedge clk_100mhz);
        assert (!$isunknown(uart_tx)) else $fatal(1, "SoC UART TX unknown");
        assert (!$isunknown(leds)) else $fatal(1, "SoC LEDs unknown");
        release dut.clk_25mhz;
        $display("soc_top_tb: PASS (structural reset/elaboration)");
        $finish;
    end
endmodule
