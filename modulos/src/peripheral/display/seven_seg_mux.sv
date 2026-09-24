module seven_seg_mux (
    input  logic       clk,
    input  logic       rst,
    input  logic [3:0] time_tens,
    input  logic [3:0] time_ones,
    input  logic [3:0] wins_tens,
    input  logic [3:0] wins_ones,
    output logic [6:0] seg,
    output logic       dp,
    output logic [3:0] an
);

    logic [1:0] digit_sel;
    logic [3:0] digit_value;
    logic [15:0] refresh_count;

    always_ff @(posedge clk) begin
        if (rst) begin
            refresh_count <= 16'd0;
            digit_sel <= 2'd0;
        end else if (refresh_count == 16'd0) begin
            refresh_count <= 16'hffff;
            digit_sel <= digit_sel + 2'd1;
        end else begin
            refresh_count <= refresh_count - 16'd1;
        end
    end

    always_comb begin
        case (digit_sel)
            2'd0: begin digit_value = time_tens; an = 4'b1110; end
            2'd1: begin digit_value = time_ones; an = 4'b1101; end
            2'd2: begin digit_value = wins_tens; an = 4'b1011; end
            default: begin digit_value = wins_ones; an = 4'b0111; end
        endcase

        dp = 1'b1;
        case (digit_value)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule
