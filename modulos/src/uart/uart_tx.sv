module uart_tx #(
    parameter DBIT    = 8,
    parameter SB_TICK = 16
)(
    input  logic            clk_i,
    input  logic            rst_i,
    input  logic            tx_start,
    input  logic            s_tick,
    input  logic [DBIT-1:0] din,
    output logic            tx_done_tick,
    output logic            tx
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
    logic tx_reg, tx_next;

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_reg <= IDLE;
            s_reg     <= '0;
            n_reg     <= '0;
            b_reg     <= '0;
            tx_reg    <= 1'b1;
        end
        else begin
            state_reg <= state_next;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
            tx_reg    <= tx_next;
        end
    end

    always_comb begin
        state_next   = state_reg;
        tx_done_tick = 1'b0;
        s_next       = s_reg;
        n_next       = n_reg;
        b_next       = b_reg;
        tx_next      = tx_reg;

        case (state_reg)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    state_next = START;
                    s_next     = '0;
                    b_next     = din;
                end
            end
            START: begin
                tx_next = 1'b0;
                if (s_tick) begin
                    if (s_reg == (SB_TICK - 1)) begin
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
                tx_next = b_reg[0];
                if (s_tick) begin
                    if (s_reg == (SB_TICK - 1)) begin
                        s_next = '0;
                        b_next = b_reg >> 1;

                        if (n_reg == (DBIT - 1))
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
                tx_next = 1'b1;
                if (s_tick) begin
                    if (s_reg == (SB_TICK - 1)) begin
                        state_next   = IDLE;
                        tx_done_tick = 1'b1;
                        s_next       = '0;
                    end
                    else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end
            default: begin
                state_next = IDLE;
                tx_next    = 1'b1;
            end
        endcase
    end

    assign tx = tx_reg;

endmodule