`timescale 1ns / 1ps


module triangle_rasterizer #(
    parameter integer COORD_WIDTH = 16,
    parameter integer COLOR_WIDTH = 12,

    parameter integer COEFF_WIDTH = COORD_WIDTH + 1,
    parameter integer EDGE_WIDTH  = (2 * COORD_WIDTH) + 2
)(
    input wire clk,
    input wire reset,
    input wire start,

    // Bounding box
    input wire signed [COORD_WIDTH-1:0] min_x,
    input wire signed [COORD_WIDTH-1:0] max_x,
    input wire signed [COORD_WIDTH-1:0] min_y,
    input wire signed [COORD_WIDTH-1:0] max_y,

    // Edge-equation values at (min_x, min_y)
    input wire signed [EDGE_WIDTH-1:0] edge0_start,
    input wire signed [EDGE_WIDTH-1:0] edge1_start,
    input wire signed [EDGE_WIDTH-1:0] edge2_start,

    // Change in each edge equation for x + 1
    input wire signed [COEFF_WIDTH-1:0] edge0_step_x,
    input wire signed [COEFF_WIDTH-1:0] edge1_step_x,
    input wire signed [COEFF_WIDTH-1:0] edge2_step_x,

    // Change in each edge equation for y + 1
    input wire signed [COEFF_WIDTH-1:0] edge0_step_y,
    input wire signed [COEFF_WIDTH-1:0] edge1_step_y,
    input wire signed [COEFF_WIDTH-1:0] edge2_step_y,

    input wire edge0_inclusive,
    input wire edge1_inclusive,
    input wire edge2_inclusive,

    // Flat triangle color
    input wire [COLOR_WIDTH-1:0] triangle_color,

    output reg framebuffer_write_enable,
    output reg signed [COORD_WIDTH-1:0] framebuffer_x,
    output reg signed [COORD_WIDTH-1:0] framebuffer_y,
    output reg [COLOR_WIDTH-1:0] framebuffer_color,

    output reg busy,
    output reg done
);


    reg signed [COORD_WIDTH-1:0] current_x;
    reg signed [COORD_WIDTH-1:0] current_y;

    reg signed [EDGE_WIDTH-1:0] edge0_value;
    reg signed [EDGE_WIDTH-1:0] edge1_value;
    reg signed [EDGE_WIDTH-1:0] edge2_value;
    reg signed [EDGE_WIDTH-1:0] edge0_row_start;
    reg signed [EDGE_WIDTH-1:0] edge1_row_start;
    reg signed [EDGE_WIDTH-1:0] edge2_row_start;

    wire edge0_pass;
    wire edge1_pass;
    wire edge2_pass;
    wire pixel_inside;

    assign edge0_pass =(edge0_value > 0) || ((edge0_value == 0) && edge0_inclusive);
    assign edge1_pass = (edge1_value > 0) || ((edge1_value == 0) && edge1_inclusive);
    assign edge2_pass = (edge2_value > 0) ||((edge2_value == 0) && edge2_inclusive);

    assign pixel_inside = edge0_pass && edge1_pass && edge2_pass;


    always_ff @(posedge clk) begin
        if (reset) begin
            current_x <= '0;
            current_y <= '0;

            edge0_value <= '0;
            edge1_value <= '0;
            edge2_value <= '0;

            edge0_row_start <= '0;
            edge1_row_start <= '0;
            edge2_row_start <= '0;

            busy <= 1'b0;
            done <= 1'b0;
        end
        else begin
            
            done <= 1'b0;

            if (start && !busy) begin
                current_x <= min_x;
                current_y <= min_y;

                edge0_value <= edge0_start;
                edge1_value <= edge1_start;
                edge2_value <= edge2_start;

                edge0_row_start <= edge0_start;
                edge1_row_start <= edge1_start;
                edge2_row_start <= edge2_start;

                busy <= 1'b1;
            end

            else if (busy) begin
 
                if (pixel_inside) begin
                    framebuffer_write_enable <= 1'b1;
                    framebuffer_x            <= current_x;
                    framebuffer_y            <= current_y;
                    framebuffer_color        <= triangle_color;
                end


                if (current_x < max_x) begin
                    current_x <= current_x + 1'b1;

                    edge0_value <= edge0_value + edge0_step_x;
                    edge1_value <= edge1_value + edge1_step_x;
                    edge2_value <= edge2_value + edge2_step_x;
                end
            end
            
        end
    end


endmodule
