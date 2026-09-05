`timescale 1ns / 1ps





module branch_comparator (
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [2:0]  funct3,

    output reg         branch_taken,
    output reg         branch_valid
);

    localparam [2:0] BRANCH_EQUAL                = 3'b000; // BEQ
    localparam [2:0] BRANCH_NOT_EQUAL            = 3'b001; // BNE
    localparam [2:0] BRANCH_LESS_THAN            = 3'b100; // BLT
    localparam [2:0] BRANCH_GREATER_EQUAL        = 3'b101; // BGE
    localparam [2:0] BRANCH_LESS_THAN_UNSIGNED   = 3'b110; // BLTU
    localparam [2:0] BRANCH_GREATER_EQUAL_UNSIGNED = 3'b111; // BGEU

    always_comb begin
        branch_taken = 1'b0;
        branch_valid = 1'b1;

        case (funct3)

            BRANCH_EQUAL: begin
                branch_taken = (rs1_data == rs2_data);
            end

            BRANCH_NOT_EQUAL: begin
                branch_taken = (rs1_data != rs2_data);
            end

            BRANCH_LESS_THAN: begin
                branch_taken =
                    ($signed(rs1_data) < $signed(rs2_data));
            end


            BRANCH_GREATER_EQUAL: begin
                branch_taken =
                    ($signed(rs1_data) >= $signed(rs2_data));
            end


            BRANCH_LESS_THAN_UNSIGNED: begin
                branch_taken = (rs1_data < rs2_data);
            end


            BRANCH_GREATER_EQUAL_UNSIGNED: begin
                branch_taken = (rs1_data >= rs2_data);
            end


            default: begin
                branch_taken = 1'b0;
                branch_valid = 1'b0;
            end

        endcase
    end

endmodule
