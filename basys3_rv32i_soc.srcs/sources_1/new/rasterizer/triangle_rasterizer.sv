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

    // Edge-equation change when moving one pixel right
    input wire signed [COEFF_WIDTH-1:0] edge0_step_x,
    input wire signed [COEFF_WIDTH-1:0] edge1_step_x,
    input wire signed [COEFF_WIDTH-1:0] edge2_step_x,

    // Edge-equation change when moving one pixel down
    input wire signed [COEFF_WIDTH-1:0] edge0_step_y,
    input wire signed [COEFF_WIDTH-1:0] edge1_step_y,
    input wire signed [COEFF_WIDTH-1:0] edge2_step_y,

    // Top-left rule
    input wire edge0_inclusive,
    input wire edge1_inclusive,
    input wire edge2_inclusive,

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

    reg signed [COORD_WIDTH-1:0] stored_min_x;
    reg signed [COORD_WIDTH-1:0] stored_max_x;
    reg signed [COORD_WIDTH-1:0] stored_max_y;

    // Edge values at the current pixel
    reg signed [EDGE_WIDTH-1:0] edge0_value;
    reg signed [EDGE_WIDTH-1:0] edge1_value;
    reg signed [EDGE_WIDTH-1:0] edge2_value;

    // Edge values at the first pixel of the current row
    reg signed [EDGE_WIDTH-1:0] edge0_row_start;
    reg signed [EDGE_WIDTH-1:0] edge1_row_start;
    reg signed [EDGE_WIDTH-1:0] edge2_row_start;


    reg signed [COEFF_WIDTH-1:0] stored_edge0_step_x;
    reg signed [COEFF_WIDTH-1:0] stored_edge1_step_x;
    reg signed [COEFF_WIDTH-1:0] stored_edge2_step_x;

    reg signed [COEFF_WIDTH-1:0] stored_edge0_step_y;
    reg signed [COEFF_WIDTH-1:0] stored_edge1_step_y;
    reg signed [COEFF_WIDTH-1:0] stored_edge2_step_y;

    // Captured top-left flags and color
    reg stored_edge0_inclusive;
    reg stored_edge1_inclusive;
    reg stored_edge2_inclusive;

    reg [COLOR_WIDTH-1:0] stored_triangle_color;

    // Inside-triangle test
    wire edge0_pass;
    wire edge1_pass;
    wire edge2_pass;
    wire pixel_inside;

    assign edge0_pass =(edge0_value > 0) || ((edge0_value == 0) && stored_edge0_inclusive);

    assign edge1_pass = (edge1_value > 0) || ((edge1_value == 0) && stored_edge1_inclusive);

    assign edge2_pass =(edge2_value > 0) || ((edge2_value == 0) && stored_edge2_inclusive);

    assign pixel_inside = edge0_pass && edge1_pass && edge2_pass;

    always_ff @(posedge clk) begin
        if (reset) begin
            current_x <= '0;
            current_y <= '0;

            stored_min_x <= '0;
            stored_max_x <= '0;
            stored_max_y <= '0;

            edge0_value <= '0;
            edge1_value <= '0;
            edge2_value <= '0;

            edge0_row_start <= '0;
            edge1_row_start <= '0;
            edge2_row_start <= '0;

            stored_edge0_step_x <= '0;
            stored_edge1_step_x <= '0;
            stored_edge2_step_x <= '0;

            stored_edge0_step_y <= '0;
            stored_edge1_step_y <= '0;
            stored_edge2_step_y <= '0;

            stored_edge0_inclusive <= 1'b0;
            stored_edge1_inclusive <= 1'b0;
            stored_edge2_inclusive <= 1'b0;

            stored_triangle_color <= '0;

            framebuffer_write_enable <= 1'b0;
            framebuffer_x            <= '0;
            framebuffer_y            <= '0;
            framebuffer_color        <= '0;

            busy <= 1'b0;
            done <= 1'b0;
        end
        else begin

            done                     <= 1'b0;
            framebuffer_write_enable <= 1'b0;

            if (start && !busy) begin
                
                //invalid triangle
                if ((min_x > max_x) || (min_y > max_y)) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
                else begin


                    stored_min_x <= min_x;
                    stored_max_x <= max_x;
                    stored_max_y <= max_y;

                    current_x <= min_x;
                    current_y <= min_y;


                    edge0_value <= edge0_start;
                    edge1_value <= edge1_start;
                    edge2_value <= edge2_start;


                    edge0_row_start <= edge0_start;
                    edge1_row_start <= edge1_start;
                    edge2_row_start <= edge2_start;

                    stored_edge0_step_x <= edge0_step_x;
                    stored_edge1_step_x <= edge1_step_x;
                    stored_edge2_step_x <= edge2_step_x;

                    stored_edge0_step_y <= edge0_step_y;
                    stored_edge1_step_y <= edge1_step_y;
                    stored_edge2_step_y <= edge2_step_y;

                    stored_edge0_inclusive <= edge0_inclusive;
                    stored_edge1_inclusive <= edge1_inclusive;
                    stored_edge2_inclusive <= edge2_inclusive;


                    stored_triangle_color <= triangle_color;

                    busy <= 1'b1;
                end
            end

            else if (busy) begin

                if (pixel_inside) begin
                    framebuffer_write_enable <= 1'b1;
                    framebuffer_x            <= current_x;
                    framebuffer_y            <= current_y;
                    framebuffer_color        <= stored_triangle_color;
                end

                
                if (current_x < stored_max_x) begin
                    current_x <= current_x + 1'b1;

                    edge0_value <=
                        edge0_value + stored_edge0_step_x;

                    edge1_value <=
                        edge1_value + stored_edge1_step_x;

                    edge2_value <=
                        edge2_value + stored_edge2_step_x;
                end

                else if (current_y < stored_max_y) begin
                    current_x <= stored_min_x;
                    current_y <= current_y + 1'b1;

                    edge0_row_start <= edge0_row_start + stored_edge0_step_y;
                    edge1_row_start <= edge1_row_start + stored_edge1_step_y;
                    edge2_row_start <= edge2_row_start + stored_edge2_step_y;
                    
                    edge0_value <= edge0_row_start + stored_edge0_step_y;
                    edge1_value <= edge1_row_start + stored_edge1_step_y;
                    edge2_value <= edge2_row_start + stored_edge2_step_y;
                end


                else begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end

endmodule
