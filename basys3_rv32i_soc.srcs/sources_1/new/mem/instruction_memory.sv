`timescale 1ns / 1ps

module instruction_memory #(
    parameter integer MEMORY_WORDS = 1024,
    parameter         INIT_FILE    = ""
) (
    input  wire [31:0] address,
    output wire [31:0] instruction
);

    localparam integer ADDRESS_WIDTH = $clog2(MEMORY_WORDS);

    reg [31:0] memory [0:MEMORY_WORDS-1];
    wire [ADDRESS_WIDTH-1:0] word_address;

    assign word_address = address[ADDRESS_WIDTH+1:2];
    assign instruction = memory[word_address];


    //init program 
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

endmodule


