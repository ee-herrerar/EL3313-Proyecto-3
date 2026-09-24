module status_led (
    input  logic [1:0]  game_state,
    output logic [15:0] led
);

    always_comb begin
        led = 16'd0;
        case (game_state)
            2'd0: led[0] = 1'b1;
            2'd1: led[1] = 1'b1;
            2'd2: led[2] = 1'b1;
            default: led = 16'd0;
        endcase
    end

endmodule
