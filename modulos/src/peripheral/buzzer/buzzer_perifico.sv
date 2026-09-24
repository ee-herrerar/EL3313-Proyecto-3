module buzzer_perifico (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    output logic        buzzer_pwm
);
 
    localparam logic [1:0] ADDR_CONTROL = 2'b00;
 
    logic write_strobe;
    logic [2:0] evento;
 
    assign write_strobe = write_enable_i && (addr_i == ADDR_CONTROL);
    assign evento       = wdata_i[2:0];
 
    assign rdata_o = (addr_i == ADDR_CONTROL) ? {29'b0, evento} : 32'h0;
 
    logic impacto_pulse, fallo_pulse, hundido_pulse, invalido_pulse, victoria_pulse;
 
    assign impacto_pulse  = write_strobe && (evento == 3'd1);
    assign fallo_pulse    = write_strobe && (evento == 3'd2);
    assign hundido_pulse  = write_strobe && (evento == 3'd3);
    assign invalido_pulse = write_strobe && (evento == 3'd4);
    assign victoria_pulse = write_strobe && (evento == 3'd5);
 
    buzzer_driver u_buzzer (
        .clk            (clk_i),
        .rst            (rst_i),
        .impacto_pulse  (impacto_pulse),
        .fallo_pulse    (fallo_pulse),
        .hundido_pulse  (hundido_pulse),
        .invalido_pulse (invalido_pulse),
        .victoria_pulse (victoria_pulse),
        .buzzer_pwm     (buzzer_pwm)
    );
 
endmodule
