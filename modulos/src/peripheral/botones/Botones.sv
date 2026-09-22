module Botones #(
    // BTN_SEL (índice 0) y BTN_OK (índice 1)
    parameter int NUM_BOTONES = 2
)(
    input  logic                   clk,
    input  logic                   reset,
    input  logic [NUM_BOTONES-1:0] btn_async_in, // Entradas físicas (BTN_SEL, BTN_OK)

    output logic                   btn_sel_pulsado, // Pulso de 1 ciclo clk al presionar SEL
    output logic                   btn_ok_pulsado   // Pulso de 1 ciclo clk al presionar OK
);

    // Señales internas de interconexión
    logic [NUM_BOTONES-1:0] btn_synced;
    logic [NUM_BOTONES-1:0] btn_debounced;
    logic [NUM_BOTONES-1:0] btn_previos;
    logic [NUM_BOTONES-1:0] btn_nuevos;

    // Sincronización (Evita Metaestabilidad)
    Sync #(
        .N(NUM_BOTONES)
    ) inst_sync (
        .clk          (clk),
        .reset        (reset),
        .async_signal (btn_async_in),
        .sync_signal  (btn_synced)
    );

    // Debouncer (Filtro Antirrebote)
    Debouncer #(
        .N(NUM_BOTONES)
    ) inst_debouncer (
        .clk     (clk),
        .reset   (reset),
        .btn_in  (btn_synced),
        .btn_out (btn_debounced)
    );

    // Detección de flanco de subida (Generación de pulso único)
    assign btn_nuevos = btn_debounced & ~btn_previos;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            btn_previos <= '0;
        end else begin
            btn_previos <= btn_debounced;
        end
    end

    // Asignación de salidas específicas para el control del Ahorcado
    assign btn_sel_pulsado = btn_nuevos[0]; // Mapeado al botón 0 (BTN_SEL)
    assign btn_ok_pulsado  = btn_nuevos[1]; // Mapeado al botón 1 (BTN_OK)

endmodule
