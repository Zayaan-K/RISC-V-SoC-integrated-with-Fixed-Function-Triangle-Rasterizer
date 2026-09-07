`timescale 1ns / 1ps

module framebuffer_reader #(
    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,
    parameter integer COLOR_WIDTH  = 12,
    parameter integer VGA_WIDTH    = 640,
    parameter integer VGA_HEIGHT   = 480,
    parameter integer VGA_X_WIDTH  = 10,
    parameter integer VGA_Y_WIDTH  = 10,
    parameter integer ADDRESS_WIDTH =
        $clog2(FRAME_WIDTH * FRAME_HEIGHT)
)(
    input wire clk,
    input wire reset,

    // Current timing signals from the VGA controller.
    input wire [VGA_X_WIDTH-1:0] vga_x,
    input wire [VGA_Y_WIDTH-1:0] vga_y,
    input wire                   vga_active_video,
    input wire                   vga_hsync,
    input wire                   vga_vsync,

    // Synchronous framebuffer read port.
    output reg  [ADDRESS_WIDTH-1:0] framebuffer_read_address,
    input  wire [COLOR_WIDTH-1:0]   framebuffer_read_color,

    // Pixel and timing signals aligned with framebuffer_read_color.
    output wire [COLOR_WIDTH-1:0] display_color,
    output reg                    display_active_video,
    output reg                    display_hsync,
    output reg                    display_vsync
);

    /*//=====================================================================
     * The 320x240 framebuffer is scaled to 640x480 by displaying every
     * stored pixel as a 2x2 block:
     *
     * framebuffer_x = vga_x / 2
     * framebuffer_y = vga_y / 2
     * address       = framebuffer_y * FRAME_WIDTH + framebuffer_x
     *
     * VGA_WIDTH and VGA_HEIGHT are checked here to prevent blanking-period
     * coordinates from producing an address outside the framebuffer.
     *///================================================================================

    wire [VGA_X_WIDTH-1:0] framebuffer_x;
    wire [VGA_Y_WIDTH-1:0] framebuffer_y;

    assign framebuffer_x = vga_x >> 1;
    assign framebuffer_y = vga_y >> 1;

    always @(*) begin
        framebuffer_read_address = {ADDRESS_WIDTH{1'b0}};

        if (vga_active_video &&
            (vga_x < VGA_WIDTH) &&
            (vga_y < VGA_HEIGHT)) begin
            framebuffer_read_address =
                (framebuffer_y * FRAME_WIDTH) + framebuffer_x;
        end
    end


    always @(posedge clk) begin
        if (reset) begin
            display_active_video <= 1'b0;
            display_hsync        <= 1'b1;
            display_vsync        <= 1'b1;
        end else begin
            display_active_video <= vga_active_video;
            display_hsync        <= vga_hsync;
            display_vsync        <= vga_vsync;
        end
    end

    // Force the display output to black during horizontal and vertical blanking.
    assign display_color = display_active_video
                         ? framebuffer_read_color
                         : {COLOR_WIDTH{1'b0}};

endmodule
