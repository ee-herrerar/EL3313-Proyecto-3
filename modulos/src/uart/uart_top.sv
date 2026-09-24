module uart_top #(
    parameter SYS_CLK_FREQ = 100_000_000, // Reloj principal
    parameter BAUD_RATE    = 115_200,     // Baudios de comunicación para la aplicación PC
    parameter OVERSAMPLE   = 16,
    parameter DBIT         = 8
)(
    // Interfaz estándar de 32 bits requerida por el proyecto
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,         
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    
    // Pines físicos para conexión serial con la PC
    input  logic        rx_pin,
    output logic        tx_pin
);

    // Señales internas de interconexión
    logic s_tick;
    logic tx_start, tx_done_tick;
    logic rx_done_tick;
    logic [DBIT-1:0] rx_dout;
    
    // Banderas de estado
    logic tx_busy;
    logic rx_valid;
    logic [DBIT-1:0] rx_data_reg;

    // Instancia del Generador de Baudios
    uart_generador_baudios #(
        .SYS_CLK_FREQ(SYS_CLK_FREQ), 
        .BAUD_RATE(BAUD_RATE), 
        .OVERSAMPLE(OVERSAMPLE)
    ) baud_gen (
        .clk_i(clk_i), 
        .rst_i(rst_i), 
        .s_tick(s_tick)
    );

    // Instancia del Receptor UART
    uart_rx #(
        .DBIT(DBIT), 
        .SB_TICK(OVERSAMPLE)
    ) rx_inst (
        .clk_i(clk_i), 
        .rst_i(rst_i), 
        .rx(rx_pin), 
        .s_tick(s_tick),
        .rx_done_tick(rx_done_tick), 
        .dout(rx_dout)
    );

    // Instancia del Transmisor UART
    uart_tx #(
        .DBIT(DBIT), 
        .SB_TICK(OVERSAMPLE)
    ) tx_inst (
        .clk_i(clk_i), 
        .rst_i(rst_i), 
        .tx_start(tx_start), 
        .s_tick(s_tick),
        .din(wdata_i[7:0]), // Toma el byte menos significativo del bus de escritura
        .tx_done_tick(tx_done_tick), 
        .tx(tx_pin)
    );

    // Mapeo de memoria para escritura de Datos TX (Offset 0x04 corresponde a addr_i == 01)
    assign tx_start = (write_enable_i && (addr_i == 2'b01)) ? 1'b1 : 1'b0;

    // Control de las banderas de estado para el microprocesador
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_busy     <= 1'b0;
            rx_valid    <= 1'b0;
            rx_data_reg <= '0;
        end else begin
            // Lógica de estado para TX Ocupado
            if (tx_start) 
                tx_busy <= 1'b1;
            else if (tx_done_tick) 
                tx_busy <= 1'b0;
            
            // Lógica de estado para RX Válido
            if (rx_done_tick) begin
                rx_data_reg <= rx_dout;
                rx_valid    <= 1'b1;
            end 
            // La bandera se limpia automáticamente cuando el CPU lee el offset 0x08 (Datos RX)
            else if (!write_enable_i && (addr_i == 2'b10)) begin
                rx_valid    <= 1'b0;
            end
        end
    end

    // Mapeo de memoria para lectura (Hacia el procesador)
    always_comb begin
        rdata_o = 32'd0;
        case (addr_i)
            // Offset 0x00: Registro de Control/Estado
            // Bit 1: rx_valid (Dato disponible) | Bit 0: tx_busy (Transmisor ocupado)
            2'b00: rdata_o = {30'd0, rx_valid, tx_busy}; 
            
            // Offset 0x04: Datos TX (Registro de solo escritura, al leer retorna 0)
            2'b01: rdata_o = 32'd0;                      
            
            // Offset 0x08: Datos RX (Retorna el byte recibido y guardado)
            2'b10: rdata_o = {24'd0, rx_data_reg};       
            
            default: rdata_o = 32'd0;
        endcase
    end

endmodule