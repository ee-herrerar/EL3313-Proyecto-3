`timescale 1ns/1ps
module buzzer_driver_tb;
    logic clk = 0, rst = 1;
    logic impacto_pulse = 0, fallo_pulse = 0, hundido_pulse = 0;
    logic invalido_pulse = 0, victoria_pulse = 0, buzzer_pwm;
    buzzer_driver #(.CLK_FREQ_HZ(1000), .IMPACTO_FREQ_HZ(100), .IMPACTO_MS(2),
        .FALLO_FREQ_HZ(50), .FALLO_MS(2), .HUNDIDO_FREQ_HZ(25), .HUNDIDO_MS(2),
        .INVALIDO_FREQ_HZ(20), .INVALIDO_MS(2), .VICTORIA_FREQ_HZ(10), .VICTORIA_MS(2)) dut (.*);
    always #5 clk = ~clk;

    initial begin
        repeat (2) @(posedge clk); rst = 0;
        impacto_pulse = 1; @(posedge clk); #1; impacto_pulse = 0;
        assert (buzzer_pwm == 0) else $fatal(1, "buzzer did not start low");
        repeat (5) @(posedge clk);
        assert (!$isunknown(buzzer_pwm)) else $fatal(1, "buzzer became unknown");
        repeat (5) @(posedge clk);
        $display("buzzer_driver_tb: PASS");
        $finish;
    end
endmodule
