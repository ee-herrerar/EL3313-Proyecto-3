module soc_top (
    input  logic        clk100mhz,
    input  logic        btnC,
    input  logic        btnU,
    input  logic        btnD,
    input  logic        btnL,
    input  logic        btnR,
    input  logic [1:0]  sw,
    input  logic        uart_rx,
    output logic        uart_tx,
    output logic [15:0] led,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [3:0]  an,
    output logic        buzzer,
    output logic        hsync,
    output logic        vsync,
    output logic [3:0]  vgaRed,
    output logic [3:0]  vgaGreen,
    output logic [3:0]  vgaBlue
);

    localparam logic [31:0] UART_BASE = 32'h0001_0040;
    localparam logic [31:0] GPIO_BASE = 32'h0001_0120;
    localparam logic [31:0] DISPLAY_BASE = 32'h0001_0130;
    localparam logic [31:0] LED_BASE = 32'h0001_0138;
    localparam logic [31:0] BUZZER_BASE = 32'h0001_0140;
    localparam logic [31:0] VGA_BASE = 32'h0001_1000;
    localparam logic [31:0] VGA_LIMIT = 32'h0001_1800;

    logic clk_vga;
    logic vga_clock_locked;
    logic vga_reset;
    logic [6:0] btns;
    logic [31:0] prog_address;
    logic [31:0] prog_instr;
    logic [31:0] data_address;
    logic [31:0] data_write;
    logic [31:0] data_read;
    logic [2:0] data_funct3;
    logic data_write_enable;

    logic [31:0] ram_read;
    logic [31:0] gpio_read;
    logic [31:0] uart_read;
    logic [31:0] display_read;
    logic [31:0] led_read;
    logic [31:0] buzzer_read;

    logic ram_select;
    logic uart_select;
    logic gpio_select;
    logic display_select;
    logic led_select;
    logic buzzer_select;
    logic vga_select;

    logic [1:0] uart_addr;
    logic [1:0] gpio_addr;
    logic [1:0] display_addr;
    logic [1:0] led_addr;
    logic [1:0] buzzer_addr;

    assign btns = {btnC, btnU, btnD, btnL, btnR, sw};
    assign vga_reset = btnC || !vga_clock_locked;

    assign ram_select = (data_address >= 32'h0000_2000) &&
                        (data_address < 32'h0000_3000);
    assign uart_select = (data_address >= UART_BASE) &&
                         (data_address < UART_BASE + 32'h0000_000C);
    assign gpio_select = (data_address >= GPIO_BASE) &&
                         (data_address < GPIO_BASE + 32'h0000_0004);
    assign display_select = (data_address >= DISPLAY_BASE) &&
                            (data_address < DISPLAY_BASE + 32'h0000_0004);
    assign led_select = (data_address >= LED_BASE) &&
                        (data_address < LED_BASE + 32'h0000_0004);
    assign buzzer_select = (data_address >= BUZZER_BASE) &&
                           (data_address < BUZZER_BASE + 32'h0000_0004);
    assign vga_select = (data_address >= VGA_BASE) &&
                        (data_address < VGA_LIMIT);

    assign uart_addr = (data_address - UART_BASE) >> 2;
    assign gpio_addr = (data_address - GPIO_BASE) >> 2;
    assign display_addr = (data_address - DISPLAY_BASE) >> 2;
    assign led_addr = (data_address - LED_BASE) >> 2;
    assign buzzer_addr = (data_address - BUZZER_BASE) >> 2;

    always_comb begin
        data_read = 32'b0;
        if (ram_select)
            data_read = ram_read;
        else if (uart_select)
            data_read = uart_read;
        else if (gpio_select)
            data_read = gpio_read;
        else if (display_select)
            data_read = display_read;
        else if (led_select)
            data_read = led_read;
        else if (buzzer_select)
            data_read = buzzer_read;
    end

    vga_clock_gen u_vga_clock (
        .clk100_i (clk100mhz),
        .rst_i    (btnC),
        .clk25_o  (clk_vga),
        .locked_o (vga_clock_locked)
    );

    instr_mem u_program_rom (
        .A  (prog_address),
        .RD (prog_instr)
    );

    cpu u_cpu (
        .clk                (clk100mhz),
        .rst                (btnC),
        .ProgInstr_i        (prog_instr),
        .ProgAddress_o      (prog_address),
        .DataIn_i           (data_read),
        .DataAddress_o      (data_address),
        .DataOut_o          (data_write),
        .DataFunct3_o       (data_funct3),
        .DataWriteEnable_o  (data_write_enable)
    );

    soc_data_ram u_data_ram (
        .clk_i          (clk100mhz),
        .write_enable_i (data_write_enable && ram_select),
        .address_i      (data_address),
        .write_data_i   (data_write),
        .funct3_i       (data_funct3),
        .read_data_o    (ram_read)
    );

    j1_input u_gpio (
        .clk_i          (clk100mhz),
        .rst_i          (btnC),
        .write_enable_i (data_write_enable && gpio_select),
        .addr_i         (gpio_addr),
        .wdata_i        (data_write),
        .rdata_o        (gpio_read),
        .btns_in        (btns)
    );

    led_perifico u_led (
        .clk_i          (clk100mhz),
        .rst_i          (btnC),
        .write_enable_i (data_write_enable && led_select),
        .addr_i         (led_addr),
        .wdata_i        (data_write),
        .rdata_o        (led_read),
        .led            (led)
    );

    display_7seg u_display (
        .clk_i          (clk100mhz),
        .rst_i          (btnC),
        .write_enable_i (data_write_enable && display_select),
        .addr_i         (display_addr),
        .wdata_i        (data_write),
        .rdata_o        (display_read),
        .an             (an),
        .dp             (dp),
        .seg            (seg)
    );

    buzzer_perifico u_buzzer (
        .clk_i          (clk100mhz),
        .rst_i          (btnC),
        .write_enable_i (data_write_enable && buzzer_select),
        .addr_i         (buzzer_addr),
        .wdata_i        (data_write),
        .rdata_o        (buzzer_read),
        .buzzer_pwm     (buzzer)
    );

    uart_top u_uart (
        .clk_i          (clk100mhz),
        .rst_i          (btnC),
        .write_enable_i (data_write_enable && uart_select),
        .addr_i         (uart_addr),
        .wdata_i        (data_write),
        .rdata_o        (uart_read),
        .rx_pin         (uart_rx),
        .tx_pin         (uart_tx)
    );

    vga_periph u_vga (
        .clk_cpu_i      (clk100mhz),
        .rst_i          (vga_reset),
        .write_enable_i (data_write_enable && vga_select),
        .addr_i         (data_address),
        .wdata_i        (data_write),
        .clk_vga_i      (clk_vga),
        .hsync_o        (hsync),
        .vsync_o        (vsync),
        .vga_r_o        (vgaRed),
        .vga_g_o        (vgaGreen),
        .vga_b_o        (vgaBlue)
    );

endmodule
