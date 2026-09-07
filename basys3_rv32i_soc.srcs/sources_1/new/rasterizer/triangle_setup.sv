`timescale 1ns / 1ps

module triangle_setup #(
    parameter integer COORD_WIDTH  = 16,
    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,

    parameter integer COEFF_WIDTH = COORD_WIDTH + 1,
    parameter integer EDGE_WIDTH  = (2 * COORD_WIDTH) + 3
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

    localparam [1:0] IDLE            = 2'd0;
    localparam [1:0] CALCULATE       = 2'd1;
    localparam [1:0] CALCULATE_START = 2'd2;
    localparam [1:0] FINISH          = 2'd3;

    localparam integer C_PRODUCT_WIDTH = 2 * COORD_WIDTH;
    localparam integer AREA_PRODUCT_WIDTH = 2 * (COORD_WIDTH + 1);
    localparam integer START_PRODUCT_WIDTH = COEFF_WIDTH + COORD_WIDTH;
    localparam signed [COORD_WIDTH-1:0] SCREEN_MAX_X = FRAME_WIDTH - 1;
    localparam signed [COORD_WIDTH-1:0] SCREEN_MAX_Y = FRAME_HEIGHT - 1;

    reg [1:0] state;

    // Captured vertices
    reg signed [COORD_WIDTH-1:0] x0_reg;
    reg signed [COORD_WIDTH-1:0] y0_reg;
    reg signed [COORD_WIDTH-1:0] x1_reg;
    reg signed [COORD_WIDTH-1:0] y1_reg;
    reg signed [COORD_WIDTH-1:0] x2_reg;
    reg signed [COORD_WIDTH-1:0] y2_reg;

    wire signed [COORD_WIDTH:0] x0_ext;
    wire signed [COORD_WIDTH:0] y0_ext;
    wire signed [COORD_WIDTH:0] x1_ext;
    wire signed [COORD_WIDTH:0] y1_ext;
    wire signed [COORD_WIDTH:0] x2_ext;
    wire signed [COORD_WIDTH:0] y2_ext;

    assign x0_ext = {x0_reg[COORD_WIDTH-1], x0_reg};
    assign y0_ext = {y0_reg[COORD_WIDTH-1], y0_reg};
    assign x1_ext = {x1_reg[COORD_WIDTH-1], x1_reg};
    assign y1_ext = {y1_reg[COORD_WIDTH-1], y1_reg};
    assign x2_ext = {x2_reg[COORD_WIDTH-1], x2_reg};
    assign y2_ext = {y2_reg[COORD_WIDTH-1], y2_reg};



    wire signed [COORD_WIDTH-1:0] raw_min_x;
    wire signed [COORD_WIDTH-1:0] raw_max_x;
    wire signed [COORD_WIDTH-1:0] raw_min_y;
    wire signed [COORD_WIDTH-1:0] raw_max_y;

    wire bbox_outside;

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

    assign raw_min_x = min2(min2(x0_reg, x1_reg), x2_reg);
    assign raw_max_x = max2(max2(x0_reg, x1_reg), x2_reg);

    assign raw_min_y = min2(min2(y0_reg, y1_reg), y2_reg);
    assign raw_max_y = max2(max2(y0_reg, y1_reg), y2_reg);

    assign bbox_outside = (raw_max_x < 0) || (raw_min_x > SCREEN_MAX_X) || (raw_max_y < 0) || (raw_min_y > SCREEN_MAX_Y);

    wire signed [COORD_WIDTH:0] dx10;
    wire signed [COORD_WIDTH:0] dy10;
    wire signed [COORD_WIDTH:0] dx20;
    wire signed [COORD_WIDTH:0] dy20;

    wire signed [AREA_PRODUCT_WIDTH-1:0] area_product_0;
    wire signed [AREA_PRODUCT_WIDTH-1:0] area_product_1;

    wire signed [EDGE_WIDTH-1:0] area_product_0_ext;
    wire signed [EDGE_WIDTH-1:0] area_product_1_ext;
    wire signed [EDGE_WIDTH-1:0] area_twice;

    assign dx10 = x1_ext - x0_ext;
    assign dy10 = y1_ext - y0_ext;
    assign dx20 = x2_ext - x0_ext;
    assign dy20 = y2_ext - y0_ext;

    assign area_product_0 = dx10 * dy20;
    assign area_product_1 = dy10 * dx20;

    assign area_product_0_ext = {
        {(EDGE_WIDTH-AREA_PRODUCT_WIDTH) {
            area_product_0[AREA_PRODUCT_WIDTH-1]
        }},
        area_product_0
    };

    assign area_product_1_ext = {
        {(EDGE_WIDTH-AREA_PRODUCT_WIDTH) {
            area_product_1[AREA_PRODUCT_WIDTH-1]
        }},
        area_product_1
    };

    assign area_twice =
        area_product_0_ext - area_product_1_ext;

    assign triangle_skip =
        (area_twice == 0) || bbox_outside;


     // E(x,y) = A*x + B*y + C
     

    wire signed [COEFF_WIDTH-1:0] raw_edge_a [0:2];
    wire signed [COEFF_WIDTH-1:0] raw_edge_b [0:2];
    wire signed [EDGE_WIDTH-1:0]  raw_edge_c [0:2];

    // Edge 0: v0 -> v1
    assign raw_edge_a[0] = y0_ext - y1_ext;
    assign raw_edge_b[0] = x1_ext - x0_ext;

    // Edge 1: v1 -> v2
    assign raw_edge_a[1] = y1_ext - y2_ext;
    assign raw_edge_b[1] = x2_ext - x1_ext;

    // Edge 2: v2 -> v0
    assign raw_edge_a[2] = y2_ext - y0_ext;
    assign raw_edge_b[2] = x0_ext - x2_ext;


    wire signed [C_PRODUCT_WIDTH-1:0] c0_product_0;
    wire signed [C_PRODUCT_WIDTH-1:0] c0_product_1;
    wire signed [C_PRODUCT_WIDTH-1:0] c1_product_0;
    wire signed [C_PRODUCT_WIDTH-1:0] c1_product_1;
    wire signed [C_PRODUCT_WIDTH-1:0] c2_product_0;
    wire signed [C_PRODUCT_WIDTH-1:0] c2_product_1;

    wire signed [EDGE_WIDTH-1:0] c0_product_0_ext;
    wire signed [EDGE_WIDTH-1:0] c0_product_1_ext;
    wire signed [EDGE_WIDTH-1:0] c1_product_0_ext;
    wire signed [EDGE_WIDTH-1:0] c1_product_1_ext;
    wire signed [EDGE_WIDTH-1:0] c2_product_0_ext;
    wire signed [EDGE_WIDTH-1:0] c2_product_1_ext;

    assign c0_product_0 = x0_reg * y1_reg;
    assign c0_product_1 = y0_reg * x1_reg;

    assign c1_product_0 = x1_reg * y2_reg;
    assign c1_product_1 = y1_reg * x2_reg;

    assign c2_product_0 = x2_reg * y0_reg;
    assign c2_product_1 = y2_reg * x0_reg;

    assign c0_product_0_ext = {
        {(EDGE_WIDTH-C_PRODUCT_WIDTH) {
            c0_product_0[C_PRODUCT_WIDTH-1]
        }},
        c0_product_0
    };

    assign c0_product_1_ext = {
        {(EDGE_WIDTH-C_PRODUCT_WIDTH) {
            c0_product_1[C_PRODUCT_WIDTH-1]
        }},
        c0_product_1
    };

    assign c1_product_0_ext = {
        {(EDGE_WIDTH-C_PRODUCT_WIDTH) {
            c1_product_0[C_PRODUCT_WIDTH-1]
        }},
        c1_product_0
    };

    assign c1_product_1_ext = {
        {(EDGE_WIDTH-C_PRODUCT_WIDTH) {
            c1_product_1[C_PRODUCT_WIDTH-1]
        }},
        c1_product_1
    };

    assign c2_product_0_ext = {
        {(EDGE_WIDTH-C_PRODUCT_WIDTH) {
            c2_product_0[C_PRODUCT_WIDTH-1]
        }},
        c2_product_0
    };

    assign c2_product_1_ext = {
        {(EDGE_WIDTH-C_PRODUCT_WIDTH) {
            c2_product_1[C_PRODUCT_WIDTH-1]
        }},
        c2_product_1
    };

    assign raw_edge_c[0] =
        c0_product_0_ext - c0_product_1_ext;

    assign raw_edge_c[1] =
        c1_product_0_ext - c1_product_1_ext;

    assign raw_edge_c[2] =
        c2_product_0_ext - c2_product_1_ext;


    wire signed [START_PRODUCT_WIDTH-1:0] edge_x_product [0:2];
    wire signed [START_PRODUCT_WIDTH-1:0] edge_y_product [0:2];

    wire signed [EDGE_WIDTH-1:0] edge_x_product_ext [0:2];
    wire signed [EDGE_WIDTH-1:0] edge_y_product_ext [0:2];

    wire signed [EDGE_WIDTH-1:0] calculated_edge_start [0:2];

    assign edge_x_product[0] = edge_a[0] * min_x;
    assign edge_x_product[1] = edge_a[1] * min_x;
    assign edge_x_product[2] = edge_a[2] * min_x;

    assign edge_y_product[0] = edge_b[0] * min_y;
    assign edge_y_product[1] = edge_b[1] * min_y;
    assign edge_y_product[2] = edge_b[2] * min_y;

    assign edge_x_product_ext[0] = {
        {(EDGE_WIDTH-START_PRODUCT_WIDTH) {
            edge_x_product[0][START_PRODUCT_WIDTH-1]
        }},
        edge_x_product[0]
    };

    assign edge_x_product_ext[1] = {
        {(EDGE_WIDTH-START_PRODUCT_WIDTH) {
            edge_x_product[1][START_PRODUCT_WIDTH-1]
        }},
        edge_x_product[1]
    };

    assign edge_x_product_ext[2] = {
        {(EDGE_WIDTH-START_PRODUCT_WIDTH) {
            edge_x_product[2][START_PRODUCT_WIDTH-1]
        }},
        edge_x_product[2]
    };

    assign edge_y_product_ext[0] = {
        {(EDGE_WIDTH-START_PRODUCT_WIDTH) {
            edge_y_product[0][START_PRODUCT_WIDTH-1]
        }},
        edge_y_product[0]
    };

    assign edge_y_product_ext[1] = {
        {(EDGE_WIDTH-START_PRODUCT_WIDTH) {
            edge_y_product[1][START_PRODUCT_WIDTH-1]
        }},
        edge_y_product[1]
    };

    assign edge_y_product_ext[2] = {
        {(EDGE_WIDTH-START_PRODUCT_WIDTH) {
            edge_y_product[2][START_PRODUCT_WIDTH-1]
        }},
        edge_y_product[2]
    };

    assign calculated_edge_start[0] =
        edge_x_product_ext[0] +
        edge_y_product_ext[0] +
        edge_c[0];

    assign calculated_edge_start[1] =
        edge_x_product_ext[1] +
        edge_y_product_ext[1] +
        edge_c[1];

    assign calculated_edge_start[2] =
        edge_x_product_ext[2] +
        edge_y_product_ext[2] +
        edge_c[2];

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;

            x0_reg <= 0;
            y0_reg <= 0;
            x1_reg <= 0;
            y1_reg <= 0;
            x2_reg <= 0;
            y2_reg <= 0;

            min_x <= 0;
            max_x <= 0;
            min_y <= 0;
            max_y <= 0;

            edge_a[0] <= 0;
            edge_a[1] <= 0;
            edge_a[2] <= 0;

            edge_b[0] <= 0;
            edge_b[1] <= 0;
            edge_b[2] <= 0;

            edge_c[0] <= 0;
            edge_c[1] <= 0;
            edge_c[2] <= 0;

            edge_start[0] <= 0;
            edge_start[1] <= 0;
            edge_start[2] <= 0;

            edge_inclusive <= 3'b000;

            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        x0_reg <= x0;
                        y0_reg <= y0;
                        x1_reg <= x1;
                        y1_reg <= y1;
                        x2_reg <= x2;
                        y2_reg <= y2;

                        busy  <= 1'b1;
                        state <= CALCULATE;
                    end
                end

                CALCULATE: begin
                    min_x <= (raw_min_x < 0)
                           ? 0
                           : raw_min_x;

                    max_x <= (raw_max_x > SCREEN_MAX_X)
                           ? SCREEN_MAX_X
                           : raw_max_x;

                    min_y <= (raw_min_y < 0)
                           ? 0
                           : raw_min_y;

                    max_y <= (raw_max_y > SCREEN_MAX_Y)
                           ? SCREEN_MAX_Y
                           : raw_max_y;
                    
                    //normalize so pos = triangle interior

                    if (area_twice > 0) begin
                        edge_a[0] <= raw_edge_a[0];
                        edge_a[1] <= raw_edge_a[1];
                        edge_a[2] <= raw_edge_a[2];

                        edge_b[0] <= raw_edge_b[0];
                        edge_b[1] <= raw_edge_b[1];
                        edge_b[2] <= raw_edge_b[2];

                        edge_c[0] <= raw_edge_c[0];
                        edge_c[1] <= raw_edge_c[1];
                        edge_c[2] <= raw_edge_c[2];
                    end else begin
                        edge_a[0] <= -raw_edge_a[0];
                        edge_a[1] <= -raw_edge_a[1];
                        edge_a[2] <= -raw_edge_a[2];

                        edge_b[0] <= -raw_edge_b[0];
                        edge_b[1] <= -raw_edge_b[1];
                        edge_b[2] <= -raw_edge_b[2];

                        edge_c[0] <= -raw_edge_c[0];
                        edge_c[1] <= -raw_edge_c[1];
                        edge_c[2] <= -raw_edge_c[2];
                    end

                    state <= CALCULATE_START;
                end

                CALCULATE_START: begin

                    edge_start[0] <= calculated_edge_start[0];
                    edge_start[1] <= calculated_edge_start[1];
                    edge_start[2] <= calculated_edge_start[2];

                    /*//=============================================
                     * Top-left edge inclusion rule.
                     * Screen Y coordinates increase downward.
                     *///=======================================

                    edge_inclusive[0] <=
                        (edge_a[0] > 0) ||
                        ((edge_a[0] == 0) &&
                         (edge_b[0] > 0));

                    edge_inclusive[1] <=
                        (edge_a[1] > 0) ||
                        ((edge_a[1] == 0) &&
                         (edge_b[1] > 0));

                    edge_inclusive[2] <=
                        (edge_a[2] > 0) ||
                        ((edge_a[2] == 0) &&
                         (edge_b[2] > 0));

                    state <= FINISH;
                end

                FINISH: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    busy  <= 1'b0;
                    done  <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
