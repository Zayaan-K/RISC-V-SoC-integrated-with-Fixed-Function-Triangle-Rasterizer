`timescale 1ns/1ps
module tb_alu;
    logic [31:0] operandA, operandB;
    logic [3:0] aluSelect;
    wire [31:0] result;
    wire zero;
    integer errors = 0;

    alu dut(.*);

    task automatic check(input [3:0] op, input [31:0] a, b, expected);
        begin
            aluSelect = op; operandA = a; operandB = b; #1;
            if (result !== expected || zero !== (expected == 0)) begin
                $error("ALU op=%h a=%h b=%h got=%h z=%b expected=%h", op,a,b,result,zero,expected);
                errors++;
            end
        end
    endtask

    initial begin
        check(4'h0, 32'd10, 32'd7, 32'd17);
        check(4'h0, 32'hffff_ffff, 1, 0);
        check(4'h1, 32'd7, 32'd10, 32'hffff_fffd);
        check(4'h2, 32'h1, 32'd31, 32'h8000_0000);
        check(4'h2, 32'h1, 32'd32, 32'h1);
        check(4'h3, 32'hffff_ffff, 1, 1);
        check(4'h3, 1, 32'hffff_ffff, 0);
        check(4'h4, 32'hffff_ffff, 1, 0);
        check(4'h5, 32'ha5a5_5a5a, 32'hffff_0000, 32'h5a5a_5a5a);
        check(4'h6, 32'h8000_0000, 31, 1);
        check(4'h7, 32'h8000_0000, 31, 32'hffff_ffff);
        check(4'h8, 32'hf000_0000, 32'h0f00_000f, 32'hff00_000f);
        check(4'h9, 32'hf0f0_aa55, 32'h0ff0_ff00, 32'h00f0_aa00);
        check(4'ha, 32'hdead_beef, 32'h1234_5678, 32'h1234_5678);
        check(4'hf, 1, 2, 0);
        if (errors == 0) $display("PASS: tb_alu"); else $fatal(1, "FAIL: tb_alu (%0d errors)", errors);
        $finish;
    end
endmodule
