`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
// Design Name: 
// Module Name: immediate_generator
// Project Name: 
// Target Devices: 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module immediate_generator (
    input  wire [31:0] instruction,
    input  wire [2:0]  immediateSelect,

    output reg  [31:0] immediate
);

    localparam [2:0] IMM_I = 3'b000;
    localparam [2:0] IMM_S = 3'b001;
    localparam [2:0] IMM_B = 3'b010;
    localparam [2:0] IMM_U = 3'b011;
    localparam [2:0] IMM_J = 3'b100;

    always_comb begin
        case (immediateSelect)

            IMM_I: begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };
            end

            IMM_S: begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:25],
                    instruction[11:7]
                };
            end


            IMM_B: begin
                immediate = {
                    {19{instruction[31]}},
                    instruction[31],
                    instruction[7],
                    instruction[30:25],
                    instruction[11:8],
                    1'b0
                };
            end


            IMM_U: begin
                immediate = {
                    instruction[31:12],
                    12'b0
                };
            end

            IMM_J: begin
                immediate = {
                    {11{instruction[31]}},
                    instruction[31],
                    instruction[19:12],
                    instruction[20],
                    instruction[30:21],
                    1'b0
                };
            end

            default: begin
                immediate = 32'b0;
            end

        endcase
    end

endmodule
