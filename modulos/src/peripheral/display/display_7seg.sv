module display_7seg (
    // Interfaz estándar de periféricos
    input logic clk_i, rst_i, write_enable_i,
    input logic [1:0] addr_i,
    input logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    // Salidas físicas hacia FPGA
    output logic [3:0] an, // Ánodos para seleccionar dígito
    output logic        dp,
    output logic [6:0] seg // Display 7 segmentos
);

  localparam logic [1:0] ADDR_DATOS = 2'b00;
 
    logic [31:0] datos_reg;
 
    always_ff @(posedge clk_i) begin
        if (rst_i)
            datos_reg <= 32'h0;
        else if (write_enable_i && addr_i == ADDR_DATOS)
            datos_reg <= wdata_i;
    end
 
    assign rdata_o = (addr_i == ADDR_DATOS) ? datos_reg : 32'h0;
 
    seven_seg_mux u_seven_seg (
        .clk       (clk_i),
        .rst       (rst_i),
        .time_tens (datos_reg[3:0]),    // decenas Jugador 1
        .time_ones (datos_reg[7:4]),    // unidades Jugador 1
        .wins_tens (datos_reg[11:8]),   // decenas Jugador 2
        .wins_ones (datos_reg[15:12]),  // unidades Jugador 2
        .seg       (seg),
        .dp        (dp),
        .an        (an)
    );
 
endmodule

    
endmodule
