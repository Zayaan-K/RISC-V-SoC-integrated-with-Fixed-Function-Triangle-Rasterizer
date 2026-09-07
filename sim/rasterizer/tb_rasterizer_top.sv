`timescale 1ns / 1ps

module tb_rasterizer_top;

    localparam integer COORD_WIDTH  = 16;
    localparam integer COLOR_WIDTH  = 12;
    localparam integer FRAME_WIDTH  = 320;
    localparam integer FRAME_HEIGHT = 240;
    localparam integer MMIO_ADDR_WIDTH = 6;
    localparam integer FRAMEBUFFER_ADDR_WIDTH =
        $clog2(FRAME_WIDTH * FRAME_HEIGHT);

    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_CONTROL = 6'h00;
    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_STATUS  = 6'h04;
    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_X0      = 6'h08;
    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_Y0      = 6'h0C;
    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_X1      = 6'h10;
    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_Y1      = 6'h14;
    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_X2      = 6'h18;
    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_Y2      = 6'h1C;
    localparam [MMIO_ADDR_WIDTH-1:0] ADDR_COLOR   = 6'h20;

    localparam [COLOR_WIDTH-1:0] TEST_COLOR = 12'hF35;
    localparam [COLOR_WIDTH-1:0] SKIP_COLOR = 12'h0AF;

    reg clk;
    reg reset;

    reg                          mmio_write_enable;
    reg                          mmio_read_enable;
    reg  [MMIO_ADDR_WIDTH-1:0]   mmio_address;
    reg  [31:0]                  mmio_write_data;
    wire [31:0]                  mmio_read_data;

    reg  [FRAMEBUFFER_ADDR_WIDTH-1:0] framebuffer_read_address;
    wire [COLOR_WIDTH-1:0]             framebuffer_read_color;

    wire busy;
    wire done;

    integer error_count;
    integer colored_pixel_count;
    integer x;
    integer y;
    integer timeout_count;

    reg [31:0] status_value;
    reg [COLOR_WIDTH-1:0] sampled_color;

    rasterizer_top #(
        .COORD_WIDTH  (COORD_WIDTH),
        .COLOR_WIDTH  (COLOR_WIDTH),
        .FRAME_WIDTH  (FRAME_WIDTH),
        .FRAME_HEIGHT (FRAME_HEIGHT),
        .MMIO_ADDR_WIDTH (MMIO_ADDR_WIDTH),
        .FRAMEBUFFER_ADDR_WIDTH (FRAMEBUFFER_ADDR_WIDTH)
    ) dut (
        .clk                      (clk),
        .reset                    (reset),
        .mmio_write_enable        (mmio_write_enable),
        .mmio_read_enable         (mmio_read_enable),
        .mmio_address             (mmio_address),
        .mmio_write_data          (mmio_write_data),
        .mmio_read_data           (mmio_read_data),
        .framebuffer_read_address (framebuffer_read_address),
        .framebuffer_read_color   (framebuffer_read_color),
        .busy                     (busy),
        .done                     (done)
    );

    always #5 clk = ~clk;

    task automatic mmio_write;
        input [MMIO_ADDR_WIDTH-1:0] write_address;
        input [31:0] write_value;
        begin
            @(negedge clk);
            mmio_address      = write_address;
            mmio_write_data   = write_value;
            mmio_write_enable = 1'b1;

            @(negedge clk);
            mmio_write_enable = 1'b0;
            mmio_address      = '0;
            mmio_write_data   = '0;
        end
    endtask

    task automatic mmio_read;
        input  [MMIO_ADDR_WIDTH-1:0] read_address;
        output [31:0] read_value;
        begin
            @(negedge clk);
            mmio_address     = read_address;
            mmio_read_enable = 1'b1;
            #1 read_value    = mmio_read_data;

            @(negedge clk);
            mmio_read_enable = 1'b0;
            mmio_address     = '0;
        end
    endtask

    task automatic read_pixel;
        input integer pixel_x;
        input integer pixel_y;
        output [COLOR_WIDTH-1:0] pixel_color;
        integer linear_address;
        begin
            linear_address = (pixel_y * FRAME_WIDTH) + pixel_x;

            @(negedge clk);
            framebuffer_read_address = linear_address;

            // frame_buffer uses a synchronous read port.
            @(posedge clk);
            #1 pixel_color = framebuffer_read_color;
        end
    endtask

    task automatic wait_for_completion;
        begin
            timeout_count = 0;
            while ((busy !== 1'b1) && (timeout_count < 20)) begin
                @(posedge clk);
                #1;
                timeout_count = timeout_count + 1;
            end

            if (busy !== 1'b1) begin
                $error("Rasterizer never asserted busy");
                error_count = error_count + 1;
            end

            timeout_count = 0;
            while ((done !== 1'b1) && (timeout_count < 500)) begin
                @(posedge clk);
                #1;
                timeout_count = timeout_count + 1;
            end

            if (done !== 1'b1) begin
                $error("Rasterizer did not finish before timeout");
                error_count = error_count + 1;
            end

            // Allow the final registered framebuffer write and sticky
            // done-status update to complete.
            repeat (2) @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk                      = 1'b0;
        reset                    = 1'b1;
        mmio_write_enable        = 1'b0;
        mmio_read_enable         = 1'b0;
        mmio_address             = '0;
        mmio_write_data          = '0;
        framebuffer_read_address = '0;
        error_count              = 0;
        colored_pixel_count      = 0;
        status_value             = '0;
        sampled_color            = '0;

        repeat (4) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // Triangle vertices: (2,2), (6,2), (2,6).
        // With the top-left rule, the expected stored pixels are:
        // y=2: x=2..5
        // y=3: x=2..4
        // y=4: x=2..3
        // y=5: x=2
        // Total: 10 pixels.
        mmio_write(ADDR_X0,    32'd2);
        mmio_write(ADDR_Y0,    32'd2);
        mmio_write(ADDR_X1,    32'd6);
        mmio_write(ADDR_Y1,    32'd2);
        mmio_write(ADDR_X2,    32'd2);
        mmio_write(ADDR_Y2,    32'd6);
        mmio_write(ADDR_COLOR, {20'b0, TEST_COLOR});
        mmio_write(ADDR_CONTROL, 32'h0000_0001);

        wait_for_completion();

        mmio_read(ADDR_STATUS, status_value);

        if (status_value[0] !== 1'b0) begin
            $error("Busy status remained set after completion");
            error_count = error_count + 1;
        end

        if (status_value[1] !== 1'b1) begin
            $error("Sticky done status was not set");
            error_count = error_count + 1;
        end

        colored_pixel_count = 0;

        for (y = 0; y <= 8; y = y + 1) begin
            for (x = 0; x <= 8; x = x + 1) begin
                read_pixel(x, y, sampled_color);

                if (sampled_color === TEST_COLOR)
                    colored_pixel_count = colored_pixel_count + 1;
            end
        end

        if (colored_pixel_count != 10) begin
            $error("Expected 10 colored pixels, found %0d",
                   colored_pixel_count);
            error_count = error_count + 1;
        end

        read_pixel(2, 2, sampled_color);
        if (sampled_color !== TEST_COLOR) begin
            $error("Expected interior pixel (2,2) to be colored");
            error_count = error_count + 1;
        end

        read_pixel(3, 3, sampled_color);
        if (sampled_color !== TEST_COLOR) begin
            $error("Expected interior pixel (3,3) to be colored");
            error_count = error_count + 1;
        end

        read_pixel(6, 2, sampled_color);
        if (sampled_color === TEST_COLOR) begin
            $error("Diagonal-edge pixel (6,2) should be excluded");
            error_count = error_count + 1;
        end

        read_pixel(1, 2, sampled_color);
        if (sampled_color === TEST_COLOR) begin
            $error("Exterior pixel (1,2) was incorrectly colored");
            error_count = error_count + 1;
        end

        // Clear the sticky done flag.
        mmio_write(ADDR_CONTROL, 32'h0000_0002);
        mmio_read(ADDR_STATUS, status_value);

        if (status_value[1] !== 1'b0) begin
            $error("Sticky done status did not clear");
            error_count = error_count + 1;
        end

        // Submit a completely off-screen triangle. Setup should skip it,
        // report completion, and produce no SKIP_COLOR framebuffer writes.
        mmio_write(ADDR_X0,    -32'sd10);
        mmio_write(ADDR_Y0,    -32'sd10);
        mmio_write(ADDR_X1,    -32'sd5);
        mmio_write(ADDR_Y1,    -32'sd10);
        mmio_write(ADDR_X2,    -32'sd10);
        mmio_write(ADDR_Y2,    -32'sd5);
        mmio_write(ADDR_COLOR, {20'b0, SKIP_COLOR});
        mmio_write(ADDR_CONTROL, 32'h0000_0001);

        wait_for_completion();

        read_pixel(0, 0, sampled_color);
        if (sampled_color === SKIP_COLOR) begin
            $error("Off-screen triangle unexpectedly wrote a pixel");
            error_count = error_count + 1;
        end

        mmio_read(ADDR_STATUS, status_value);
        if (status_value[1] !== 1'b1) begin
            $error("Skipped triangle did not set done status");
            error_count = error_count + 1;
        end

        if (error_count == 0)
            $display("PASS: rasterizer_top completed all tests");
        else
            $fatal(1, "FAIL: rasterizer_top reported %0d errors",
                   error_count);

        $finish;
    end

endmodule
