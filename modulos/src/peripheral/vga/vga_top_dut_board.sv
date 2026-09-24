module vga_top_dut_board (
    input  logic       clk100mhz,
    input  logic       btnC,
    output logic       hsync,
    output logic       vsync,
    // Salidas colores
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    logic [1:0] clk_div;
    logic       clk_vga;
    logic [8:0] write_index;
    logic       writing;
    logic       write_enable;
    logic [31:0] write_addr;
    logic [31:0] write_data;
    logic [2:0] color_code;

    always_ff @(posedge clk100mhz or posedge btnC) begin
        if (btnC) begin
            clk_div     <= 2'b00;
            write_index <= 9'd0;
            writing     <= 1'b1;
        end else begin
            clk_div <= clk_div + 1'b1;
            if (writing && write_index == 9'd299) begin
                writing <= 1'b0;
            end else if (writing) begin
                write_index <= write_index + 1'b1;
            end
        end
    end

    assign clk_vga      = clk_div[1];
    assign write_enable = writing;
    assign write_addr  = 32'h0001_1000 + (write_index << 2);
    assign color_code  = write_index % 5;
    assign write_data  = {29'b0, color_code};

    vga_top_dut u_dut (
        .clk_cpu_i      (clk100mhz),
        .clk_vga_i      (clk_vga),
        .rst_i          (btnC),
        .write_enable_i (write_enable),
        .addr_i         (write_addr),
        .wdata_i        (write_data),
        .hsync_o        (hsync),
        .vsync_o        (vsync),
        .vga_r_o        (vgaRed),
        .vga_g_o        (vgaGreen),
        .vga_b_o        (vgaBlue)
    );

endmodule
