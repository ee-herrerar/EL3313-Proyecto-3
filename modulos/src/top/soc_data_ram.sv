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

    logic [7:0]  selected_byte;
    logic [15:0] selected_half;


    // ============================================================
    // Dirección
    // ============================================================

    assign address_valid =
        (address_i >= BASE_ADDRESS) &&
        (address_i < BASE_ADDRESS + (DEPTH * 4));

    assign word_index =
        (address_i - BASE_ADDRESS) >> 2;

    assign word =
        address_valid
        ? mem[word_index]
        : 32'b0;


    // ============================================================
    // Selección de byte
    //
    // address[1:0]:
    //
    // 00 -> bits  7:0
    // 01 -> bits 15:8
    // 10 -> bits 23:16
    // 11 -> bits 31:24
    // ============================================================

    always_comb begin

        case (address_i[1:0])

            2'b00:
                selected_byte = word[7:0];

            2'b01:
                selected_byte = word[15:8];

            2'b10:
                selected_byte = word[23:16];

            2'b11:
                selected_byte = word[31:24];

            default:
                selected_byte = 8'b0;

        endcase

    end


    // ============================================================
    // Selección de halfword
    //
    // address[1] = 0 -> bits 15:0
    // address[1] = 1 -> bits 31:16
    // ============================================================

    always_comb begin

        case (address_i[1])

            1'b0:
                selected_half = word[15:0];

            1'b1:
                selected_half = word[31:16];

            default:
                selected_half = 16'b0;

        endcase

    end


    // ============================================================
    // Lecturas
    //
    // funct3:
    //
    // 000 = LB
    // 001 = LH
    // 010 = LW
    // 100 = LBU
    // 101 = LHU
    // ============================================================

    always_comb begin

        if (!address_valid) begin

            read_data_o = 32'b0;

        end
        else begin

            case (funct3_i)

                // LB
                3'b000:
                    read_data_o =
                        {{24{selected_byte[7]}}, selected_byte};

                // LH
                3'b001:
                    read_data_o =
                        {{16{selected_half[15]}}, selected_half};

                // LW
                3'b010:
                    read_data_o =
                        word;

                // LBU
                3'b100:
                    read_data_o =
                        {24'b0, selected_byte};

                // LHU
                3'b101:
                    read_data_o =
                        {16'b0, selected_half};

                default:
                    read_data_o =
                        32'b0;

            endcase

        end

    end


    // ============================================================
    // Escrituras
    //
    // funct3:
    //
    // 000 = SB
    // 001 = SH
    // 010 = SW
    // ============================================================

    always_ff @(posedge clk_i) begin

        if (write_enable_i && address_valid) begin

            case (funct3_i)

                // ------------------------------------------------
                // SB
                // ------------------------------------------------

                3'b000: begin

                    case (address_i[1:0])

                        2'b00:
                            mem[word_index][7:0]
                                <= write_data_i[7:0];

                        2'b01:
                            mem[word_index][15:8]
                                <= write_data_i[7:0];

                        2'b10:
                            mem[word_index][23:16]
                                <= write_data_i[7:0];

                        2'b11:
                            mem[word_index][31:24]
                                <= write_data_i[7:0];

                    endcase

                end


                // ------------------------------------------------
                // SH
                // ------------------------------------------------

                3'b001: begin

                    case (address_i[1])

                        1'b0:
                            mem[word_index][15:0]
                                <= write_data_i[15:0];

                        1'b1:
                            mem[word_index][31:16]
                                <= write_data_i[15:0];

                    endcase

                end


                // ------------------------------------------------
                // SW
                // ------------------------------------------------

                3'b010:
                    mem[word_index]
                        <= write_data_i;


                default: begin
                end

            endcase

        end

    end


    // ============================================================
    // Inicialización
    // ============================================================

    initial begin

        for (
            int index = 0;
            index < DEPTH;
            index = index + 1
        ) begin

            mem[index] = 32'b0;

        end

    end

endmodule