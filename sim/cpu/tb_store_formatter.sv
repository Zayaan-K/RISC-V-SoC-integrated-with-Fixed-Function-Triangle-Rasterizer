`timescale 1ns/1ps
module tb_store_formatter;
    logic [31:0] register_data;
    logic [1:0] address_offset;
    logic [2:0] funct3;
    wire [31:0] write_data;
    wire [3:0] byte_enable;
    wire store_valid,misaligned;
    integer errors=0;
    store_formatter dut(.*);
    task automatic check(input [2:0] f,input [1:0] off,input [31:0] ed,input [3:0] eb,input ev,em);
        begin funct3=f; address_offset=off; #1;
            if(write_data!==ed || byte_enable!==eb || store_valid!==ev || misaligned!==em) begin $error("store f=%b off=%d got=%h be=%b v=%b m=%b",f,off,write_data,byte_enable,store_valid,misaligned); errors++; end
        end
    endtask
    initial begin
        register_data=32'ha1b2c3d4;
        check(3'b000,0,32'h000000d4,4'b0001,1,0); check(3'b000,1,32'h0000d400,4'b0010,1,0);
        check(3'b000,2,32'h00d40000,4'b0100,1,0); check(3'b000,3,32'hd4000000,4'b1000,1,0);
        check(3'b001,0,32'h0000c3d4,4'b0011,1,0); check(3'b001,2,32'hc3d40000,4'b1100,1,0);
        check(3'b001,1,0,0,0,1); check(3'b001,3,0,0,0,1);
        check(3'b010,0,32'ha1b2c3d4,4'b1111,1,0); check(3'b010,1,0,0,0,1);
        check(3'b111,0,0,0,0,0);
        if(!errors) $display("PASS: tb_store_formatter"); else $fatal(1,"FAIL: tb_store_formatter (%0d)",errors);
        $finish;
    end
endmodule
