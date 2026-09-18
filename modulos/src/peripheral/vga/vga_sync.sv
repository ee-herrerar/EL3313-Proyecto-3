module vga_sync (
    input  logic clk_vga_i, // Reloj de píxel de 25 MHz
    input  logic rst_i,
    output logic hsync_o,
    output logic vsync_o,
    output logic [9:0] pixel_x_o,
    output logic [9:0] pixel_y_o,
    output logic video_on_o
);

    // Parámetros estándar VGA 640x480@60Hz
    localparam HD = 640, HF = 16, HS = 96, HB = 48; // Total H = 800
    localparam VD = 480, VF = 10, VS = 2,  VB = 33; // Total V = 525

    logic [9:0] h_count;
    logic [9:0] v_count;

    always_ff @(posedge clk_vga_i or posedge rst_i) begin
        if (rst_i) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == (HD + HF + HS + HB - 1)) begin
                h_count <= 0;
                if (v_count == (VD + VF + VS + VB - 1))
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // Sincronismos activos en bajo
    assign hsync_o = ~(h_count >= (HD + HF) && h_count < (HD + HF + HS));
    assign vsync_o = ~(v_count >= (VD + VF) && v_count < (VD + VF + VS));
    
    assign pixel_x_o = h_count;
    assign pixel_y_o = v_count;
    assign video_on_o = (h_count < HD) && (v_count < VD);

endmodule