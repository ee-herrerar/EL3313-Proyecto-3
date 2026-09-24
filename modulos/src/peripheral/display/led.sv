module led_perifico (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    output logic [15:0] led
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
 
    status_led u_status_led (
        .game_state (datos_reg[1:0]),
        .led        (led)
    );
 
endmodule
