`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.09.2026 18:32:56
// Design Name: 
// Module Name: vga_clock_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vga_clock_generator #(
    parameter int DIV = 4
)(
    input  logic clk_in,      // 100 MHz
    input  logic rst,
    output logic clk_out      // 25 MHz
);

    logic [$clog2(DIV)-1:0] counter;

    always_ff @(posedge clk_in) begin
        if (rst) begin
            counter <= '0;
            clk_out <= 1'b0;
        end
        else begin
            if (counter == (DIV/2 - 1)) begin
                counter <= '0;
                clk_out <= ~clk_out;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule
