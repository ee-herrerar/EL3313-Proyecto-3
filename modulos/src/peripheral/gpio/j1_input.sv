module j1_input (
    // Interfaz estándar de periféricos
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    // Entradas físicas desde la tarjeta
    //Arriba, Abajo, Izquierda, Derecha, OK/Rotar, Reiniciar
    input  logic [5:0]  btns_in
);

    // 1. Sincronización de entradas asíncronas
    logic [5:0] btns_sync;
    
    sync #(
        .N(6)
    ) sync_btns (
        .clk          (clk_i),
        .reset        (rst_i),
        .async_signal (btns_in),
        .sync_signal  (btns_sync)
    );

    // 2. Filtro Anti-Rebotes (Debouncing)
    logic [5:0] btns_debounced;

    debouncer #(
        .N(6)
    ) debounce_btns (
        .clk     (clk_i),
        .reset   (rst_i),
        .btn_in  (btns_sync),
        .btn_out (btns_debounced)
    );

    // 3. Mapeo en Memoria (Lectura del Registro de Estado)
    always_comb begin
        rdata_o = 32'b0; // Por defecto retorna 0
        
        // Cuando write_enable_i=0, la lectura se realiza por rdata_o
        if (!write_enable_i) begin
            case (addr_i)
                2'b00: rdata_o = {26'b0, btns_debounced}; // Registro de Estado
                default: rdata_o = 32'b0;
            endcase
        end
    end

endmodule