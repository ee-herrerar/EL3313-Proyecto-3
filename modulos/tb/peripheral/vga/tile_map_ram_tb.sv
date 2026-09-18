`timescale 1ns / 1ps

module tile_map_ram_tb();

    // Señales Puerto A (CPU - 100 MHz)
    logic        clk_cpu_i;
    logic        write_enable_i;
    logic [8:0]  addr_cpu_i;
    logic [31:0] wdata_i;

    // Señales Puerto B (VGA - 25 MHz)
    logic        clk_vga_i;
    logic [8:0]  addr_vga_i;
    logic [31:0] rdata_vga_o;

    tile_map_ram uut (
        .clk_cpu_i      (clk_cpu_i),
        .write_enable_i (write_enable_i),
        .addr_cpu_i     (addr_cpu_i),
        .wdata_i        (wdata_i),
        .clk_vga_i      (clk_vga_i),
        .addr_vga_i     (addr_vga_i),
        .rdata_vga_o    (rdata_vga_o)
    );

    // Reloj CPU a 100 MHz (Periodo 10 ns)
    always #5 clk_cpu_i = ~clk_cpu_i;

    // Reloj VGA a 25 MHz (Periodo 40 ns)
    always #20 clk_vga_i = ~clk_vga_i;

    initial begin
        clk_cpu_i = 0;
        clk_vga_i = 0;
        write_enable_i = 0;
        addr_cpu_i = 0;
        wdata_i = 0;
        addr_vga_i = 0;

        #50;

        // 1. Simular escritura de una casilla por parte del microprocesador
        @(posedge clk_cpu_i);
        write_enable_i = 1;
        addr_cpu_i = 9'd45;         // Escribir en la celda 45
        wdata_i = 32'h00000002;     // Codificación para impacto (rojo)
        
        @(posedge clk_cpu_i);
        write_enable_i = 0;

        // 2. Simular lectura asíncrona por parte del barrido de píxeles VGA
        #100;
        @(posedge clk_vga_i);
        addr_vga_i = 9'd45;

        @(posedge clk_vga_i);
        if (rdata_vga_o == 32'h00000002) begin
            $display("PASSED: Lectura/Escritura en doble puerto exitosa.");
        end else begin
            $error("FAILED: Se esperaba 0x00000002, se obtuvo %h", rdata_vga_o);
        end

        $finish;
    end

endmodule