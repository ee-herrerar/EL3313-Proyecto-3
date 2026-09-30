`timescale 1ns/1ps

module soc_interconnect_tb;
    logic [31:0] address_i = 32'b0;
    logic write_enable_i = 1'b0;
    logic [31:0] ram_read_i = 32'h1111_1111;
    logic [31:0] uart_read_i = 32'h2222_2222;
    logic [31:0] gpio_read_i = 32'h3333_3333;
    logic [31:0] display_read_i = 32'h4444_4444;
    logic [31:0] led_read_i = 32'h5555_5555;
    logic [31:0] buzzer_read_i = 32'h6666_6666;
    logic [31:0] vga_read_i = 32'h7777_7777;
    logic [31:0] read_data_o;
    logic ram_write_enable_o;
    logic uart_write_enable_o;
    logic gpio_write_enable_o;
    logic display_write_enable_o;
    logic led_write_enable_o;
    logic buzzer_write_enable_o;
    logic vga_write_enable_o;
    logic [1:0] uart_addr_o;
    logic [1:0] gpio_addr_o;
    logic [1:0] display_addr_o;
    logic [1:0] led_addr_o;
    logic [1:0] buzzer_addr_o;

    soc_interconnect dut (.*);

    initial begin
        #1;
        address_i = 32'h0000_2000;
        #1;
        assert (read_data_o == ram_read_i)
            else $fatal(1, "RAM read mux failed");

        address_i = 32'h0001_0048;
        write_enable_i = 1'b1;
        #1;
        assert (read_data_o == uart_read_i && uart_addr_o == 2'b10)
            else $fatal(1, "UART read mux or register address failed");
        assert (uart_write_enable_o && !ram_write_enable_o &&
                !gpio_write_enable_o && !display_write_enable_o &&
                !led_write_enable_o && !buzzer_write_enable_o &&
                !vga_write_enable_o)
            else $fatal(1, "UART write decode failed");

        address_i = 32'h0001_1000;
        write_enable_i = 1'b0;
        #1;
        assert (read_data_o == vga_read_i)
            else $fatal(1, "VGA read mux failed");
        write_enable_i = 1'b1;
        #1;
        assert (vga_write_enable_o && !uart_write_enable_o)
            else $fatal(1, "VGA write decode failed");

        address_i = 32'h0000_3000;
        write_enable_i = 1'b0;
        #1;
        assert (read_data_o == 32'b0)
            else $fatal(1, "Unmapped read did not return zero");

        $display("soc_interconnect_tb: PASS");
        $finish;
    end
endmodule