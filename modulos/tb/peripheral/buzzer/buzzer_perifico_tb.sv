`timescale 1ns/1ps
module buzzer_perifico_tb;
    logic clk_i = 0, rst_i = 1, write_enable_i = 0;
    logic [1:0] addr_i = 0;
    logic [31:0] wdata_i = 0, rdata_o;
    logic buzzer_pwm;
    buzzer_perifico dut (.*);
    always #5 clk_i = ~clk_i;

    initial begin
        repeat (2) @(posedge clk_i); #1; assert (rdata_o == 0) else $fatal(1, "buzzer reset failed");
        rst_i = 0; write_enable_i = 1; wdata_i = 32'd1;
        #1; assert (rdata_o == 32'd1) else $fatal(1, "buzzer event readback failed");
        @(posedge clk_i); #1; write_enable_i = 0;
        assert (!$isunknown(buzzer_pwm)) else $fatal(1, "buzzer output unknown");
        $display("buzzer_perifico_tb: PASS");
        $finish;
    end
endmodule
