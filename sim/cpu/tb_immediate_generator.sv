`timescale 1ns/1ps
module tb_immediate_generator;
    logic [31:0] instruction;
    logic [2:0] immediateSelect;
    wire [31:0] immediate;
    integer errors=0;
    immediate_generator dut(.*);

    task automatic check(input [31:0] insn, input [2:0] sel, input [31:0] expected);
        begin instruction=insn; immediateSelect=sel; #1;
            if (immediate !== expected) begin $error("imm sel=%b insn=%h got=%h expected=%h",sel,insn,immediate,expected); errors++; end
        end
    endtask
    function automatic [31:0] enc_s(input integer imm); enc_s={imm[11:5],5'd2,5'd1,3'b010,imm[4:0],7'b0100011}; endfunction
    function automatic [31:0] enc_b(input integer imm); enc_b={imm[12],imm[10:5],5'd2,5'd1,3'b000,imm[4:1],imm[11],7'b1100011}; endfunction
    function automatic [31:0] enc_j(input integer imm); enc_j={imm[20],imm[10:1],imm[11],imm[19:12],5'd1,7'b1101111}; endfunction
    initial begin
        check({12'h7ff,20'b0},3'b000,32'h0000_07ff);
        check({12'h800,20'b0},3'b000,32'hffff_f800);
        check(enc_s(12'h37c),3'b001,32'h0000_037c);
        check(enc_s(-16),3'b001,32'hffff_fff0);
        check(enc_b(16),3'b010,32'd16);
        check(enc_b(-16),3'b010,32'hffff_fff0);
        check(32'habcde037,3'b011,32'habcde000);
        check(enc_j(2048),3'b100,32'd2048);
        check(enc_j(-2048),3'b100,32'hffff_f800);
        check(0,3'b111,0);
        if (!errors) $display("PASS: tb_immediate_generator"); else $fatal(1,"FAIL: tb_immediate_generator (%0d)",errors);
        $finish;
    end
endmodule
