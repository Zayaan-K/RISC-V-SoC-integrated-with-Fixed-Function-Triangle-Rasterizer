`timescale 1ns/1ps
module tb_branch_comparator;
    logic [31:0] rs1_data, rs2_data;
    logic [2:0] funct3;
    wire branch_taken, branch_valid;
    integer errors = 0;
    branch_comparator dut(.*);

    task automatic check(input [2:0] f, input [31:0] a,b, input exp_taken, exp_valid);
        begin
            funct3=f; rs1_data=a; rs2_data=b; #1;
            if (branch_taken !== exp_taken || branch_valid !== exp_valid) begin
                $error("branch f=%b a=%h b=%h got taken=%b valid=%b",f,a,b,branch_taken,branch_valid);
                errors++;
            end
        end
    endtask
    initial begin
        check(3'b000,5,5,1,1); check(3'b000,5,6,0,1);
        check(3'b001,5,6,1,1); check(3'b001,5,5,0,1);
        check(3'b100,32'hffff_ffff,1,1,1); check(3'b100,1,32'hffff_ffff,0,1);
        check(3'b101,1,32'hffff_ffff,1,1); check(3'b101,32'hffff_ffff,1,0,1);
        check(3'b110,1,32'hffff_ffff,1,1); check(3'b110,32'hffff_ffff,1,0,1);
        check(3'b111,32'hffff_ffff,1,1,1); check(3'b111,1,32'hffff_ffff,0,1);
        check(3'b010,0,0,0,0); check(3'b011,0,0,0,0);
        if (!errors) $display("PASS: tb_branch_comparator"); else $fatal(1,"FAIL: tb_branch_comparator (%0d)",errors);
        $finish;
    end
endmodule
