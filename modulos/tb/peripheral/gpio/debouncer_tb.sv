`timescale 1ns/1ps
module debouncer_tb;
    logic clk = 0, reset = 1;
    logic [0:0] btn_in = 0;
    logic [0:0] btn_out;
    debouncer #(.N(1), .DEBOUNCE_CYCLES(3)) dut (.*);
    always #5 clk = ~clk;

    initial begin
        repeat (2) @(posedge clk);
        reset = 0;
        btn_in = 1;
        repeat (3) @(posedge clk);
        #1; assert (btn_out == 0) else $fatal(1, "debouncer accepted too early");
        @(posedge clk); #1; assert (btn_out == 1) else $fatal(1, "debouncer did not accept stable input");
        btn_in = 0;
        repeat (5) @(posedge clk);
        #1; assert (btn_out == 0) else $fatal(1, "debouncer did not release input");
        $display("debouncer_tb: PASS");
        $finish;
    end
endmodule
