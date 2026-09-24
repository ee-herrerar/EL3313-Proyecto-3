`timescale 1ns/1ps
module sync_tb;
    logic clk = 0, reset = 1;
    logic [5:0] async_signal = 0;
    logic [5:0] sync_signal;
    sync #(.N(6)) dut (.*);
    always #5 clk = ~clk;

    initial begin
        repeat (2) @(posedge clk);
        #1;
        assert (sync_signal == 0) else $fatal(1, "sync reset failed");
        reset = 0;
        async_signal = 6'b101011;
        @(posedge clk); #1; assert (sync_signal == 0) else $fatal(1, "sync changed too early");
        @(posedge clk); #1; assert (sync_signal == 6'b101011) else $fatal(1, "sync did not delay input");
        $display("sync_tb: PASS");
        $finish;
    end
endmodule
