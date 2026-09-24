`timescale 1ns/1ps
module uart_generador_baudios_tb;
    logic clk_i = 0, rst_i = 1, s_tick;
    uart_generador_baudios #(.SYS_CLK_FREQ(1000), .BAUD_RATE(10), .OVERSAMPLE(4)) dut (.*);
    always #5 clk_i = ~clk_i;
    int ticks;
    initial begin
        ticks = 0;
        repeat (2) @(posedge clk_i); rst_i = 0;
        repeat (60) begin @(posedge clk_i); #1; ticks += s_tick; end
        assert (ticks == 2) else $fatal(1, "expected 2 baud ticks, got %0d", ticks);
        $display("uart_generador_baudios_tb: PASS");
        $finish;
    end
endmodule
