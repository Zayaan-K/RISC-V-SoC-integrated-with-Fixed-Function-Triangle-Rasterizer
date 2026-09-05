`timescale 1ns/1ps
module tb_next_instruction_incrementor;
    logic [31:0] current_pc,immediate,rs1_data;
    logic [1:0] pc_select;
    wire [31:0] next_pc;
    wire misaligned;
    integer errors=0;
    next_instruction_incrementor dut(.*);
    task automatic check(input [1:0] sel,input [31:0] pc,imm,rs1,expected,input exp_misaligned);
        begin pc_select=sel; current_pc=pc; immediate=imm; rs1_data=rs1; #1;
            if(next_pc!==expected || misaligned!==exp_misaligned) begin $error("nextpc got=%h m=%b expected=%h m=%b",next_pc,misaligned,expected,exp_misaligned); errors++; end
        end
    endtask
    initial begin
        check(0,32'h100,0,0,32'h104,0);
        check(1,32'h100,32'h20,0,32'h120,0);
        check(1,32'h100,32'hffff_fff0,0,32'h0f0,0);
        check(2,32'h100,32'h06,0,32'h106,1);
        check(3,0,3,32'h100,32'h102,1);
        check(3,0,5,32'h100,32'h104,0);
        check(3,0,1,32'h102,32'h102,1);
        if(!errors) $display("PASS: tb_next_instruction_incrementor"); else $fatal(1,"FAIL: tb_next_instruction_incrementor (%0d)",errors);
        $finish;
    end
endmodule
