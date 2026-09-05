`timescale 1ns / 1ps



module next_instruction_incrementor (
    input  wire [31:0] current_pc,
    input  wire [31:0] immediate,
    input  wire [31:0] rs1_data,
    input  wire [1:0]  pc_select,

    output reg  [31:0] next_pc,
    output reg         misaligned
);

    localparam [1:0] PC_PLUS_4 = 2'b00;
    localparam [1:0] PC_BRANCH = 2'b01;
    localparam [1:0] PC_JAL    = 2'b10;
    localparam [1:0] PC_JALR   = 2'b11;

    reg [31:0] selected_pc;

    always_comb begin
        case (pc_select)

            PC_PLUS_4: begin
                selected_pc = current_pc + 32'd4;
            end


            PC_BRANCH: begin
                selected_pc = current_pc + immediate;
            end

            PC_JAL: begin
                selected_pc = current_pc + immediate;
            end


            PC_JALR: begin
                selected_pc =
                    (rs1_data + immediate) & 32'hFFFF_FFFE;
            end

            default: begin
                selected_pc = current_pc + 32'd4;
            end

        endcase

        next_pc = selected_pc;


        misaligned = (selected_pc[1:0] != 2'b00);
    end

endmodule
