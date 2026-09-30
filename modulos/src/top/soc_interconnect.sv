module soc_interconnect (
    input  logic [31:0] address_i,
    input  logic        write_enable_i,
    input  logic [31:0] ram_read_i,
    input  logic [31:0] uart_read_i,
    input  logic [31:0] gpio_read_i,
    input  logic [31:0] display_read_i,
    input  logic [31:0] led_read_i,
    input  logic [31:0] buzzer_read_i,
    input  logic [31:0] vga_read_i,
    output logic [31:0] read_data_o,
    output logic        ram_write_enable_o,
    output logic        uart_write_enable_o,
    output logic        gpio_write_enable_o,
    output logic        display_write_enable_o,
    output logic        led_write_enable_o,
    output logic        buzzer_write_enable_o,
    output logic        vga_write_enable_o,
    output logic [1:0]  uart_addr_o,
    output logic [1:0]  gpio_addr_o,
    output logic [1:0]  display_addr_o,
    output logic [1:0]  led_addr_o,
    output logic [1:0]  buzzer_addr_o
);

    localparam logic [31:0] UART_BASE = 32'h0001_0040;
    localparam logic [31:0] GPIO_BASE = 32'h0001_0120;
    localparam logic [31:0] DISPLAY_BASE = 32'h0001_0130;
    localparam logic [31:0] LED_BASE = 32'h0001_0138;
    localparam logic [31:0] BUZZER_BASE = 32'h0001_0140;
    localparam logic [31:0] VGA_BASE = 32'h0001_1000;

    logic ram_select;
    logic uart_select;
    logic gpio_select;
    logic display_select;
    logic led_select;
    logic buzzer_select;
    logic vga_select;

    assign ram_select = (address_i >= 32'h0000_2000) &&
                        (address_i <  32'h0000_3000);
    assign uart_select = (address_i >= UART_BASE) &&
                         (address_i < UART_BASE + 32'h0000_000C);
    assign gpio_select = (address_i >= GPIO_BASE) &&
                         (address_i < GPIO_BASE + 32'h0000_0004);
    assign display_select = (address_i >= DISPLAY_BASE) &&
                            (address_i < DISPLAY_BASE + 32'h0000_0004);
    assign led_select = (address_i >= LED_BASE) &&
                        (address_i < LED_BASE + 32'h0000_0004);
    assign buzzer_select = (address_i >= BUZZER_BASE) &&
                           (address_i < BUZZER_BASE + 32'h0000_0004);
    assign vga_select = (address_i >= VGA_BASE) &&
                        (address_i < VGA_BASE + 32'h0000_0800);

    assign ram_write_enable_o = write_enable_i && ram_select;
    assign uart_write_enable_o = write_enable_i && uart_select;
    assign gpio_write_enable_o = write_enable_i && gpio_select;
    assign display_write_enable_o = write_enable_i && display_select;
    assign led_write_enable_o = write_enable_i && led_select;
    assign buzzer_write_enable_o = write_enable_i && buzzer_select;
    assign vga_write_enable_o = write_enable_i && vga_select;

    assign uart_addr_o = (address_i - UART_BASE) >> 2;
    assign gpio_addr_o = (address_i - GPIO_BASE) >> 2;
    assign display_addr_o = (address_i - DISPLAY_BASE) >> 2;
    assign led_addr_o = (address_i - LED_BASE) >> 2;
    assign buzzer_addr_o = (address_i - BUZZER_BASE) >> 2;

    always_comb begin
        read_data_o = 32'b0;
        if (ram_select)
            read_data_o = ram_read_i;
        else if (uart_select)
            read_data_o = uart_read_i;
        else if (gpio_select)
            read_data_o = gpio_read_i;
        else if (display_select)
            read_data_o = display_read_i;
        else if (led_select)
            read_data_o = led_read_i;
        else if (buzzer_select)
            read_data_o = buzzer_read_i;
        else if (vga_select)
            read_data_o = vga_read_i;
    end

endmodule