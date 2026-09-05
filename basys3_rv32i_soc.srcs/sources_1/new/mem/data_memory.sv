`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
// Design Name: 
// Module Name: data_memory
// Project Name: 
// Target Devices: 
//////////////////////////////////////////////////////////////////////////////////


module data_memory #(
    parameter integer MEMORY_WORDS = 1024
) (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [3:0]  byte_enable,
    input  wire [31:0] address,
    input  wire [31:0] write_data,

    output wire [31:0] read_data
);

    localparam integer ADDRESS_WIDTH = $clog2(MEMORY_WORDS);

    reg [31:0] memory [0:MEMORY_WORDS-1];
    wire [ADDRESS_WIDTH-1:0] word_address;

    assign word_address = address[ADDRESS_WIDTH+1:2];
    assign read_data = memory[word_address];

    always_ff @(posedge clk) begin
        if (write_enable) begin

            if (byte_enable[0]) begin
                memory[word_address][7:0] <= write_data[7:0];
            end

            if (byte_enable[1]) begin
                memory[word_address][15:8] <= write_data[15:8];
            end

            if (byte_enable[2]) begin
                memory[word_address][23:16] <= write_data[23:16];
            end

            if (byte_enable[3]) begin
                memory[word_address][31:24] <= write_data[31:24];
            end

        end
    end

endmodule
