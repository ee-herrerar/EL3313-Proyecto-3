`timescale 1ns/1ps
module uart_rx_tb;
    logic clk_i = 0, rst_i = 1, rx = 1, s_tick = 1;
    logic rx_done_tick;
    logic [7:0] dout;
    localparam integer TICKS_PER_BIT = 16;
    uart_rx #(.DBIT(8), .SB_TICK(TICKS_PER_BIT)) dut (.*);
    always #5 clk_i = ~clk_i;
    task automatic send_bit(input logic value);
        begin
            @(negedge clk_i);
            rx = value;
            repeat (TICKS_PER_BIT) @(posedge clk_i);
        end
    endtask

    initial begin
        repeat (2) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 0;
        // UART serializa primero el bit menos significativo.
        send_bit(0);
        send_bit(1); send_bit(0); send_bit(1); send_bit(0);
        send_bit(0); send_bit(1); send_bit(0); send_bit(1);
        send_bit(1);
        wait (rx_done_tick === 1'b1);
        #1;
        assert (dout === 8'hA5) else $fatal(1, "RX byte mismatch: got %h expected A5", dout);
        $display("uart_rx_tb: PASS (dout=%h)", dout);
        $finish;
    end
endmodule
