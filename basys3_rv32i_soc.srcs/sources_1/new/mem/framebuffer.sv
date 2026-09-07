module frame_buffer #(
    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,
    parameter integer COLOR_WIDTH  = 12,

    parameter integer FRAME_SIZE   = FRAME_WIDTH * FRAME_HEIGHT,
    parameter integer ADDR_WIDTH   = $clog2(FRAME_SIZE)
)(
    input wire clk,

    // Rasterizer write port
    input wire                      write_enable,
    input wire [ADDR_WIDTH-1:0]     write_address,
    input wire [COLOR_WIDTH-1:0]    write_color,

    // VGA read port
    input  wire [ADDR_WIDTH-1:0]    read_address,S
    output reg  [COLOR_WIDTH-1:0]   read_color
);

    // Instruct Vivado to implement this memory using block RAM.
    (* ram_style = "block" *)
    reg [COLOR_WIDTH-1:0] memory [0:FRAME_SIZE-1];


    always @(posedge clk) begin
        if (write_enable) begin
            memory[write_address] <= write_color;
        end
    end


    always @(posedge clk) begin
        read_color <= memory[read_address];
    end

endmodule
