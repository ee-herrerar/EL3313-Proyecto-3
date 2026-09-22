module buzzer_driver #(
    parameter integer CLK_FREQ_HZ      = 100_000_000,
    parameter integer IMPACTO_FREQ_HZ  = 1200, parameter integer IMPACTO_MS  = 100,
    parameter integer FALLO_FREQ_HZ    = 300,  parameter integer FALLO_MS    = 120,
    parameter integer HUNDIDO_FREQ_HZ  = 600,  parameter integer HUNDIDO_MS  = 400,
    parameter integer INVALIDO_FREQ_HZ = 150,  parameter integer INVALIDO_MS = 200,
    parameter integer VICTORIA_FREQ_HZ = 900,  parameter integer VICTORIA_MS = 800
)(
    input  logic clk,
    input  logic rst,
    input  logic impacto_pulse,
    input  logic fallo_pulse,
    input  logic hundido_pulse,
    input  logic invalido_pulse,
    input  logic victoria_pulse,
    output logic buzzer_pwm
);
 
    localparam integer IMPACTO_HALF  = CLK_FREQ_HZ / (2 * IMPACTO_FREQ_HZ);
    localparam integer FALLO_HALF    = CLK_FREQ_HZ / (2 * FALLO_FREQ_HZ);
    localparam integer HUNDIDO_HALF  = CLK_FREQ_HZ / (2 * HUNDIDO_FREQ_HZ);
    localparam integer INVALIDO_HALF = CLK_FREQ_HZ / (2 * INVALIDO_FREQ_HZ);
    localparam integer VICTORIA_HALF = CLK_FREQ_HZ / (2 * VICTORIA_FREQ_HZ);
 
    localparam integer IMPACTO_DUR  = $rtoi(CLK_FREQ_HZ * (IMPACTO_MS  / 1000.0));
    localparam integer FALLO_DUR    = $rtoi(CLK_FREQ_HZ * (FALLO_MS    / 1000.0));
    localparam integer HUNDIDO_DUR  = $rtoi(CLK_FREQ_HZ * (HUNDIDO_MS  / 1000.0));
    localparam integer INVALIDO_DUR = $rtoi(CLK_FREQ_HZ * (INVALIDO_MS / 1000.0));
    localparam integer VICTORIA_DUR = $rtoi(CLK_FREQ_HZ * (VICTORIA_MS / 1000.0));
 
    function automatic integer max5(input integer a, b, c, d, e);
        integer m;
        begin
            m = a;
            if (b > m) m = b;
            if (c > m) m = c;
            if (d > m) m = d;
            if (e > m) m = e;
            max5 = m;
        end
    endfunction
 
    localparam integer MAX_HALF = max5(IMPACTO_HALF, FALLO_HALF, HUNDIDO_HALF, INVALIDO_HALF, VICTORIA_HALF);
    localparam integer MAX_DUR  = max5(IMPACTO_DUR,  FALLO_DUR,  HUNDIDO_DUR,  INVALIDO_DUR,  VICTORIA_DUR);
 
    localparam integer HALF_WIDTH = $clog2(MAX_HALF + 1);
    localparam integer DUR_WIDTH  = $clog2(MAX_DUR + 1);
 
    logic [HALF_WIDTH-1:0] half_period;
    logic [HALF_WIDTH-1:0] toggle_cnt;
    logic [DUR_WIDTH-1:0]  duration_cnt;
    logic                  active;
 
    always_ff @(posedge clk) begin
        if (rst) begin
            half_period  <= '0;
            toggle_cnt   <= '0;
            duration_cnt <= '0;
            active       <= 1'b0;
            buzzer_pwm   <= 1'b0;
        end else if (impacto_pulse) begin
            half_period  <= HALF_WIDTH'(IMPACTO_HALF);
            duration_cnt <= DUR_WIDTH'(IMPACTO_DUR);
            toggle_cnt   <= '0; active <= 1'b1; buzzer_pwm <= 1'b0;
        end else if (fallo_pulse) begin
            half_period  <= HALF_WIDTH'(FALLO_HALF);
            duration_cnt <= DUR_WIDTH'(FALLO_DUR);
            toggle_cnt   <= '0; active <= 1'b1; buzzer_pwm <= 1'b0;
        end else if (hundido_pulse) begin
            half_period  <= HALF_WIDTH'(HUNDIDO_HALF);
            duration_cnt <= DUR_WIDTH'(HUNDIDO_DUR);
            toggle_cnt   <= '0; active <= 1'b1; buzzer_pwm <= 1'b0;
        end else if (invalido_pulse) begin
            half_period  <= HALF_WIDTH'(INVALIDO_HALF);
            duration_cnt <= DUR_WIDTH'(INVALIDO_DUR);
            toggle_cnt   <= '0; active <= 1'b1; buzzer_pwm <= 1'b0;
        end else if (victoria_pulse) begin
            half_period  <= HALF_WIDTH'(VICTORIA_HALF);
            duration_cnt <= DUR_WIDTH'(VICTORIA_DUR);
            toggle_cnt   <= '0; active <= 1'b1; buzzer_pwm <= 1'b0;
        end else if (active) begin
            if (duration_cnt == '0) begin
                active     <= 1'b0;
                buzzer_pwm <= 1'b0;
            end else begin
                duration_cnt <= duration_cnt - 1'b1;
                if (toggle_cnt == half_period - 1'b1) begin
                    toggle_cnt <= '0;
                    buzzer_pwm <= ~buzzer_pwm;
                end else begin
                    toggle_cnt <= toggle_cnt + 1'b1;
                end
            end
        end
    end
 
endmodule
