module mux21_tb;
    logic sel; logic [31:0] in0, in1, out;
    mux21 dut (.*);
    initial begin
        in0 = 32'h11; in1 = 32'h22; sel = 0; #1; assert (out == in0) else $fatal(1, "mux21 sel0 failed");
        sel = 1; #1; assert (out == in1) else $fatal(1, "mux21 sel1 failed");
        $display("mux21_tb: PASS"); $finish;
    end
endmodule
