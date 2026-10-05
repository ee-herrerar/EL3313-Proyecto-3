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

    logic clk_fpga;
    logic clk_vga;
    logic clock_locked;
    logic system_reset;
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
    logic [31:0] vga_read;

    logic ram_write_enable;
    logic uart_write_enable;
    logic gpio_write_enable;
    logic display_write_enable;
    logic led_write_enable;
    logic buzzer_write_enable;
    logic vga_write_enable;

    logic [1:0] uart_addr;
    logic [1:0] gpio_addr;
    logic [1:0] display_addr;
    logic [1:0] led_addr;
    logic [1:0] buzzer_addr;

    // GPIO bits [6:0] = reset, up, down, left, right, rotate, confirm.
    assign btns = {btnC, btnU, btnD, btnL, btnR, sw[1], sw[0]};
    assign system_reset = btnC || !clock_locked;

    soc_interconnect u_interconnect (
        .address_i              (data_address),
        .write_enable_i         (data_write_enable),
        .ram_read_i             (ram_read),
        .uart_read_i            (uart_read),
        .gpio_read_i            (gpio_read),
        .display_read_i         (display_read),
        .led_read_i             (led_read),
        .buzzer_read_i          (buzzer_read),
        .vga_read_i             (vga_read),
        .read_data_o            (data_read),
        .ram_write_enable_o     (ram_write_enable),
        .uart_write_enable_o    (uart_write_enable),
        .gpio_write_enable_o    (gpio_write_enable),
        .display_write_enable_o (display_write_enable),
        .led_write_enable_o     (led_write_enable),
        .buzzer_write_enable_o  (buzzer_write_enable),
        .vga_write_enable_o     (vga_write_enable),
        .uart_addr_o            (uart_addr),
        .gpio_addr_o            (gpio_addr),
        .display_addr_o         (display_addr),
        .led_addr_o             (led_addr),
        .buzzer_addr_o          (buzzer_addr)
    );

    vga_clock_gen u_clock_gen (
        .clk100_i   (clk100mhz),
        .rst_i      (btnC),
        .clk_fpga_o (clk_fpga),
        .clk_vga_o  (clk_vga),
        .locked_o   (clock_locked)
    );

    instr_mem u_program_rom (
        .A  (prog_address),
        .RD (prog_instr)
    );

    cpu u_cpu (
        .clk                (clk_fpga),
        .rst                (system_reset),
        .ProgInstr_i        (prog_instr),
        .ProgAddress_o      (prog_address),
        .DataIn_i           (data_read),
        .DataAddress_o      (data_address),
        .DataOut_o          (data_write),
        .DataFunct3_o       (data_funct3),
        .DataWriteEnable_o  (data_write_enable)
    );

    soc_data_ram u_data_ram (
        .clk_i          (clk_fpga),
        .write_enable_i (ram_write_enable),
        .address_i      (data_address),
        .write_data_i   (data_write),
        .funct3_i       (data_funct3),
        .read_data_o    (ram_read)
    );

    j1_input u_gpio (
        .clk_i          (clk_fpga),
        .rst_i          (system_reset),
        .write_enable_i (gpio_write_enable),
        .addr_i         (gpio_addr),
        .wdata_i        (data_write),
        .rdata_o        (gpio_read),
        .btns_in        (btns)
    );

    led_perifico u_led (
        .clk_i          (clk_fpga),
        .rst_i          (system_reset),
        .write_enable_i (led_write_enable),
        .addr_i         (led_addr),
        .wdata_i        (data_write),
        .rdata_o        (led_read),
        .led            (led)
    );

    display_7seg u_display (
        .clk_i          (clk_fpga),
        .rst_i          (system_reset),
        .write_enable_i (display_write_enable),
        .addr_i         (display_addr),
        .wdata_i        (data_write),
        .rdata_o        (display_read),
        .an             (an),
        .dp             (dp),
        .seg            (seg)
    );

    buzzer_perifico u_buzzer (
        .clk_i          (clk_fpga),
        .rst_i          (system_reset),
        .write_enable_i (buzzer_write_enable),
        .addr_i         (buzzer_addr),
        .wdata_i        (data_write),
        .rdata_o        (buzzer_read),
        .buzzer_pwm     (buzzer)
    );

    uart_top u_uart (
        .clk_i          (clk_fpga),
        .rst_i          (system_reset),
        .write_enable_i (uart_write_enable),
        .addr_i         (uart_addr),
        .wdata_i        (data_write),
        .rdata_o        (uart_read),
        .rx_pin         (uart_rx),
        .tx_pin         (uart_tx)
    );

    vga_periph u_vga (
        .clk_cpu_i      (clk_fpga),
        .rst_i          (system_reset),
        .write_enable_i (vga_write_enable),
        .addr_i         (data_address),
        .wdata_i        (data_write),
        .clk_vga_i      (clk_vga),
        .rdata_cpu_o    (vga_read),
        .hsync_o        (hsync),
        .vsync_o        (vsync),
        .vga_r_o        (vgaRed),
        .vga_g_o        (vgaGreen),
        .vga_b_o        (vgaBlue)
    );

endmodule
