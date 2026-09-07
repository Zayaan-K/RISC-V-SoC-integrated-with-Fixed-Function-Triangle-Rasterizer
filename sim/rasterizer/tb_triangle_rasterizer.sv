`timescale 1ns / 1ps

module tb_triangle_rasterizer;

    localparam integer COORD_WIDTH = 16;
    localparam integer COLOR_WIDTH = 12;
    localparam integer COEFF_WIDTH = COORD_WIDTH + 1;
    localparam integer EDGE_WIDTH  = (2 * COORD_WIDTH) + 2;

    reg clk;
    reg reset;
    reg start;

    reg signed [COORD_WIDTH-1:0] min_x;
    reg signed [COORD_WIDTH-1:0] max_x;
    reg signed [COORD_WIDTH-1:0] min_y;
    reg signed [COORD_WIDTH-1:0] max_y;

    reg signed [EDGE_WIDTH-1:0] edge0_start;
    reg signed [EDGE_WIDTH-1:0] edge1_start;
    reg signed [EDGE_WIDTH-1:0] edge2_start;

    reg signed [COEFF_WIDTH-1:0] edge0_step_x;
    reg signed [COEFF_WIDTH-1:0] edge1_step_x;
    reg signed [COEFF_WIDTH-1:0] edge2_step_x;

    reg signed [COEFF_WIDTH-1:0] edge0_step_y;
    reg signed [COEFF_WIDTH-1:0] edge1_step_y;
    reg signed [COEFF_WIDTH-1:0] edge2_step_y;

    reg edge0_inclusive;
    reg edge1_inclusive;
    reg edge2_inclusive;

    reg [COLOR_WIDTH-1:0] triangle_color;

    wire framebuffer_write_enable;
    wire signed [COORD_WIDTH-1:0] framebuffer_x;
    wire signed [COORD_WIDTH-1:0] framebuffer_y;
    wire [COLOR_WIDTH-1:0] framebuffer_color;
    wire busy;
    wire done;

    integer write_count;
    integer error_count;

    integer expected_x [0:5];
    integer expected_y [0:5];

    triangle_rasterizer #(
        .COORD_WIDTH(COORD_WIDTH),
        .COLOR_WIDTH(COLOR_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .EDGE_WIDTH(EDGE_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),

        .min_x(min_x),
        .max_x(max_x),
        .min_y(min_y),
        .max_y(max_y),

        .edge0_start(edge0_start),
        .edge1_start(edge1_start),
        .edge2_start(edge2_start),

        .edge0_step_x(edge0_step_x),
        .edge1_step_x(edge1_step_x),
        .edge2_step_x(edge2_step_x),

        .edge0_step_y(edge0_step_y),
        .edge1_step_y(edge1_step_y),
        .edge2_step_y(edge2_step_y),

        .edge0_inclusive(edge0_inclusive),
        .edge1_inclusive(edge1_inclusive),
        .edge2_inclusive(edge2_inclusive),

        .triangle_color(triangle_color),

        .framebuffer_write_enable(framebuffer_write_enable),
        .framebuffer_x(framebuffer_x),
        .framebuffer_y(framebuffer_y),
        .framebuffer_color(framebuffer_color),

        .busy(busy),
        .done(done)
    );

    always #5 clk = ~clk;

    task pulse_start;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_for_done;
        integer timeout;
        begin
            timeout = 0;

            while (!done && timeout < 100) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (!done) begin
                $fatal(1, "Timeout waiting for rasterizer done");
            end
        end
    endtask

    /*
     * Observe outputs on the falling edge so all non-blocking assignments
     * made on the preceding rising edge have settled.
     */
    always @(negedge clk) begin
        if (framebuffer_write_enable) begin
            if (write_count >= 6) begin
                $error("Unexpected extra framebuffer write at (%0d, %0d)",
                       framebuffer_x, framebuffer_y);
                error_count = error_count + 1;
            end
            else begin
                if (($signed(framebuffer_x) != expected_x[write_count]) ||
                    ($signed(framebuffer_y) != expected_y[write_count])) begin
                    $error("Write %0d: expected (%0d, %0d), got (%0d, %0d)",
                           write_count,
                           expected_x[write_count], expected_y[write_count],
                           framebuffer_x, framebuffer_y);
                    error_count = error_count + 1;
                end

                if (framebuffer_color !== 12'hA5C) begin
                    $error("Write %0d: expected color A5C, got %h",
                           write_count, framebuffer_color);
                    error_count = error_count + 1;
                end
            end

            write_count = write_count + 1;
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        start = 1'b0;

        min_x = '0;
        max_x = '0;
        min_y = '0;
        max_y = '0;

        edge0_start = '0;
        edge1_start = '0;
        edge2_start = '0;

        edge0_step_x = '0;
        edge1_step_x = '0;
        edge2_step_x = '0;

        edge0_step_y = '0;
        edge1_step_y = '0;
        edge2_step_y = '0;

        edge0_inclusive = 1'b0;
        edge1_inclusive = 1'b0;
        edge2_inclusive = 1'b0;

        triangle_color = '0;

        write_count = 0;
        error_count = 0;

        expected_x[0] = 1; expected_y[0] = 1;
        expected_x[1] = 2; expected_y[1] = 1;
        expected_x[2] = 3; expected_y[2] = 1;
        expected_x[3] = 1; expected_y[3] = 2;
        expected_x[4] = 2; expected_y[4] = 2;
        expected_x[5] = 1; expected_y[5] = 3;

        repeat (3) @(posedge clk);
        reset = 1'b0;

        /*
         * Test 1: inclusive right triangle covering:
         *
         * (1,1), (2,1), (3,1)
         * (1,2), (2,2)
         * (1,3)
         *
         * Edge equations:
         *   E0 = y - 1
         *   E1 = 4 - x - y
         *   E2 = x - 1
         */
        min_x = 1;
        max_x = 3;
        min_y = 1;
        max_y = 3;

        edge0_start = 0;
        edge1_start = 2;
        edge2_start = 0;

        edge0_step_x =  0;
        edge1_step_x = -1;
        edge2_step_x =  1;

        edge0_step_y =  1;
        edge1_step_y = -1;
        edge2_step_y =  0;

        edge0_inclusive = 1'b1;
        edge1_inclusive = 1'b1;
        edge2_inclusive = 1'b1;

        triangle_color = 12'hA5C;

        pulse_start();

        if (!busy) begin
            $error("Rasterizer did not assert busy after a valid start");
            error_count = error_count + 1;
        end

        wait_for_done();

        if (write_count != 6) begin
            $error("Expected 6 framebuffer writes, got %0d", write_count);
            error_count = error_count + 1;
        end

        if (busy) begin
            $error("busy remained asserted after completion");
            error_count = error_count + 1;
        end

        /* Test 2: an invalid bounding box must finish without writing. */
        @(negedge clk);
        write_count = 0;

        min_x = 5;
        max_x = 3;
        min_y = 1;
        max_y = 3;

        pulse_start();
        wait_for_done();

        if (write_count != 0) begin
            $error("Invalid bounding box produced %0d writes", write_count);
            error_count = error_count + 1;
        end

        /* Test 3: a zero edge fails when that edge is not inclusive. */
        @(negedge clk);
        write_count = 0;

        min_x = 2;
        max_x = 2;
        min_y = 2;
        max_y = 2;

        edge0_start = 0;
        edge1_start = 1;
        edge2_start = 1;

        edge0_step_x = 0;
        edge1_step_x = 0;
        edge2_step_x = 0;

        edge0_step_y = 0;
        edge1_step_y = 0;
        edge2_step_y = 0;

        edge0_inclusive = 1'b0;
        edge1_inclusive = 1'b1;
        edge2_inclusive = 1'b1;

        pulse_start();
        wait_for_done();

        if (write_count != 0) begin
            $error("Non-inclusive boundary pixel was incorrectly written");
            error_count = error_count + 1;
        end

        if (error_count == 0) begin
            $display("PASS: all triangle_rasterizer tests completed successfully");
        end
        else begin
            $fatal(1, "FAIL: triangle_rasterizer testbench found %0d errors",
                   error_count);
        end

        $finish;
    end

endmodule
