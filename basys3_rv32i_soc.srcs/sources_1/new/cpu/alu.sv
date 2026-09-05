`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
//////////////////////////////////////////////////////////////////////////////////


module ALU (
    input  wire [31:0] operandA,
    input  wire [31:0] operandB,
    input  wire [3:0]  aluSelect,

    output reg  [31:0] result,
    output wire        zero
);

    localparam [3:0] ALU_ADD  = 4'b0000;
    localparam [3:0] ALU_SUB  = 4'b0001;
    localparam [3:0] ALU_SLL  = 4'b0010;
    localparam [3:0] ALU_SLT  = 4'b0011;
    localparam [3:0] ALU_SLTU = 4'b0100;
    localparam [3:0] ALU_XOR  = 4'b0101;
    localparam [3:0] ALU_SRL  = 4'b0110;
    localparam [3:0] ALU_SRA  = 4'b0111;
    localparam [3:0] ALU_OR   = 4'b1000;
    localparam [3:0] ALU_AND  = 4'b1001;

    always_comb begin
        case (aluSelect)

            ALU_ADD: begin
                result = operandA + operandB;
            end

            ALU_SUB: begin
                result = operandA - operandB;
            end

            ALU_SLL: begin
                result = operandA << operandB[4:0];
            end

            ALU_SLT: begin
                result = {
                    31'b0,
                    $signed(operandA) < $signed(operandB)
                };
            end

            ALU_SLTU: begin
                result = {
                    31'b0,
                    operandA < operandB
                };
            end

            ALU_XOR: begin
                result = operandA ^ operandB;
            end

            ALU_SRL: begin
                result = operandA >> operandB[4:0];
            end

            ALU_SRA: begin
                result = $signed(operandA) >>> operandB[4:0];
            end

            ALU_OR: begin
                result = operandA | operandB;
            end

            ALU_AND: begin
                result = operandA & operandB;
            end

            default: begin
                result = 32'b0;
            end

        endcase
    end

    assign zero = (result == 32'b0);

endmodule
            end

            ALU_SRL: begin
                result = operandA >> operandB[4:0];
            end

            ALU_SRA: begin
                result = $signed(operandA) >>> operandB[4:0];
            end

            ALU_OR: begin
                result = operandA | operandB;
            end

            ALU_AND: begin
                result = operandA & operandB;
            end

            default: begin
                result = 32'b0;
            end

        endcase
    end

    assign zero = (result == 32'b0);

endmodule
