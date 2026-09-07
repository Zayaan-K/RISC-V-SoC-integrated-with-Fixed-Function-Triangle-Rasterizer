module triangle_setup #(
    parameter integer COORD_WIDTH  = 16,
    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,

    parameter integer COEFF_WIDTH = COORD_WIDTH + 1,
    parameter integer EDGE_WIDTH  = (2 * COORD_WIDTH) + 2
)(
    input wire clk,
    input wire reset,
    input wire start,

    input wire signed [COORD_WIDTH-1:0] x0,
    input wire signed [COORD_WIDTH-1:0] y0,
    input wire signed [COORD_WIDTH-1:0] x1,
    input wire signed [COORD_WIDTH-1:0] y1,
    input wire signed [COORD_WIDTH-1:0] x2,
    input wire signed [COORD_WIDTH-1:0] y2,

    output reg  busy,
    output reg  done,
    output wire triangle_skip,

    output reg signed [COORD_WIDTH-1:0] min_x,
    output reg signed [COORD_WIDTH-1:0] max_x,
    output reg signed [COORD_WIDTH-1:0] min_y,
    output reg signed [COORD_WIDTH-1:0] max_y,

    output reg signed [COEFF_WIDTH-1:0] edge_a [0:2],
    output reg signed [COEFF_WIDTH-1:0] edge_b [0:2],
    output reg signed [EDGE_WIDTH-1:0]  edge_c [0:2],

    output reg signed [EDGE_WIDTH-1:0] edge_start [0:2],
    output reg [2:0] edge_inclusive
);


    localparam IDLE      = 2'd0;
    localparam CALCULATE = 2'd1;
    localparam FINISH    = 2'd2;

    reg [1:0] state;
    
    reg signed [COORD_WIDTH-1:0] x0_reg;
    reg signed [COORD_WIDTH-1:0] y0_reg;
    reg signed [COORD_WIDTH-1:0] x1_reg;
    reg signed [COORD_WIDTH-1:0] y1_reg;
    reg signed [COORD_WIDTH-1:0] x2_reg;
    reg signed [COORD_WIDTH-1:0] y2_reg;

    // Coordinate differences require one extra bit.
    wire signed [COORD_WIDTH:0] dx10;
    wire signed [COORD_WIDTH:0] dy10;
    wire signed [COORD_WIDTH:0] dx20;
    wire signed [COORD_WIDTH:0] dy20;

    // Signed double-area of the triangle.
    wire signed [EDGE_WIDTH-1:0] area_twice;

    function signed [COORD_WIDTH-1:0] min2;
        input signed [COORD_WIDTH-1:0] a;
        input signed [COORD_WIDTH-1:0] b;
        begin
            min2 = (a < b) ? a : b;
        end
    endfunction

    function signed [COORD_WIDTH-1:0] max2;
        input signed [COORD_WIDTH-1:0] a;
        input signed [COORD_WIDTH-1:0] b;
        begin
            max2 = (a > b) ? a : b;
        end
    endfunction 
    


    assign dx10 = x1_reg - x0_reg;
    assign dy10 = y1_reg - y0_reg;
    assign dx20 = x2_reg - x0_reg;
    assign dy20 = y2_reg - y0_reg;

    assign area_twice = (dx10 * dy20) - (dy10 * dx20);

    assign triangle_skip = (area_twice == 0);

    always @(posedge clk) begin
        if (reset) begin
            x0_reg <= 0;
            y0_reg <= 0;
            x1_reg <= 0;
            y1_reg <= 0;
            x2_reg <= 0;
            y2_reg <= 0;

            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                x0_reg <= x0;
                y0_reg <= y0;
                x1_reg <= x1;
                y1_reg <= y1;
                x2_reg <= x2;
                y2_reg <= y2;

                busy <= 1'b1;
            end
        end
    end

endmodule


