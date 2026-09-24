`timescale 1ns/1ps
module j1_input_tb;
    logic clk = 0, rst_i = 1, write_enable_i = 0;
    logic [1:0] addr_i = 0;
    logic [31:0] wdata_i = 0, rdata_o;
    logic [5:0] btns_in = 0;
    j1_input dut (
        .clk_i(clk),
        .rst_i(rst_i),
        .write_enable_i(write_enable_i),
        .addr_i(addr_i),
        .wdata_i(wdata_i),
        .rdata_o(rdata_o),
        .btns_in(btns_in)
    );
    always #5 clk = ~clk;

    initial begin
        repeat (2) @(posedge clk);
        #1; assert (rdata_o == 0) else $fatal(1, "GPIO reset failed");
        rst_i = 0;
        btns_in = 6'b010101;
        repeat (4) @(posedge clk);
        #1; assert (rdata_o[5:0] == 6'b0) else $fatal(1, "GPIO bypassed debounce");
        write_enable_i = 1;
        #1; assert (rdata_o == 0) else $fatal(1, "GPIO write did not suppress read");
        $display("j1_input_tb: PASS");
        $finish;
    end
endmodule
