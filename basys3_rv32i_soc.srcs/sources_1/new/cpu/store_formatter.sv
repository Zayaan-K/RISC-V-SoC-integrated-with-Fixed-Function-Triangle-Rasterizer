`timescale 1ns / 1ps

module store_formatter (
    input  wire [31:0] register_data,
    input  wire [1:0]  address_offset,
    input  wire [2:0]  funct3,

    output reg  [31:0] write_data,
    output reg  [3:0]  byte_enable,
    output reg         store_valid,
    output reg         misaligned
);

    localparam [2:0] STORE_BYTE     = 3'b000; // SB
    localparam [2:0] STORE_HALFWORD = 3'b001; // SH
    localparam [2:0] STORE_WORD     = 3'b010; // SW

    always_comb begin
        write_data  = 32'b0;
        byte_enable = 4'b0000;
        store_valid = 1'b1;
        misaligned  = 1'b0;

        case (funct3)
            STORE_BYTE: begin
                write_data =
                    {24'b0, register_data[7:0]}
                    << (address_offset * 8);

                byte_enable = 4'b0001 << address_offset;
            end


            STORE_HALFWORD: begin
                if (address_offset[0] != 1'b0) begin
                    store_valid = 1'b0;
                    misaligned  = 1'b1;
                end
                else begin
                    write_data =
                        {16'b0, register_data[15:0]}
                        << (address_offset * 8);

                    byte_enable = 4'b0011 << address_offset;
                end
            end

            STORE_WORD: begin
                if (address_offset != 2'b00) begin
                    store_valid = 1'b0;
                    misaligned  = 1'b1;
                end
                else begin
                    write_data  = register_data;
                    byte_enable = 4'b1111;
                end
            end

            default: begin
                write_data  = 32'b0;
                byte_enable = 4'b0000;
                store_valid = 1'b0;
            end

        endcase
    end

endmodule
