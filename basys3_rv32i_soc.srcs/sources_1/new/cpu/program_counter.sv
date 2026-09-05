`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// Engineer: 
// 
// Create Date: 09/04/2026 03:26:57 PM
// Design Name: 
// Module Name: program_counter
// Project Name: 
// Target Devices: 

//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module program_counter (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [31:0] next_pc,

    output reg  [31:0] pc
);

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 32'h0000_0000;
        end
        else if (enable) begin
            pc <= next_pc;
        end
    end

endmodule
