module uart_peripheral #(
    parameter SYS_CLK_FREQ = 100_000_000,
    parameter BAUD_RATE    = 115_200, // Baudios solicitados
    parameter OVERSAMPLE   = 16,
    parameter DBIT         = 8
)(
    // Interfaz estándar de periféricos
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,         // 00=Control, 01=TX, 10=RX
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    
    // Pines físicos UART
    input  logic        rx,
    output logic        tx
);

    // Señales internas
    logic s_tick;
    logic tx_start, tx_done_tick;
    logic rx_done_tick;
    logic [DBIT-1:0] rx_dout;
    
    // Registros de control
    logic tx_busy;
    logic rx_valid;
    logic [DBIT-1:0] rx_data_reg;

    // 1. Instancia del Generador de Baudios (No cuenta para el límite)
    uart_generador_baudios #(
        .SYS_CLK_FREQ(SYS_CLK_FREQ), 
        .BAUD_RATE(BAUD_RATE), 
        .OVERSAMPLE(OVERSAMPLE)
    ) baud_gen (
        .clk_i(clk_i), 
        .rst_i(rst_i), 
        .s_tick(s_tick)
    );

    // 2. Instancia de RX (Tu módulo existente)
    uart_rx #(
        .DBIT(DBIT), 
        .SB_TICK(OVERSAMPLE)
    ) uart_rx_inst (
        .clk_i(clk_i), 
        .rst_i(rst_i), 
        .rx(rx), 
        .s_tick(s_tick),
        .rx_done_tick(rx_done_tick), 
        .dout(rx_dout)
    );

    // 3. Instancia de TX (Tu módulo existente)
    uart_tx #(
        .DBIT(DBIT), 
        .SB_TICK(OVERSAMPLE)
    ) uart_tx_inst (
        .clk_i(clk_i), 
        .rst_i(rst_i), 
        .tx_start(tx_start), 
        .s_tick(s_tick),
        .din(wdata_i[7:0]), // El dato a transmitir viene del bus del CPU
        .tx_done_tick(tx_done_tick), 
        .tx(tx)
    );

    // --- LÓGICA DE CONTROL (Mapeo de Memoria) ---
    
    // Un pulso de escritura en el offset 0x04 (addr_i = 01) dispara la transmisión
    assign tx_start = (write_enable_i && (addr_i == 2'b01)) ? 1'b1 : 1'b0;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_busy     <= 1'b0;
            rx_valid    <= 1'b0;
            rx_data_reg <= '0;
        end else begin
            // Bandera: TX Ocupado
            if (tx_start) 
                tx_busy <= 1'b1;
            else if (tx_done_tick) 
                tx_busy <= 1'b0;
            
            // Bandera: Dato RX disponible
            if (rx_done_tick) begin
                rx_data_reg <= rx_dout;
                rx_valid    <= 1'b1;
            end 
            // La bandera se limpia automáticamente cuando el CPU lee el offset 0x08 (addr_i = 10)
            else if (!write_enable_i && (addr_i == 2'b10)) begin
                rx_valid    <= 1'b0;
            end
        end
    end

    // --- LÓGICA DE LECTURA (Hacia el procesador) ---
    always_comb begin
        rdata_o = 32'd0;
        case (addr_i)
            // Offset 0x00: Registro de Estado
            2'b00: rdata_o = {30'd0, rx_valid, tx_busy}; 
            
            // Offset 0x04: Registro TX (Es de escritura, por defecto lee 0)
            2'b01: rdata_o = 32'd0;                      
            
            // Offset 0x08: Registro RX (Retorna el byte recibido)
            2'b10: rdata_o = {24'd0, rx_data_reg};       
            
            default: rdata_o = 32'd0;
        endcase
    end

endmodule