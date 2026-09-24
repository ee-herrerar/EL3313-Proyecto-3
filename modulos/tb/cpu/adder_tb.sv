module adder_tb;
    logic [31:0] in0, in1, out;
    adder dut (.*);
    initial begin
        in0 = 32'd7; in1 = 32'd5; #1;
        assert (out == 32'd12) else $fatal(1, "adder failed");
        $display("adder_tb: PASS"); $finish;
    end
endmodule
