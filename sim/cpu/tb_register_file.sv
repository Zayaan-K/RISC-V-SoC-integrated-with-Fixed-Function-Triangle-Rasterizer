`timescale 1ns/1ps
module tb_register_file;
    logic clk=0, reset, writeEnable;
    logic [4:0] rs1Address,rs2Address,rdAddress;
    logic [31:0] rdData;
    wire [31:0] rs1Data,rs2Data;
    integer errors=0;
    always #5 clk=~clk;
    register_file dut(.*);
    task automatic check(input [31:0] a,b);
        begin #1; if(rs1Data!==a || rs2Data!==b) begin $error("rf got %h,%h expected %h,%h",rs1Data,rs2Data,a,b); errors++; end end
    endtask
    initial begin
        reset=1; writeEnable=0; rs1Address=0; rs2Address=31; rdAddress=0; rdData=0;
        @(posedge clk); #1; reset=0; check(0,0);
        writeEnable=1; rdAddress=5; rdData=32'h12345678; @(posedge clk); rs1Address=5; rs2Address=0; check(32'h12345678,0);
        rdAddress=0; rdData=32'hffff_ffff; @(posedge clk); rs1Address=0; check(0,0);
        rdAddress=31; rdData=32'hdead_beef; @(posedge clk); rs2Address=31; check(0,32'hdead_beef);
        reset=1; @(posedge clk); check(0,0);
        if(!errors) $display("PASS: tb_register_file"); else $fatal(1,"FAIL: tb_register_file (%0d)",errors);
        $finish;
    end
endmodule
