`timescale 1ns / 1ps

module tb_triangle_setup;

    localparam integer COORD_WIDTH  = 16;
    localparam integer FRAME_WIDTH  = 320;
    localparam integer FRAME_HEIGHT = 240;

    localparam integer COEFF_WIDTH =
        COORD_WIDTH + 1;

    localparam integer EDGE_WIDTH =
        (2 * COORD_WIDTH) + 3;

    reg clk;
    reg reset;
    reg start;

    reg signed [COORD_WIDTH-1:0] x0;
    reg signed [COORD_WIDTH-1:0] y0;
    reg signed [COORD_WIDTH-1:0] x1;
    reg signed [COORD_WIDTH-1:0] y1;
    reg signed [COORD_WIDTH-1:0] x2;
    reg signed [COORD_WIDTH-1:0] y2;

    wire busy;
    wire done;
    wire triangle_skip;

    wire signed [COORD_WIDTH-1:0] min_x;
    wire signed [COORD_WIDTH-1:0] max_x;
    wire signed [COORD_WIDTH-1:0] min_y;
    wire signed [COORD_WIDTH-1:0] max_y;

    wire signed [COEFF_WIDTH-1:0] edge_a [0:2];
    wire signed [COEFF_WIDTH-1:0] edge_b [0:2];
    wire signed [EDGE_WIDTH-1:0]  edge_c [0:2];

    wire signed [EDGE_WIDTH-1:0] edge_start [0:2];
    wire [2:0] edge_inclusive;

    integer error_count;

    triangle_setup #(
        .COORD_WIDTH(COORD_WIDTH),
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .COEFF_WIDTH(COEFF_WIDTH),
        .EDGE_WIDTH(EDGE_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),

        .x0(x0),
        .y0(y0),
        .x1(x1),
        .y1(y1),
        .x2(x2),
        .y2(y2),

        .busy(busy),
        .done(done),
        .triangle_skip(triangle_skip),

        .min_x(min_x),
        .max_x(max_x),
        .min_y(min_y),
        .max_y(max_y),

        .edge_a(edge_a),
        .edge_b(edge_b),
        .edge_c(edge_c),

        .edge_start(edge_start),
        .edge_inclusive(edge_inclusive)
    );

    /*
     * 100 MHz clock
     */

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    /*
     * Submit one triangle and wait for setup to finish.
     */

    task submit_triangle;
        input signed [COORD_WIDTH-1:0] test_x0;
        input signed [COORD_WIDTH-1:0] test_y0;
        input signed [COORD_WIDTH-1:0] test_x1;
        input signed [COORD_WIDTH-1:0] test_y1;
        input signed [COORD_WIDTH-1:0] test_x2;
        input signed [COORD_WIDTH-1:0] test_y2;

        begin
            wait (busy == 1'b0);

            @(negedge clk);

            x0 = test_x0;
            y0 = test_y0;
            x1 = test_x1;
            y1 = test_y1;
            x2 = test_x2;
            y2 = test_y2;

            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            wait (done == 1'b1);
            #1;
        end
    endtask

    /*
     * Check the bounding-box outputs.
     */

    task check_bounding_box;
        input integer expected_min_x;
        input integer expected_max_x;
        input integer expected_min_y;
        input integer expected_max_y;

        begin
            if ($signed(min_x) != expected_min_x) begin
                $error(
                    "min_x incorrect: expected %0d, got %0d",
                    expected_min_x,
                    $signed(min_x)
                );

                error_count = error_count + 1;
            end

            if ($signed(max_x) != expected_max_x) begin
                $error(
                    "max_x incorrect: expected %0d, got %0d",
                    expected_max_x,
                    $signed(max_x)
                );

                error_count = error_count + 1;
            end

            if ($signed(min_y) != expected_min_y) begin
                $error(
                    "min_y incorrect: expected %0d, got %0d",
                    expected_min_y,
                    $signed(min_y)
                );

                error_count = error_count + 1;
            end

            if ($signed(max_y) != expected_max_y) begin
                $error(
                    "max_y incorrect: expected %0d, got %0d",
                    expected_max_y,
                    $signed(max_y)
                );

                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        reset = 1'b1;
        start = 1'b0;

        x0 = 0;
        y0 = 0;
        x1 = 0;
        y1 = 0;
        x2 = 0;
        y2 = 0;

        error_count = 0;

        /*
         * Hold reset for several clock cycles.
         */

        repeat (3) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        /*
         * Test 1:
         * Valid on-screen triangle
         *
         * v0 = (20,20)
         * v1 = (100,20)
         * v2 = (20,100)
         */

        $display("Test 1: valid on-screen triangle");

        submit_triangle(
            20, 20,
            100, 20,
            20, 100
        );

        if (triangle_skip != 1'b0) begin
            $error("Test 1: valid triangle was skipped");
            error_count = error_count + 1;
        end

        check_bounding_box(
            20, 100,
            20, 100
        );

        /*
         * Expected normalized edge equations:
         *
         * Edge 0:  0*x + 80*y - 1600
         * Edge 1: -80*x - 80*y + 9600
         * Edge 2: 80*x +  0*y - 1600
         */

        if (
            ($signed(edge_a[0]) != 0)  ||
            ($signed(edge_b[0]) != 80) ||
            ($signed(edge_c[0]) != -1600)
        ) begin
            $error("Test 1: edge 0 coefficients incorrect");
            error_count = error_count + 1;
        end

        if (
            ($signed(edge_a[1]) != -80) ||
            ($signed(edge_b[1]) != -80) ||
            ($signed(edge_c[1]) != 9600)
        ) begin
            $error("Test 1: edge 1 coefficients incorrect");
            error_count = error_count + 1;
        end

        if (
            ($signed(edge_a[2]) != 80) ||
            ($signed(edge_b[2]) != 0)  ||
            ($signed(edge_c[2]) != -1600)
        ) begin
            $error("Test 1: edge 2 coefficients incorrect");
            error_count = error_count + 1;
        end

        /*
         * At the first bounding-box pixel (20,20):
         *
         * edge 0 = 0
         * edge 1 = 6400
         * edge 2 = 0
         */

        if ($signed(edge_start[0]) != 0) begin
            $error(
                "Test 1: edge_start[0] expected 0, got %0d",
                $signed(edge_start[0])
            );

            error_count = error_count + 1;
        end

        if ($signed(edge_start[1]) != 6400) begin
            $error(
                "Test 1: edge_start[1] expected 6400, got %0d",
                $signed(edge_start[1])
            );

            error_count = error_count + 1;
        end

        if ($signed(edge_start[2]) != 0) begin
            $error(
                "Test 1: edge_start[2] expected 0, got %0d",
                $signed(edge_start[2])
            );

            error_count = error_count + 1;
        end

        if (edge_inclusive != 3'b101) begin
            $error(
                "Test 1: edge_inclusive expected 101, got %b",
                edge_inclusive
            );

            error_count = error_count + 1;
        end

        /*
         * Test 2:
         * Same triangle with reversed vertex order.
         *
         * The edge ordering changes, but the normalized
         * equations should still point toward the interior.
         */

        $display("Test 2: reversed vertex order");

        submit_triangle(
            20, 20,
            20, 100,
            100, 20
        );

        if (triangle_skip != 1'b0) begin
            $error("Test 2: reversed triangle was skipped");
            error_count = error_count + 1;
        end

        check_bounding_box(
            20, 100,
            20, 100
        );

        if (
            ($signed(edge_start[0]) < 0) ||
            ($signed(edge_start[1]) < 0) ||
            ($signed(edge_start[2]) < 0)
        ) begin
            $error(
                "Test 2: normalized edge-start values should be nonnegative"
            );

            error_count = error_count + 1;
        end

        /*
         * Test 3:
         * Collinear vertices produce zero area.
         */

        $display("Test 3: zero-area triangle");

        submit_triangle(
            10, 10,
            20, 20,
            30, 30
        );

        if (triangle_skip != 1'b1) begin
            $error("Test 3: zero-area triangle was not skipped");
            error_count = error_count + 1;
        end

        /*
         * Test 4:
         * Triangle partially outside the left side.
         *
         * The triangle remains visible, but min_x must
         * be clipped to zero.
         */

        $display("Test 4: partially off-screen triangle");

        submit_triangle(
            -20, 10,
            50, 10,
            10, 50
        );

        if (triangle_skip != 1'b0) begin
            $error(
                "Test 4: partially visible triangle was skipped"
            );

            error_count = error_count + 1;
        end

        check_bounding_box(
            0, 50,
            10, 50
        );

        /*
         * Test 5:
         * Triangle completely outside the left side.
         */

        $display("Test 5: completely off-screen triangle");

        submit_triangle(
            -30, 10,
            -20, 50,
            -10, 20
        );

        if (triangle_skip != 1'b1) begin
            $error(
                "Test 5: completely off-screen triangle was not skipped"
            );

            error_count = error_count + 1;
        end

        /*
         * Final result
         */

        if (error_count == 0) begin
            $display("----------------------------------------");
            $display("All triangle_setup tests passed");
            $display("----------------------------------------");
        end else begin
            $fatal(
                1,
                "triangle_setup failed with %0d errors",
                error_count
            );
        end

        $finish;
    end

    /*
     * Simulation timeout
     */

    initial begin
        #10000;

        $fatal(
            1,
            "Simulation timed out before all tests completed"
        );
    end

endmodule
