module uart_rx #(
    parameter DBIT    = 8,
    parameter SB_TICK = 16
)(
    input  logic            clk_i,
    input  logic            rst_i,
    input  logic            rx,
    input  logic            s_tick,
    output logic            rx_done_tick,
    output logic [DBIT-1:0] dout
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } state_t;

    state_t state_reg, state_next;

    logic [$clog2(SB_TICK)-1:0] s_reg, s_next;
    logic [$clog2(DBIT)-1:0] n_reg, n_next;
    logic [DBIT-1:0] b_reg, b_next;
    logic rx_sync_0, rx_sync;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            rx_sync_0 <= 1'b1;
            rx_sync   <= 1'b1;
        end
        else begin
            rx_sync_0 <= rx;
            rx_sync   <= rx_sync_0;
        end
    end

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_reg <= IDLE;
            s_reg     <= '0;
            n_reg     <= '0;
            b_reg     <= '0;
        end
        else begin
            state_reg <= state_next;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
        end
    end

    always_comb begin
        state_next   = state_reg;
        rx_done_tick = 1'b0;
        s_next       = s_reg;
        n_next       = n_reg;
        b_next       = b_reg;

        case (state_reg)
            IDLE: begin
                if (!rx_sync) begin
                    state_next = START;
                    s_next     = '0;
                end
            end
            START: begin
                if (s_tick) begin
                    if (s_reg == (SB_TICK/2 - 1)) begin
                        state_next = DATA;
                        s_next     = '0;
                        n_next     = '0;
                    end
                    else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end
            DATA: begin
                if (s_tick) begin
                    if (s_reg == (SB_TICK - 1)) begin
                        s_next = '0;
                        b_next = '0;
                        for (int i = 0; i < DBIT - 1; i = i + 1)
                            b_next[i] = b_reg[i + 1];
                        b_next[DBIT - 1] = rx_sync;

                        if (n_reg == DBIT - 1)
                            state_next = STOP;
                        else
                            n_next = n_reg + 1'b1;
                    end
                    else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end
            STOP: begin
                if (s_tick) begin
                    if (s_reg == (SB_TICK - 1)) begin
                        state_next   = IDLE;
                        rx_done_tick = 1'b1;
                    end
                    else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end
            default: state_next = IDLE;
        endcase
    end

    assign dout = b_reg;

endmodule