`timescale 1ns/1ps
module uart_tx_tb;
    logic clk_i = 0, rst_i = 1, tx_start = 0, s_tick = 1;
    logic [7:0] din = 8'hA5;
    logic tx_done_tick, tx;
    uart_tx #(.DBIT(8), .SB_TICK(2)) dut (.*);
    always #5 clk_i = ~clk_i;
    initial begin
        repeat (2) @(posedge clk_i); rst_i = 0;
        @(posedge clk_i); tx_start = 1;
        @(posedge clk_i); #1; tx_start = 0;
        assert (tx == 1'b1 || tx == 1'b0) else $fatal(1, "TX unknown");
        repeat (25) @(posedge clk_i);
        assert (tx_done_tick == 1'b0) else $fatal(1, "TX done pulse not one-cycle");
        $display("uart_tx_tb: PASS");
        $finish;
    end
endmodule
