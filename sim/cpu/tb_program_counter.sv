`timescale 1ns/1ps
module tb_program_counter;
    logic clk=0, reset, enable;
    logic [31:0] next_pc;
    wire [31:0] pc;
    integer errors=0;
    always #5 clk=~clk;
    program_counter dut(.*);
    task automatic check_pc(input [31:0] value);
        begin #1; if(pc!==value) begin $error("pc=%h expected=%h",pc,value); errors++; end end
    endtask
    initial begin
        reset=1; enable=0; next_pc=32'h1234; @(posedge clk); check_pc(0);
        reset=0; enable=1; next_pc=32'h100; @(posedge clk); check_pc(32'h100);
        enable=0; next_pc=32'h200; @(posedge clk); check_pc(32'h100);
        enable=1; @(posedge clk); check_pc(32'h200);
        reset=1; @(posedge clk); check_pc(0);
        if(!errors) $display("PASS: tb_program_counter"); else $fatal(1,"FAIL: tb_program_counter (%0d)",errors);
        $finish;
    end
endmodule
