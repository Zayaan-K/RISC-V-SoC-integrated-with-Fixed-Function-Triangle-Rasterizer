`timescale 1ns/1ps
module tb_load_formatter;
    logic [31:0] memory_data;
    logic [1:0] address_offset;
    logic [2:0] funct3;
    wire [31:0] load_data;
    wire load_valid,misaligned;
    integer errors=0;
    load_formatter dut(.*);
    task automatic check(input [2:0] f,input [1:0] off,input [31:0] expected,input ev,em);
        begin funct3=f; address_offset=off; #1;
            if(load_data!==expected || load_valid!==ev || misaligned!==em) begin $error("load f=%b off=%d got=%h v=%b m=%b expected=%h v=%b m=%b",f,off,load_data,load_valid,misaligned,expected,ev,em); errors++; end
        end
    endtask
    initial begin
        memory_data=32'h80ff_7f01;
        check(3'b000,0,32'h00000001,1,0); check(3'b000,1,32'h0000007f,1,0);
        check(3'b000,2,32'hffffffff,1,0); check(3'b000,3,32'hffffff80,1,0);
        check(3'b100,2,32'h000000ff,1,0); check(3'b100,3,32'h00000080,1,0);
        check(3'b001,0,32'h00007f01,1,0); check(3'b001,2,32'hffff80ff,1,0);
        check(3'b101,2,32'h000080ff,1,0); check(3'b001,1,0,0,1); check(3'b101,3,0,0,1);
        check(3'b010,0,32'h80ff7f01,1,0); check(3'b010,2,0,0,1);
        check(3'b011,0,0,0,0);
        if(!errors) $display("PASS: tb_load_formatter"); else $fatal(1,"FAIL: tb_load_formatter (%0d)",errors);
        $finish;
    end
endmodule
