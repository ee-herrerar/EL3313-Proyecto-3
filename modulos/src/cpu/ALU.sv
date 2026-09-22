module ALU (
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    input logic [3:0] ALUControl,
    output logic [31:0] ALUResult,
    output logic zero,
    output logic less
);

always @(*) begin
    case (ALUControl)
        default: ALUResult = 32'd0;
        4'b0000: ALUResult = SrcA + SrcB; //Esta es la operacion de suma
        4'b0001: ALUResult = SrcA - SrcB; //Esta es la operacion de resta
        4'b0101: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 32'd1 : 32'd0; //Esta es la operacion set less than 
        4'b0011: ALUResult = SrcA | SrcB; //Esta es la operacion de OR
        4'b0010: ALUResult = SrcA & SrcB; //Esta es la operacion de AND
        4'b0100: ALUResult = SrcA ^ SrcB; //Esta es la operacion de XOR
        4'b0110: ALUResult = SrcA << SrcB[4:0]; //Esta es la operacion de Shift Logical Left
        4'b1000: ALUResult = SrcA >> SrcB[4:0]; //Esta es la operacion de Shift Logical Right
        4'b1001: ALUResult = $signed(SrcA) >>> SrcB[4:0]; //Esta es la operacion de Shift Right Arithmetic
        4'b1011: ALUResult = (SrcA < SrcB) ? 32'd1 : 32'd0; //Esta es la op SIN unsigned
        4'b1010: ALUResult = SrcB; // Esta es la  operacion del LUI, que simplemente pasa el valor de SrcB a la salida
    endcase
    zero = (ALUResult == 32'd0);
    less = ($signed(SrcA) < $signed(SrcB));
end

endmodule