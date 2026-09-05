`timescale 1ns / 1ps

module load_formatter (
    input  wire [31:0] memory_data,
    input  wire [1:0]  address_offset,
    input  wire [2:0]  funct3,

    output reg  [31:0] load_data,
    output reg         load_valid,
    output reg         misaligned
);

    localparam [2:0] LOAD_BYTE              = 3'b000; // LB
    localparam [2:0] LOAD_HALFWORD          = 3'b001; // LH
    localparam [2:0] LOAD_WORD              = 3'b010; // LW
    localparam [2:0] LOAD_BYTE_UNSIGNED     = 3'b100; // LBU
    localparam [2:0] LOAD_HALFWORD_UNSIGNED = 3'b101; // LHU

    reg [31:0] shifted_data;

    always_comb begin
        load_data   = 32'b0;
        load_valid  = 1'b1;
        misaligned  = 1'b0;

        /*//=============================================
         * Move the addressed byte into bits [7:0].
         *
         * Offset 00: shift by 0 bits
         * Offset 01: shift by 8 bits
         * Offset 10: shift by 16 bits
         * Offset 11: shift by 24 bits
         *///===========================================
        shifted_data = memory_data >> (address_offset * 8);

        case (funct3)

            LOAD_BYTE: begin
                load_data = {
                    {24{shifted_data[7]}},
                    shifted_data[7:0]
                };
            end

            LOAD_HALFWORD: begin
                if (address_offset[0] != 1'b0) begin
                    load_valid = 1'b0;
                    misaligned = 1'b1;
                end
                else begin
                    load_data = {
                        {16{shifted_data[15]}},
                        shifted_data[15:0]
                    };
                end
            end

            LOAD_WORD: begin
                if (address_offset != 2'b00) begin
                    load_valid = 1'b0;
                    misaligned = 1'b1;
                end
                else begin
                    load_data = memory_data;
                end
            end


            LOAD_BYTE_UNSIGNED: begin
                load_data = {
                    24'b0,
                    shifted_data[7:0]
                };
            end


            LOAD_HALFWORD_UNSIGNED: begin
                if (address_offset[0] != 1'b0) begin
                    load_valid = 1'b0;
                    misaligned = 1'b1;
                end
                else begin
                    load_data = {
                        16'b0,
                        shifted_data[15:0]
                    };
                end
            end


            default: begin
                load_data  = 32'b0;
                load_valid = 1'b0;
            end

        endcase
    end

endmodule
