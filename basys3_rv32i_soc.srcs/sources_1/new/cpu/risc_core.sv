`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
// Create Date: 09/04/2026 03:37:21 PM
// Design Name: 
// Module Name: risc_core
// Project Name: 
// Target Devices: 
//////////////////////////////////////////////////////////////////////



module risc_core (
    input  wire        clk,
    input  wire        reset,


    output wire [31:0] instruction_address,
    input  wire [31:0] instruction,

    output wire [31:0] data_address,
    output wire [31:0] data_write_data,
    output wire [3:0]  data_byte_enable,
    output wire        data_write_enable,
    input  wire [31:0] data_read_data,
    output wire        illegal_instruction,
    output wire        instruction_address_misaligned,
    output wire        data_address_misaligned,
    output wire        halted
);

    localparam [1:0] PC_PLUS_4 = 2'b00;
    localparam [1:0] PC_BRANCH = 2'b01;
    localparam [1:0] PC_JAL    = 2'b10;
    localparam [1:0] PC_JALR   = 2'b11;
    localparam [1:0] WRITEBACK_ALU  = 2'b00;
    localparam [1:0] WRITEBACK_LOAD = 2'b01;
    localparam [1:0] WRITEBACK_PC4  = 2'b10;

    wire [6:0] opcode;
    wire [4:0] rd_address;
    wire [2:0] funct3;
    wire [4:0] rs1_address;
    wire [4:0] rs2_address;
    wire [6:0] funct7;

    assign opcode      = instruction[6:0];
    assign rd_address  = instruction[11:7];
    assign funct3      = instruction[14:12];
    assign rs1_address = instruction[19:15];
    assign rs2_address = instruction[24:20];
    assign funct7      = instruction[31:25];

    wire       register_write_enable_control;
    wire       memory_write_enable_control;
    wire       alu_source_a_select;
    wire       alu_source_b_select;
    wire [3:0] alu_operation;
    wire [2:0] immediate_select;
    wire [1:0] writeback_select;
    wire       branch_enable;
    wire       jump_enable;
    wire       jump_register_enable;

    wire [31:0] current_pc;
    wire [31:0] next_pc;
    wire [31:0] pc_plus_4;
    wire [31:0] immediate;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    reg  [31:0] alu_operand_a;
    reg  [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    reg  [31:0] writeback_data;

    wire       branch_taken;
    wire       branch_valid;
    reg  [1:0] pc_select;
    wire       next_pc_misaligned;

    wire [31:0] load_data;
    wire        load_valid;
    wire        load_misaligned;
    wire [31:0] store_write_data;
    wire [3:0]  store_byte_enable;
    wire        store_valid;
    wire        store_misaligned;

    wire load_access;
    wire load_fault;
    wire store_fault;
    wire core_fault;
    wire register_write_enable;
    wire pc_enable;

    assign instruction_address = current_pc;
    assign pc_plus_4            = current_pc + 32'd4;
    assign data_address         = alu_result;

    assign load_access = (writeback_select == WRITEBACK_LOAD);
    assign load_fault  = load_access && (!load_valid || load_misaligned);
    assign store_fault = memory_write_enable_control &&
                         (!store_valid || store_misaligned);

    assign instruction_address_misaligned = next_pc_misaligned;
    assign data_address_misaligned =
        (load_access && load_misaligned) ||
        (memory_write_enable_control && store_misaligned);

    assign core_fault = illegal_instruction |
                        instruction_address_misaligned |
                        load_fault |
                        store_fault;

    assign halted = core_fault;
    assign pc_enable = !core_fault;

    assign register_write_enable = register_write_enable_control &&
                                   !core_fault;

    assign data_write_enable = memory_write_enable_control &&
                               store_valid &&
                               !store_misaligned &&
                               !illegal_instruction &&
                               !instruction_address_misaligned;

    assign data_write_data  = store_write_data;
    assign data_byte_enable = data_write_enable ? store_byte_enable : 4'b0000;

    always_comb begin
        if (alu_source_a_select)
            alu_operand_a = current_pc;
        else
            alu_operand_a = rs1_data;

        if (alu_source_b_select)
            alu_operand_b = immediate;
        else
            alu_operand_b = rs2_data;
    end

    always_comb begin
        case (writeback_select)
            WRITEBACK_ALU:  writeback_data = alu_result;
            WRITEBACK_LOAD: writeback_data = load_data;
            WRITEBACK_PC4:  writeback_data = pc_plus_4;
            default:        writeback_data = 32'b0;
        endcase
    end

    always_comb begin
        pc_select = PC_PLUS_4;

        if (jump_register_enable)
            pc_select = PC_JALR;
        else if (jump_enable)
            pc_select = PC_JAL;
        else if (branch_enable && branch_valid && branch_taken)
            pc_select = PC_BRANCH;
    end

    control_unit control_unit_inst (
        .opcode                  (opcode),
        .funct3                  (funct3),
        .funct7                  (funct7),
        .register_write_enable   (register_write_enable_control),
        .memory_write_enable     (memory_write_enable_control),
        .alu_source_a_select     (alu_source_a_select),
        .alu_source_b_select     (alu_source_b_select),
        .alu_operation           (alu_operation),
        .immediate_select        (immediate_select),
        .writeback_select        (writeback_select),
        .branch_enable           (branch_enable),
        .jump_enable             (jump_enable),
        .jump_register_enable    (jump_register_enable),
        .illegal_instruction     (illegal_instruction)
    );

    program_counter program_counter_inst (
        .clk     (clk),
        .reset   (reset),
        .enable  (pc_enable),
        .next_pc (next_pc),
        .pc      (current_pc)
    );

    register_file register_file_inst (
        .clk         (clk),
        .reset       (reset),
        .writeEnable (register_write_enable),
        .rs1Address  (rs1_address),
        .rs2Address  (rs2_address),
        .rdAddress   (rd_address),
        .rdData      (writeback_data),
        .rs1Data     (rs1_data),
        .rs2Data     (rs2_data)
    );

    immediate_generator immediate_generator_inst (
        .instruction    (instruction),
        .immediateSelect(immediate_select),
        .immediate      (immediate)
    );

    alu alu_inst (
        .operandA  (alu_operand_a),
        .operandB  (alu_operand_b),
        .aluSelect (alu_operation),
        .result    (alu_result),
        .zero      (alu_zero)
    );

    branch_comparator branch_comparator_inst (
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .funct3       (funct3),
        .branch_taken (branch_taken),
        .branch_valid (branch_valid)
    );

    next_instruction_incrementor next_instruction_incrementor_inst (
        .current_pc (current_pc),
        .immediate  (immediate),
        .rs1_data   (rs1_data),
        .pc_select  (pc_select),
        .next_pc    (next_pc),
        .misaligned (next_pc_misaligned)
    );

    load_formatter load_formatter_inst (
        .memory_data   (data_read_data),
        .address_offset(alu_result[1:0]),
        .funct3        (funct3),
        .load_data     (load_data),
        .load_valid    (load_valid),
        .misaligned    (load_misaligned)
    );

    store_formatter store_formatter_inst (
        .register_data (rs2_data),
        .address_offset(alu_result[1:0]),
        .funct3        (funct3),
        .write_data    (store_write_data),
        .byte_enable   (store_byte_enable),
        .store_valid   (store_valid),
        .misaligned    (store_misaligned)
    );

endmodule
