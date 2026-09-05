`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
// Design Name: 
// Module Name: register_file
// Project Name: 
// Target Devices: 
//////////////////////////////////////////////////////////////////////////////////

module register_file (
    input  wire        clk,
    input  wire        reset,
    input  wire        writeEnable,

    input  wire [4:0]  rs1Address,
    input  wire [4:0]  rs2Address,
    input  wire [4:0]  rdAddress,

    input  wire [31:0] rdData,

    output wire [31:0] rs1Data,
    output wire [31:0] rs2Data
);

    reg [31:0] registers [0:31];

    integer i;

    // x0 always prod zero
    assign rs1Data = (rs1Address == 5'd0) ? 32'b0 : registers[rs1Address];

    assign rs2Data = (rs2Address == 5'd0) ? 32'b0: registers[rs2Address];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end
        else if (writeEnable && (rdAddress != 5'd0)) begin
            registers[rdAddress] <= rdData;
        end
    end

endmodule
