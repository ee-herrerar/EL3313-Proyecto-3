`timescale 1ns/1ps
module soc_data_ram_tb;
    logic clk_i = 0;
    logic write_enable_i = 0;
    logic [31:0] address_i = 32'h0000_2000;
    logic [31:0] write_data_i = 0;
    logic [2:0] funct3_i = 3'b010;
    logic [31:0] read_data_o;

    soc_data_ram #(.DEPTH(4)) dut (.*);
    always #5 clk_i = ~clk_i;

    initial begin
        // Escribe en flanco opuesto al muestreo para evitar carreras de testbench.
        @(negedge clk_i);
        write_enable_i = 1;
        write_data_i = 32'hAABBCCDD;
        @(posedge clk_i); #1;
        write_enable_i = 0;

        address_i = 32'h0000_2001;
        funct3_i = 3'b000;
        #1; assert (read_data_o === 32'hFFFFFFCC)
            else $fatal(1, "LB lane 1 mismatch: %h", read_data_o);
        address_i = 32'h0000_2002;
        funct3_i = 3'b100;
        #1; assert (read_data_o === 32'h000000BB)
            else $fatal(1, "LBU lane 2 mismatch: %h", read_data_o);
        funct3_i = 3'b001;
        #1; assert (read_data_o === 32'hFFFFAABB)
            else $fatal(1, "LH upper half mismatch: %h", read_data_o);

        @(negedge clk_i);
        write_enable_i = 1;
        address_i = 32'h0000_2001;
        funct3_i = 3'b000;
        write_data_i = 32'h00000011;
        @(posedge clk_i); #1;
        write_enable_i = 0;
        funct3_i = 3'b010;
        #1; assert (read_data_o === 32'hAABB11DD)
            else $fatal(1, "SB lane 1 mismatch: %h", read_data_o);

        @(negedge clk_i);
        write_enable_i = 1;
        address_i = 32'h0000_2002;
        funct3_i = 3'b001;
        write_data_i = 32'h00001122;
        @(posedge clk_i); #1;
        write_enable_i = 0;
        address_i = 32'h0000_2000;
        funct3_i = 3'b010;
        #1; assert (read_data_o === 32'h112211DD)
            else $fatal(1, "SH upper half mismatch: %h", read_data_o);

        $display("soc_data_ram_tb: PASS");
        $finish;
    end
endmodule
