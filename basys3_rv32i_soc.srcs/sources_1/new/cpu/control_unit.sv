`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
// Design Name: 
// Module Name: control_unit
// Project Name: 
// Target Devices: 
//////////////////////////////////////////////////////////////////////////////////


module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        register_write_enable,
    output reg        memory_write_enable,
    output reg        alu_source_a_select,
    output reg        alu_source_b_select,
    output reg [3:0]  alu_operation,
    output reg [2:0]  immediate_select,
    output reg [1:0]  writeback_select,
    output reg        branch_enable,
    output reg        jump_enable,
    output reg        jump_register_enable,
    output reg        illegal_instruction
);


    localparam [6:0] OPCODE_LOAD      = 7'b0000011;
    localparam [6:0] OPCODE_IMMEDIATE = 7'b0010011;
    localparam [6:0] OPCODE_AUIPC     = 7'b0010111;
    localparam [6:0] OPCODE_STORE     = 7'b0100011;
    localparam [6:0] OPCODE_REGISTER  = 7'b0110011;
    localparam [6:0] OPCODE_LUI       = 7'b0110111;
    localparam [6:0] OPCODE_BRANCH    = 7'b1100011;
    localparam [6:0] OPCODE_JALR      = 7'b1100111;
    localparam [6:0] OPCODE_JAL       = 7'b1101111;
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
    localparam [3:0] ALU_PASS = 4'b1010;

    always @(*) begin

        register_write_enable = 1'b0;
        memory_write_enable   = 1'b0;
        alu_source_a_select    = 1'b0;
        alu_source_b_select    = 1'b0;
        alu_operation          = ALU_ADD;
        immediate_select       = 3'b000;
        writeback_select       = 2'b00;
        branch_enable          = 1'b0;
        jump_enable            = 1'b0;
        jump_register_enable   = 1'b0;
        illegal_instruction    = 1'b0;

        case (opcode)

            OPCODE_REGISTER: begin
                register_write_enable = 1'b1;

                case (funct3)
                    3'b000: begin
                        case (funct7)
                            7'b0000000: alu_operation = ALU_ADD;
                            7'b0100000: alu_operation = ALU_SUB;
                            default: begin
                                alu_operation       = ALU_ADD;
                                illegal_instruction = 1'b1;
                            end
                        endcase
                    end

                    3'b001: alu_operation = ALU_SLL;
                    3'b010: alu_operation = ALU_SLT;
                    3'b011: alu_operation = ALU_SLTU;
                    3'b100: alu_operation = ALU_XOR;

                    3'b101: begin
                        case (funct7)
                            7'b0000000: alu_operation = ALU_SRL;
                            7'b0100000: alu_operation = ALU_SRA;
                            default: begin
                                alu_operation       = ALU_SRL;
                                illegal_instruction = 1'b1;
                            end
                        endcase
                    end

                    3'b110: alu_operation = ALU_OR;
                    3'b111: alu_operation = ALU_AND;

                    default: illegal_instruction = 1'b1;
                endcase
            end

            // I-type ALU 
            OPCODE_IMMEDIATE: begin
                register_write_enable = 1'b1;
                alu_source_b_select    = 1'b1;
                immediate_select       = 3'b000;

                case (funct3)
                    3'b000: alu_operation = ALU_ADD;  
                    3'b010: alu_operation = ALU_SLT;  
                    3'b011: alu_operation = ALU_SLTU; 
                    3'b100: alu_operation = ALU_XOR;  
                    3'b110: alu_operation = ALU_OR;   
                    3'b111: alu_operation = ALU_AND;  

                    3'b001: begin                     
                        if (funct7 == 7'b0000000)
                            alu_operation = ALU_SLL;
                        else
                            illegal_instruction = 1'b1;
                    end

                    3'b101: begin
                        case (funct7)
                            7'b0000000: alu_operation = ALU_SRL; 
                            7'b0100000: alu_operation = ALU_SRA; 
                            default: illegal_instruction = 1'b1;
                        endcase
                    end

                    default: illegal_instruction = 1'b1;
                endcase
            end

            
            OPCODE_LOAD: begin
                register_write_enable = 1'b1;
                alu_source_b_select    = 1'b1;
                alu_operation          = ALU_ADD;
                immediate_select       = 3'b000;
                writeback_select       = 2'b01;

                case (funct3)
                    3'b000, 
                    3'b001, 
                    3'b010, 
                    3'b100, 
                    3'b101: ;

                    default: illegal_instruction = 1'b1;
                endcase
            end

            OPCODE_STORE: begin
                memory_write_enable = 1'b1;
                alu_source_b_select  = 1'b1;
                alu_operation        = ALU_ADD;
                immediate_select     = 3'b001;

                case (funct3)
                    3'b000, 
                    3'b001, 
                    3'b010: ;

                    default: illegal_instruction = 1'b1;
                endcase
            end

    
            OPCODE_BRANCH: begin
                branch_enable    = 1'b1;
                immediate_select = 3'b010;

                case (funct3)
                    3'b000, 
                    3'b001, 
                    3'b100, 
                    3'b101, 
                    3'b110, 
                    3'b111: ; 

                    default: illegal_instruction = 1'b1;
                endcase
            end


            OPCODE_JAL: begin
                register_write_enable = 1'b1;
                jump_enable            = 1'b1;
                immediate_select       = 3'b100;
                writeback_select       = 2'b10;
            end


            OPCODE_JALR: begin
                register_write_enable = 1'b1;
                jump_register_enable   = 1'b1;
                alu_source_b_select    = 1'b1;
                alu_operation          = ALU_ADD;
                immediate_select       = 3'b000;
                writeback_select       = 2'b10;

                if (funct3 != 3'b000)
                    illegal_instruction = 1'b1;
            end

            OPCODE_LUI: begin
                register_write_enable = 1'b1;
                alu_source_b_select    = 1'b1;
                alu_operation          = ALU_PASS;
                immediate_select       = 3'b011;
            end

            OPCODE_AUIPC: begin
                register_write_enable = 1'b1;
                alu_source_a_select    = 1'b1;
                alu_source_b_select    = 1'b1;
                alu_operation          = ALU_ADD;
                immediate_select       = 3'b011;
            end

            default: begin
                illegal_instruction = 1'b1;
            end
        endcase

        if (illegal_instruction) begin
            register_write_enable = 1'b0;
            memory_write_enable   = 1'b0;
            branch_enable         = 1'b0;
            jump_enable           = 1'b0;
            jump_register_enable  = 1'b0;
        end
    end

endmodule
