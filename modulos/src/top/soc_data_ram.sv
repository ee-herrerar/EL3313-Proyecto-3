module soc_data_ram #(
    parameter int DEPTH = 1024
) (
    input  logic        clk_i,
    input  logic        write_enable_i,
    input  logic [31:0] address_i,
    input  logic [31:0] write_data_i,
    input  logic [2:0]  funct3_i,
    output logic [31:0] read_data_o
);

    localparam logic [31:0] BASE_ADDRESS = 32'h0000_2000;
    logic [31:0] mem [0:DEPTH-1];
    logic [31:0] word;
    logic        address_valid;
    logic [31:0] word_index;

    assign address_valid = (address_i >= BASE_ADDRESS) &&
                           (address_i < BASE_ADDRESS + (DEPTH * 4));
    assign word_index = (address_i - BASE_ADDRESS) >> 2;
    assign word = address_valid ? mem[word_index] : 32'b0;

    always_comb begin
        case (funct3_i)
            3'b000: read_data_o = {{24{word[7]}}, word[7:0]};
            3'b001: read_data_o = {{16{word[15]}}, word[15:0]};
            3'b010: read_data_o = word;
            3'b100: read_data_o = {24'b0, word[7:0]};
            3'b101: read_data_o = {16'b0, word[15:0]};
            default: read_data_o = 32'b0;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (write_enable_i && address_valid) begin
            case (funct3_i)
                3'b000: mem[word_index][7:0] <= write_data_i[7:0];
                3'b001: mem[word_index][15:0] <= write_data_i[15:0];
                3'b010: mem[word_index] <= write_data_i;
                default: ;
            endcase
        end
    end

    initial begin
        for (int index = 0; index < DEPTH; index = index + 1)
            mem[index] = 32'b0;
    end

endmodule
