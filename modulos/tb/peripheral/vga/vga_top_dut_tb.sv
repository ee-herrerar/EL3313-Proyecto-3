`timescale 1ns / 1ps

module vga_top_dut_tb;
    localparam logic [31:0] VGA_BASE = 32'h0001_1000;

    logic clk_cpu_i = 1'b0;
    logic clk_vga_i = 1'b0;
    logic rst_i = 1'b1;
    logic write_enable_i = 1'b0;
    logic [31:0] addr_i = 32'b0;
    logic [31:0] wdata_i = 32'b0;
    logic hsync_o;
    logic vsync_o;
    logic [3:0] vga_r_o;
    logic [3:0] vga_g_o;
    logic [3:0] vga_b_o;

    integer checks = 0;
    integer errors = 0;

    vga_top_dut dut (.*);

    always #5  clk_cpu_i = ~clk_cpu_i;
    always #20 clk_vga_i = ~clk_vga_i;

    task automatic write_tile(input integer index, input logic [2:0] color);
        begin
            @(negedge clk_cpu_i);
            write_enable_i = 1'b1;
            addr_i = VGA_BASE + (index * 4);
            wdata_i = {29'b0, color};
            @(negedge clk_cpu_i);
            write_enable_i = 1'b0;
        end
    endtask

    task automatic check_color(input integer x, input integer y,
                               input logic [11:0] expected,
                               input string label);
        begin
            wait (dut.u_vga_periph.u_sync.h_count == x &&
                  dut.u_vga_periph.u_sync.v_count == y);
            #1;
            checks = checks + 1;
            if ({vga_r_o, vga_g_o, vga_b_o} !== expected) begin
                errors = errors + 1;
                $display("FAIL %s: x=%0d y=%0d got=%h expected=%h",
                         label, x, y, {vga_r_o, vga_g_o, vga_b_o}, expected);
            end else begin
                $display("PASS %s", label);
            end
        end
    endtask

    initial begin
        repeat (3) @(posedge clk_vga_i);
        rst_i = 1'b0;

        write_tile(0,   3'b000);
        write_tile(1,   3'b001);
        write_tile(20,  3'b010);
        write_tile(21,  3'b011);
        write_tile(299, 3'b100);

        wait (dut.u_vga_periph.u_sync.h_count == 656);
        #1;
        if (hsync_o !== 1'b0 || vsync_o !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL horizontal sync pulse: hsync=%b vsync=%b", hsync_o, vsync_o);
        end else begin
            checks = checks + 1;
            $display("PASS horizontal sync pulse");
        end

        check_color(16,  16,  12'h00f, "agua");
        check_color(48,  16,  12'h888, "barco propio");
        check_color(16,  48,  12'hf00, "impacto");
        check_color(48,  48,  12'hfff, "fallo");
        check_color(624, 464, 12'h0f0, "tile final");

        wait (dut.u_vga_periph.u_sync.h_count == 640 &&
              dut.u_vga_periph.u_sync.v_count == 0);
        #1;
        checks = checks + 1;
        if ({vga_r_o, vga_g_o, vga_b_o} !== 12'h000) begin
            errors = errors + 1;
            $display("FAIL blanking: got=%h", {vga_r_o, vga_g_o, vga_b_o});
        end else begin
            $display("PASS horizontal blanking");
        end

        if (errors == 0)
            $display("VGA_TOP_DUT: %0d checks passed", checks);
        else
            $fatal(1, "VGA_TOP_DUT: %0d errors in %0d checks", errors, checks);
        $finish;
    end
endmodule
