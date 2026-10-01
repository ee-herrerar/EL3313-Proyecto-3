module vga_clock_gen (
    input  logic clk100_i,
    input  logic rst_i,
    output logic clk25_o,
    output logic locked_o
);

    clk_wiz_0 u_clk_wiz_0 (
        .clk100mhz (clk100_i), 
        .clk_vga   (clk25_o),  
        .reset     (rst_i),    
        .locked    (locked_o)  
    );

endmodule