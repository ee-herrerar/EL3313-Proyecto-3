`timescale 1ns/1ps
module vga_top_dut_board_tb;
    logic clk100mhz = 0, btnC = 0;
    logic hsync, vsync;
    logic [3:0] vgaRed, vgaGreen, vgaBlue;
    vga_top_dut_board dut (.*);
    always #5 clk100mhz = ~clk100mhz;

    initial begin
        #1; btnC = 1;
        repeat (2) @(posedge clk100mhz);
        btnC = 0;
        repeat (700) @(posedge clk100mhz);
        $display("vga_top_dut_board_tb: SMOKE PASS (hsync=%b vsync=%b)", hsync, vsync);
        $finish;
    end
endmodule
