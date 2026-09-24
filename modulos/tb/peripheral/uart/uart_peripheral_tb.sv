`timescale 1ns/1ps
module uart_peripheral_tb;
    logic clk_i = 0, rst_i = 1, write_enable_i = 0;
    logic [1:0] addr_i = 0;
    logic [31:0] wdata_i = 0, rdata_o;
    logic rx = 1, tx;
    uart_peripheral #(.SYS_CLK_FREQ(1000), .BAUD_RATE(10), .OVERSAMPLE(4)) dut (.*);
    always #5 clk_i = ~clk_i;
    initial begin
        repeat (2) @(posedge clk_i); #1;
        assert (rdata_o == 0) else $fatal(1, "UART peripheral reset failed");
        rst_i = 0; write_enable_i = 1; addr_i = 2'b01; wdata_i = 32'hC3;
        @(posedge clk_i); #1; write_enable_i = 0; addr_i = 2'b00;
        assert (!$isunknown(rdata_o)) else $fatal(1, "UART peripheral status became unknown");
        repeat (100) @(posedge clk_i);
        assert (!$isunknown(tx)) else $fatal(1, "UART peripheral TX unknown");
        $display("uart_peripheral_tb: PASS");
        $finish;
    end
endmodule
