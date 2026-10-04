`timescale 1ns/1ps
module uart_tx_tb;
    logic clk_i = 0, rst_i = 1, tx_start = 0, s_tick = 1;
    logic [7:0] din = 8'hA5;
    logic tx_done_tick, tx;
    localparam integer TICKS_PER_BIT = 16;
    integer done_count = 0;
    uart_tx #(.DBIT(8), .SB_TICK(TICKS_PER_BIT)) dut (.*);
    always #5 clk_i = ~clk_i;
    always @(posedge clk_i)
        if (tx_done_tick) done_count = done_count + 1;

    initial begin
        repeat (2) @(posedge clk_i);
        @(negedge clk_i);
        rst_i = 0;
        tx_start = 1;
        @(negedge clk_i);
        tx_start = 0;
        // START y cada bit se mantienen durante TICKS_PER_BIT ciclos.
        repeat (TICKS_PER_BIT) begin
            @(posedge clk_i); #1;
            assert (tx === 1'b0) else $fatal(1, "TX start bit incorrect");
        end
        for (int bit_index = 0; bit_index < 8; bit_index++) begin
            repeat (TICKS_PER_BIT) begin
                @(posedge clk_i); #1;
                assert (tx === din[bit_index])
                    else $fatal(1, "TX data bit %0d incorrect: got %b", bit_index, tx);
            end
        end
        repeat (TICKS_PER_BIT) begin
            @(posedge clk_i); #1;
            assert (tx === 1'b1) else $fatal(1, "TX stop bit incorrect");
        end
        assert (tx_done_tick === 1'b0 && done_count == 1)
            else $fatal(1, "TX completion pulse count was %0d", done_count);
        $display("uart_tx_tb: PASS");
        $finish;
    end
endmodule
