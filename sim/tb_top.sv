`timescale 1ns / 1ps

module tb_top;

    localparam integer FRAME_WIDTH  = 320;
    localparam integer FRAME_HEIGHT = 240;
    localparam integer COLOR_WIDTH  = 12;

    localparam [COLOR_WIDTH-1:0] TEST_COLOR = 12'hF35;

    reg clk;
    reg reset;

    wire [3:0] vgaRed;
    wire [3:0] vgaGreen;
    wire [3:0] vgaBlue;
    wire Hsync;
    wire Vsync;

    wire illegal_instruction;
    wire instruction_address_misaligned;
    wire data_address_misaligned;
    wire halted;
    wire rasterizer_busy;
    wire rasterizer_done;

    integer error_count;
    integer colored_pixel_count;
    integer timeout_count;
    integer x;
    integer y;
    integer address;

    top #(
        .INSTRUCTION_WORDS (1024),
        .DATA_WORDS        (1024),
        .INSTRUCTION_INIT_FILE (""),
        .FRAME_WIDTH       (FRAME_WIDTH),
        .FRAME_HEIGHT      (FRAME_HEIGHT),
        .COLOR_WIDTH       (COLOR_WIDTH)
    ) dut (
        .clk                            (clk),
        .reset                          (reset),
        .vgaRed                         (vgaRed),
        .vgaGreen                       (vgaGreen),
        .vgaBlue                        (vgaBlue),
        .Hsync                          (Hsync),
        .Vsync                          (Vsync),
        .illegal_instruction            (illegal_instruction),
        .instruction_address_misaligned (instruction_address_misaligned),
        .data_address_misaligned        (data_address_misaligned),
        .halted                         (halted),
        .rasterizer_busy                (rasterizer_busy),
        .rasterizer_done                (rasterizer_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk                 = 1'b0;
        reset               = 1'b1;
        error_count         = 0;
        colored_pixel_count = 0;
        timeout_count       = 0;

        /*
         * RV32I test program:
         *
         * x1 = 0x4000_0000 rasterizer base address
         * triangle = (2,2), (6,2), (2,6)
         * color = 12'hF35
         * write 1 to the control register
         * loop forever
         */

        dut.instruction_memory_instance.memory[0]  = 32'h4000_00B7; // lui  x1,0x40000
        dut.instruction_memory_instance.memory[1]  = 32'h0020_0113; // addi x2,x0,2
        dut.instruction_memory_instance.memory[2]  = 32'h0020_A423; // sw   x2,8(x1)
        dut.instruction_memory_instance.memory[3]  = 32'h0020_A623; // sw   x2,12(x1)
        dut.instruction_memory_instance.memory[4]  = 32'h0060_0113; // addi x2,x0,6
        dut.instruction_memory_instance.memory[5]  = 32'h0020_A823; // sw   x2,16(x1)
        dut.instruction_memory_instance.memory[6]  = 32'h0020_0113; // addi x2,x0,2
        dut.instruction_memory_instance.memory[7]  = 32'h0020_AA23; // sw   x2,20(x1)
        dut.instruction_memory_instance.memory[8]  = 32'h0020_AC23; // sw   x2,24(x1)
        dut.instruction_memory_instance.memory[9]  = 32'h0060_0113; // addi x2,x0,6
        dut.instruction_memory_instance.memory[10] = 32'h0020_AE23; // sw   x2,28(x1)
        dut.instruction_memory_instance.memory[11] = 32'hF350_0113; // addi x2,x0,-203
        dut.instruction_memory_instance.memory[12] = 32'h0220_A023; // sw   x2,32(x1)
        dut.instruction_memory_instance.memory[13] = 32'h0010_0113; // addi x2,x0,1
        dut.instruction_memory_instance.memory[14] = 32'h0020_A023; // sw   x2,0(x1)
        dut.instruction_memory_instance.memory[15] = 32'h0000_006F; // jal  x0,0

        repeat (5) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // Wait for the program to submit the triangle.
        timeout_count = 0;
        while ((rasterizer_busy !== 1'b1) && (timeout_count < 100)) begin
            @(posedge clk);
            #1;
            timeout_count = timeout_count + 1;
        end

        if (rasterizer_busy !== 1'b1) begin
            $error("CPU did not start the rasterizer");
            error_count = error_count + 1;
        end

        // Wait for triangle rasterization to finish.
        timeout_count = 0;
        while ((rasterizer_done !== 1'b1) && (timeout_count < 500)) begin
            @(posedge clk);
            #1;
            timeout_count = timeout_count + 1;
        end

        if (rasterizer_done !== 1'b1) begin
            $error("Rasterizer did not finish before timeout");
            error_count = error_count + 1;
        end

        // Allow the final registered framebuffer write to commit.
        repeat (2) @(posedge clk);
        #1;

        if (halted !== 1'b0) begin
            $error("CPU halted while running the test program");
            error_count = error_count + 1;
        end

        if (illegal_instruction !== 1'b0) begin
            $error("CPU reported an illegal instruction");
            error_count = error_count + 1;
        end

        if (instruction_address_misaligned !== 1'b0) begin
            $error("CPU reported a misaligned instruction address");
            error_count = error_count + 1;
        end

        if (data_address_misaligned !== 1'b0) begin
            $error("CPU reported a misaligned data address");
            error_count = error_count + 1;
        end

        // Examine the framebuffer directly. The top-left rule should produce
        // exactly 10 TEST_COLOR pixels within this region.
        colored_pixel_count = 0;

        for (y = 0; y <= 8; y = y + 1) begin
            for (x = 0; x <= 8; x = x + 1) begin
                address = (y * FRAME_WIDTH) + x;

                if (dut.rasterizer_top_instance.frame_buffer_instance
                        .memory[address] === TEST_COLOR)
                    colored_pixel_count = colored_pixel_count + 1;
            end
        end

        if (colored_pixel_count != 10) begin
            $error("Expected 10 framebuffer pixels, found %0d",
                   colored_pixel_count);
            error_count = error_count + 1;
        end

        if (dut.rasterizer_top_instance.frame_buffer_instance
                .memory[(2 * FRAME_WIDTH) + 2] !== TEST_COLOR) begin
            $error("Expected interior pixel (2,2) to be colored");
            error_count = error_count + 1;
        end

        if (dut.rasterizer_top_instance.frame_buffer_instance
                .memory[(3 * FRAME_WIDTH) + 3] !== TEST_COLOR) begin
            $error("Expected interior pixel (3,3) to be colored");
            error_count = error_count + 1;
        end

        if (dut.rasterizer_top_instance.frame_buffer_instance
                .memory[(2 * FRAME_WIDTH) + 6] === TEST_COLOR) begin
            $error("Top-left rule failed at diagonal-edge pixel (6,2)");
            error_count = error_count + 1;
        end

        if (error_count == 0)
            $display("PASS: top completed CPU-to-rasterizer integration test");
        else
            $fatal(1, "FAIL: top reported %0d errors", error_count);

        $finish;
    end

endmodule
