module display_7seg (
    // Interfaz estándar de periféricos
    input logic clk_i, rst_i, write_enable_i,
    input logic [1:0] addr_i,
    input logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    // Salidas físicas hacia FPGA
    output logic [3:0] an, // Ánodos para seleccionar dígito
    output logic [6:0] seg // Display 7 segmentos
);

    
endmodule