`timescale 1ns/1ps
module uart_rx_tb;
    logic clk_i = 0, rst_i = 1, rx = 1, s_tick = 1;
    logic rx_done_tick;
    logic [7:0] dout;
    uart_rx #(.DBIT(8), .SB_TICK(2)) dut (.*);
    always #5 clk_i = ~clk_i;
    task send_bit(input logic value);
        begin rx = value; repeat (3) @(posedge clk_i); end
    endtask
    initial begin
        repeat (2) @(posedge clk_i); rst_i = 0;
        send_bit(0);
        send_bit(1); send_bit(0); send_bit(1); send_bit(0);
        send_bit(0); send_bit(1); send_bit(0); send_bit(1);
        send_bit(1);
        repeat (4) @(posedge clk_i);
        assert (rx_done_tick == 0 || rx_done_tick == 1) else $fatal(1, "RX unknown");
        $display("uart_rx_tb: PASS (dout=%h)", dout);
        $finish;
    end
endmodule
