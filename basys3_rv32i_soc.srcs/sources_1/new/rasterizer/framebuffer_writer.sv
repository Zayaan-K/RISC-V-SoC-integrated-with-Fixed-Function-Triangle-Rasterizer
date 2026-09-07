`timescale 1ns / 1ps

module framebuffer_writer #(
    parameter integer COORD_WIDTH  = 16,
    parameter integer COLOR_WIDTH  = 12,
    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,
    parameter integer ADDRESS_WIDTH =
        $clog2(FRAME_WIDTH * FRAME_HEIGHT)
)(
    // Pixel produced
    input  wire signed [COORD_WIDTH-1:0] pixel_x,
    input  wire signed [COORD_WIDTH-1:0] pixel_y,
    input  wire                          pixel_valid,
    input  wire        [COLOR_WIDTH-1:0] pixel_color,

    // Write port
    output reg                           framebuffer_write_enable,
    output reg  [ADDRESS_WIDTH-1:0]      framebuffer_write_address,
    output reg  [COLOR_WIDTH-1:0]        framebuffer_write_data
);

    localparam integer PIXEL_COUNT = FRAME_WIDTH * FRAME_HEIGHT;

    /*//=======================================================================================================
     * Converts a two-dimensional pixel coordinate into a linear address to save logic cells
     *
     * address = (y * FRAME_WIDTH) + x
     *///========================================================================================================

    always @(*) begin
        framebuffer_write_enable  = 1'b0;
        framebuffer_write_address = {ADDRESS_WIDTH{1'b0}};
        framebuffer_write_data    = pixel_color;

        if (
            pixel_valid &&
            (pixel_x >= 0) &&
            (pixel_x < FRAME_WIDTH) &&
            (pixel_y >= 0) &&
            (pixel_y < FRAME_HEIGHT)
        ) begin
            framebuffer_write_enable = 1'b1;

            framebuffer_write_address =
                ($unsigned(pixel_y) * FRAME_WIDTH) +
                $unsigned(pixel_x);
        end
    end

endmodule
