module mux41_tb;
    logic [1:0] sel; logic [31:0] in0, in1, in2, in3, out;
    mux41 dut (.*);
    initial begin
        in0 = 0; in1 = 1; in2 = 2; in3 = 3;
        for (int i = 0; i < 4; i++) begin sel = i; #1; assert (out == i) else $fatal(1, "mux41 failed for %0d", i); end
        $display("mux41_tb: PASS"); $finish;
    end
endmodule
