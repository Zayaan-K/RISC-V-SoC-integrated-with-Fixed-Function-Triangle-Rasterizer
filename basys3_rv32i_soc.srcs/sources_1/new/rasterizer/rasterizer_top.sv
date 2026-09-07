`timescale 1ns / 1ps

module rasterizer_top #(
    parameter integer COORD_WIDTH  = 16,
    parameter integer COLOR_WIDTH  = 12,
    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,
    parameter integer COEFF_WIDTH  = COORD_WIDTH + 1,
    parameter integer EDGE_WIDTH   = (2 * COORD_WIDTH) + 3,
    parameter integer MMIO_ADDR_WIDTH = 6,
    parameter integer FRAMEBUFFER_ADDR_WIDTH =
        $clog2(FRAME_WIDTH * FRAME_HEIGHT)
)(
    input wire clk,
    input wire reset,

    input  wire                         mmio_write_enable,
    input  wire                         mmio_read_enable,
    input  wire [MMIO_ADDR_WIDTH-1:0]   mmio_address,
    input  wire [31:0]                  mmio_write_data,
    output wire [31:0]                  mmio_read_data,

    input  wire [FRAMEBUFFER_ADDR_WIDTH-1:0] framebuffer_read_address,
    output wire [COLOR_WIDTH-1:0]             framebuffer_read_color,

    output wire busy,
    output wire done
);

    wire signed [COORD_WIDTH-1:0] vertex_x0;
    wire signed [COORD_WIDTH-1:0] vertex_y0;
    wire signed [COORD_WIDTH-1:0] vertex_x1;
    wire signed [COORD_WIDTH-1:0] vertex_y1;
    wire signed [COORD_WIDTH-1:0] vertex_x2;
    wire signed [COORD_WIDTH-1:0] vertex_y2;
    wire [COLOR_WIDTH-1:0] register_triangle_color;
    wire register_start;

    wire setup_busy;
    wire setup_done;
    wire triangle_skip;

    wire signed [COORD_WIDTH-1:0] setup_min_x;
    wire signed [COORD_WIDTH-1:0] setup_max_x;
    wire signed [COORD_WIDTH-1:0] setup_min_y;
    wire signed [COORD_WIDTH-1:0] setup_max_y;

    wire signed [COEFF_WIDTH-1:0] setup_edge_a [0:2];
    wire signed [COEFF_WIDTH-1:0] setup_edge_b [0:2];
    wire signed [EDGE_WIDTH-1:0]  setup_edge_c [0:2];
    wire signed [EDGE_WIDTH-1:0]  setup_edge_start [0:2];
    wire [2:0] setup_edge_inclusive;

    wire rasterizer_start;
    wire rasterizer_core_busy;
    wire rasterizer_core_done;

    wire rasterizer_pixel_valid;
    wire signed [COORD_WIDTH-1:0] rasterizer_pixel_x;
    wire signed [COORD_WIDTH-1:0] rasterizer_pixel_y;
    wire [COLOR_WIDTH-1:0] rasterizer_pixel_color;

    wire framebuffer_write_enable;
    wire [FRAMEBUFFER_ADDR_WIDTH-1:0] framebuffer_write_address;
    wire [COLOR_WIDTH-1:0] framebuffer_write_color;

    reg [COLOR_WIDTH-1:0] active_triangle_color;

    assign rasterizer_start = setup_done && !triangle_skip;

    // Include the handoff pulses so busy does not drop between stages.
    assign busy = register_start || setup_busy || setup_done ||
                  rasterizer_core_busy;

    // Skipped triangles complete after setup without starting the rasterizer.
    assign done = rasterizer_core_done || (setup_done && triangle_skip);

    always @(posedge clk) begin
        if (reset)
            active_triangle_color <= '0;
        else if (register_start)
            active_triangle_color <= register_triangle_color;
    end

    rasterizer_registers #(
        .COORD_WIDTH (COORD_WIDTH),
        .COLOR_WIDTH (COLOR_WIDTH),
        .ADDR_WIDTH  (MMIO_ADDR_WIDTH)
    ) rasterizer_registers_instance (
        .clk             (clk),
        .reset           (reset),
        .write_enable    (mmio_write_enable),
        .read_enable     (mmio_read_enable),
        .address         (mmio_address),
        .write_data      (mmio_write_data),
        .read_data       (mmio_read_data),
        .rasterizer_busy (busy),
        .rasterizer_done (done),
        .x0              (vertex_x0),
        .y0              (vertex_y0),
        .x1              (vertex_x1),
        .y1              (vertex_y1),
        .x2              (vertex_x2),
        .y2              (vertex_y2),
        .triangle_color  (register_triangle_color),
        .start           (register_start)
    );

    triangle_setup #(
        .COORD_WIDTH  (COORD_WIDTH),
        .FRAME_WIDTH  (FRAME_WIDTH),
        .FRAME_HEIGHT (FRAME_HEIGHT),
        .COEFF_WIDTH  (COEFF_WIDTH),
        .EDGE_WIDTH   (EDGE_WIDTH)
    ) triangle_setup_instance (
        .clk            (clk),
        .reset          (reset),
        .start          (register_start),
        .x0             (vertex_x0),
        .y0             (vertex_y0),
        .x1             (vertex_x1),
        .y1             (vertex_y1),
        .x2             (vertex_x2),
        .y2             (vertex_y2),
        .busy           (setup_busy),
        .done           (setup_done),
        .triangle_skip  (triangle_skip),
        .min_x          (setup_min_x),
        .max_x          (setup_max_x),
        .min_y          (setup_min_y),
        .max_y          (setup_max_y),
        .edge_a         (setup_edge_a),
        .edge_b         (setup_edge_b),
        .edge_c         (setup_edge_c),
        .edge_start     (setup_edge_start),
        .edge_inclusive (setup_edge_inclusive)
    );

    triangle_rasterizer #(
        .COORD_WIDTH (COORD_WIDTH),
        .COLOR_WIDTH (COLOR_WIDTH),
        .COEFF_WIDTH (COEFF_WIDTH),
        .EDGE_WIDTH  (EDGE_WIDTH)
    ) triangle_rasterizer_instance (
        .clk                      (clk),
        .reset                    (reset),
        .start                    (rasterizer_start),
        .min_x                    (setup_min_x),
        .max_x                    (setup_max_x),
        .min_y                    (setup_min_y),
        .max_y                    (setup_max_y),
        .edge0_start              (setup_edge_start[0]),
        .edge1_start              (setup_edge_start[1]),
        .edge2_start              (setup_edge_start[2]),
        .edge0_step_x             (setup_edge_a[0]),
        .edge1_step_x             (setup_edge_a[1]),
        .edge2_step_x             (setup_edge_a[2]),
        .edge0_step_y             (setup_edge_b[0]),
        .edge1_step_y             (setup_edge_b[1]),
        .edge2_step_y             (setup_edge_b[2]),
        .edge0_inclusive          (setup_edge_inclusive[0]),
        .edge1_inclusive          (setup_edge_inclusive[1]),
        .edge2_inclusive          (setup_edge_inclusive[2]),
        .triangle_color           (active_triangle_color),
        .framebuffer_write_enable (rasterizer_pixel_valid),
        .framebuffer_x            (rasterizer_pixel_x),
        .framebuffer_y            (rasterizer_pixel_y),
        .framebuffer_color        (rasterizer_pixel_color),
        .busy                     (rasterizer_core_busy),
        .done                     (rasterizer_core_done)
    );

    framebuffer_writer #(
        .COORD_WIDTH   (COORD_WIDTH),
        .COLOR_WIDTH   (COLOR_WIDTH),
        .FRAME_WIDTH   (FRAME_WIDTH),
        .FRAME_HEIGHT  (FRAME_HEIGHT),
        .ADDRESS_WIDTH (FRAMEBUFFER_ADDR_WIDTH)
    ) framebuffer_writer_instance (
        .pixel_x                   (rasterizer_pixel_x),
        .pixel_y                   (rasterizer_pixel_y),
        .pixel_valid               (rasterizer_pixel_valid),
        .pixel_color               (rasterizer_pixel_color),
        .framebuffer_write_enable  (framebuffer_write_enable),
        .framebuffer_write_address (framebuffer_write_address),
        .framebuffer_write_data    (framebuffer_write_color)
    );

    frame_buffer #(
        .FRAME_WIDTH  (FRAME_WIDTH),
        .FRAME_HEIGHT (FRAME_HEIGHT),
        .COLOR_WIDTH  (COLOR_WIDTH),
        .ADDR_WIDTH   (FRAMEBUFFER_ADDR_WIDTH)
    ) frame_buffer_instance (
        .clk           (clk),
        .write_enable  (framebuffer_write_enable),
        .write_address (framebuffer_write_address),
        .write_color   (framebuffer_write_color),
        .read_address  (framebuffer_read_address),
        .read_color    (framebuffer_read_color)
    );

endmodule
