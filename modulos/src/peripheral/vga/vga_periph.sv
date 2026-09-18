module vga_periph (
    // Interfaz del procesador RISC-V (100 MHz)
    input  logic        clk_cpu_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [31:0] addr_i,     // El procesador enviará la dirección completa
    input  logic [31:0] wdata_i,

    // Reloj generado por PLL para el VGA (25 MHz)
    input  logic        clk_vga_i,

    // Salidas físicas VGA (Basys 3)
    output logic        hsync_o,
    output logic        vsync_o,
    output logic [3:0]  vga_r_o,
    output logic [3:0]  vga_g_o,
    output logic [3:0]  vga_b_o
);

    logic [9:0]  pixel_x;
    logic [9:0]  pixel_y;
    logic        video_on;
    
    logic [8:0]  tile_addr_read;
    logic [31:0] tile_data_read;
    logic [11:0] rgb_out;

    // Convertimos la dirección de bytes de RISC-V a dirección de palabra (índice 0 a 511)
    // El mapa dice: 0x00011000 a 0x000117FF. Tomamos los bits [10:2].
    logic [8:0] word_addr_cpu;
    assign word_addr_cpu = addr_i[10:2]; 

    // Instancia de la memoria de bloques (Dual-Port)
    tile_map_ram u_vram (
        .clk_cpu_i      (clk_cpu_i),
        .write_enable_i (write_enable_i),
        .addr_cpu_i     (word_addr_cpu),
        .wdata_i        (wdata_i),
        
        .clk_vga_i      (clk_vga_i),
        .addr_vga_i     (tile_addr_read),
        .rdata_vga_o    (tile_data_read)
    );

    // Instancia del generador de sincronismos
    vga_sync u_sync (
        .clk_vga_i  (clk_vga_i),
        .rst_i      (rst_i),
        .hsync_o    (hsync_o),
        .vsync_o    (vsync_o),
        .pixel_x_o  (pixel_x),
        .pixel_y_o  (pixel_y),
        .video_on_o (video_on)
    );

    // Instancia del renderizador
    tile_renderer u_renderer (
        .pixel_x_i   (pixel_x),
        .pixel_y_i   (pixel_y),
        .video_on_i  (video_on),
        .tile_data_i (tile_data_read),
        .tile_addr_o (tile_addr_read),
        .rgb_o       (rgb_out)
    );

    // Asignación a los pines físicos de la Basys 3 (4 bits por canal RGB)
    assign vga_r_o = rgb_out[11:8];
    assign vga_g_o = rgb_out[7:4];
    assign vga_b_o = rgb_out[3:0];

endmodule