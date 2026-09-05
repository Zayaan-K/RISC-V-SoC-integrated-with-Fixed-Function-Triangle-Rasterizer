`timescale 1ns/1ps
module tb_control_unit;
    logic [6:0] opcode,funct7;
    logic [2:0] funct3;
    wire register_write_enable,memory_write_enable,alu_source_a_select,alu_source_b_select;
    wire [3:0] alu_operation;
    wire [2:0] immediate_select;
    wire [1:0] writeback_select;
    wire branch_enable,jump_enable,jump_register_enable,illegal_instruction;
    integer errors=0;
    control_unit dut(.*);
    task automatic check_control(input rw,mw,sa,sb,input [3:0] op,input [2:0] imm,input [1:0] wb,input br,j,jr,ill);
        begin #1;
            if({register_write_enable,memory_write_enable,alu_source_a_select,alu_source_b_select,alu_operation,immediate_select,writeback_select,branch_enable,jump_enable,jump_register_enable,illegal_instruction} !== {rw,mw,sa,sb,op,imm,wb,br,j,jr,ill}) begin
                $error("control opcode=%b f3=%b f7=%b",opcode,funct3,funct7); errors++;
            end
        end
    endtask
    task automatic rtype(input [2:0] f3,input [6:0] f7,input [3:0] op);
        begin opcode=7'b0110011;funct3=f3;funct7=f7;check_control(1,0,0,0,op,0,0,0,0,0,0);end
    endtask
    task automatic itype(input [2:0] f3,input [6:0] f7,input [3:0] op);
        begin opcode=7'b0010011;funct3=f3;funct7=f7;check_control(1,0,0,1,op,0,0,0,0,0,0);end
    endtask
    initial begin
        rtype(0,7'b0000000,0); rtype(0,7'b0100000,1); rtype(1,0,2); rtype(2,0,3); rtype(3,0,4);
        rtype(4,0,5); rtype(5,0,6); rtype(5,7'b0100000,7); rtype(6,0,8); rtype(7,0,9);
        itype(0,0,0); itype(2,0,3); itype(3,0,4); itype(4,0,5); itype(6,0,8); itype(7,0,9);
        itype(1,0,2); itype(5,0,6); itype(5,7'b0100000,7);
        opcode=7'b0000011; funct3=3'b010; funct7=0; check_control(1,0,0,1,0,0,1,0,0,0,0);
        opcode=7'b0100011; funct3=3'b001; check_control(0,1,0,1,0,1,0,0,0,0,0);
        opcode=7'b1100011; funct3=3'b111; check_control(0,0,0,0,0,2,0,1,0,0,0);
        opcode=7'b1101111; funct3=0; check_control(1,0,0,0,0,4,2,0,1,0,0);
        opcode=7'b1100111; funct3=0; check_control(1,0,0,1,0,0,2,0,0,1,0);
        opcode=7'b0110111; check_control(1,0,0,1,4'ha,3,0,0,0,0,0);
        opcode=7'b0010111; check_control(1,0,1,1,0,3,0,0,0,0,0);
        opcode=7'b1111111; funct3=0; funct7=0; check_control(0,0,0,0,0,0,0,0,0,0,1);
        opcode=7'b0110011; funct3=0; funct7=7'b1111111; check_control(0,0,0,0,0,0,0,0,0,0,1);
        opcode=7'b0100011; funct3=3'b111; funct7=0; check_control(0,0,0,1,0,1,0,0,0,0,1);
        if(!errors) $display("PASS: tb_control_unit"); else $fatal(1,"FAIL: tb_control_unit (%0d)",errors);
        $finish;
    end
endmodule
