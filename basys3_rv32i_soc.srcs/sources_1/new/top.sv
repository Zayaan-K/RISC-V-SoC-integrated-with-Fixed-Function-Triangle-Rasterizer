`timescale 1ns / 1ps

module top #(
    parameter integer INSTRUCTION_WORDS = 1024,
    parameter integer DATA_WORDS        = 1024,
    parameter         INSTRUCTION_INIT_FILE = "triangle_demo.mem",

    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,
    parameter integer COLOR_WIDTH  = 12,
    parameter integer FRAMEBUFFER_ADDR_WIDTH =
        $clog2(FRAME_WIDTH * FRAME_HEIGHT),

    parameter [31:0] RASTERIZER_BASE_ADDRESS = 32'h4000_0000
)(
    input wire clk,
    input wire reset,

    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire       Hsync,
    output wire       Vsync,

    output wire illegal_instruction,
    output wire instruction_address_misaligned,
    output wire data_address_misaligned,
    output wire halted,
    output wire rasterizer_busy,
    output wire rasterizer_done
);

    // ================================================================
    // CPU instruction interface
    // ================================================================

    wire [31:0] instruction_address;
    wire [31:0] instruction;

    // ================================================================
    // CPU data interface
    // ================================================================

    wire [31:0] cpu_data_address;
    wire [31:0] cpu_data_write_data;
    wire [3:0]  cpu_data_byte_enable;
    wire        cpu_data_write_enable;
    reg  [31:0] cpu_data_read_data;

    // ================================================================
    // Data-memory interface
    // ================================================================

    wire        data_memory_write_enable;
    wire [31:0] data_memory_read_data;

    // ================================================================
    // Rasterizer MMIO interface
    // ================================================================

    wire        rasterizer_selected;
    wire        rasterizer_write_enable;
    wire        rasterizer_read_enable;
    wire [31:0] rasterizer_read_data;

    /*
     * Rasterizer register range:
     *
     * 0x4000_0000 : control
     * 0x4000_0004 : status
     * 0x4000_0008 : x0
     * 0x4000_000C : y0
     * 0x4000_0010 : x1
     * 0x4000_0014 : y1
     * 0x4000_0018 : x2
     * 0x4000_001C : y2
     * 0x4000_0020 : triangle color
     */

    assign rasterizer_selected =
        (cpu_data_address[31:6] == RASTERIZER_BASE_ADDRESS[31:6]);

    // Rasterizer registers are accessed using aligned 32-bit stores.
    assign rasterizer_write_enable =
        cpu_data_write_enable &&
        rasterizer_selected &&
        (&cpu_data_byte_enable);

    assign rasterizer_read_enable = rasterizer_selected;

    assign data_memory_write_enable =
        cpu_data_write_enable && !rasterizer_selected;

    always @(*) begin
        if (rasterizer_selected)
            cpu_data_read_data = rasterizer_read_data;
        else
            cpu_data_read_data = data_memory_read_data;
    end

    // ================================================================
    // VGA timing and framebuffer-read interface
    // ================================================================

    wire       timing_hsync;
    wire       timing_vsync;
    wire [9:0] vga_x;
    wire [9:0] vga_y;
    wire       timing_active_video;
    wire       frame_tick;
    wire       pixel_tick;

    wire [FRAMEBUFFER_ADDR_WIDTH-1:0] framebuffer_read_address;
    wire [COLOR_WIDTH-1:0]            framebuffer_read_color;
    wire [COLOR_WIDTH-1:0]            display_color;
    wire                              display_active_video;
    wire                              display_hsync;
    wire                              display_vsync;

    // ================================================================
    // RV32I processor
    // ================================================================

    risc_core risc_core_instance (
        .clk                            (clk),
        .reset                          (reset),
        .instruction_address            (instruction_address),
        .instruction                    (instruction),
        .data_address                   (cpu_data_address),
        .data_write_data                (cpu_data_write_data),
        .data_byte_enable               (cpu_data_byte_enable),
        .data_write_enable              (cpu_data_write_enable),
        .data_read_data                 (cpu_data_read_data),
        .illegal_instruction            (illegal_instruction),
        .instruction_address_misaligned (instruction_address_misaligned),
        .data_address_misaligned        (data_address_misaligned),
        .halted                         (halted)
    );

    // ================================================================
    // Instruction and data memories
    // ================================================================

    instruction_memory #(
        .MEMORY_WORDS (INSTRUCTION_WORDS),
        .INIT_FILE    (INSTRUCTION_INIT_FILE)
    ) instruction_memory_instance (
        .address     (instruction_address),
        .instruction (instruction)
    );

    data_memory #(
        .MEMORY_WORDS (DATA_WORDS)
    ) data_memory_instance (
        .clk          (clk),
        .write_enable (data_memory_write_enable),
        .byte_enable  (cpu_data_byte_enable),
        .address      (cpu_data_address),
        .write_data   (cpu_data_write_data),
        .read_data    (data_memory_read_data)
    );

    // ================================================================
    // Rasterizer and framebuffer
    // ================================================================

    rasterizer_top #(
        .FRAME_WIDTH             (FRAME_WIDTH),
        .FRAME_HEIGHT            (FRAME_HEIGHT),
        .COLOR_WIDTH             (COLOR_WIDTH),
        .FRAMEBUFFER_ADDR_WIDTH  (FRAMEBUFFER_ADDR_WIDTH)
    ) rasterizer_top_instance (
        .clk                      (clk),
        .reset                    (reset),
        .mmio_write_enable        (rasterizer_write_enable),
        .mmio_read_enable         (rasterizer_read_enable),
        .mmio_address             (cpu_data_address[5:0]),
        .mmio_write_data          (cpu_data_write_data),
        .mmio_read_data           (rasterizer_read_data),
        .framebuffer_read_address (framebuffer_read_address),
        .framebuffer_read_color   (framebuffer_read_color),
        .busy                     (rasterizer_busy),
        .done                     (rasterizer_done)
    );

    // ================================================================
    // Reused 640x480 VGA timing controller
    // ================================================================

    VGA_Driver vga_driver_instance (
        .clk         (clk),
        .reset       (reset),
        .Hsync       (timing_hsync),
        .Vsync       (timing_vsync),
        .xCoordinate (vga_x),
        .yCoordinate (vga_y),
        .activeVideo (timing_active_video),
        .frameTick   (frame_tick),
        .pixelTick   (pixel_tick)
    );

    // ================================================================
    // 320x240 framebuffer to 640x480 VGA scanout
    // ================================================================

    framebuffer_reader #(
        .FRAME_WIDTH   (FRAME_WIDTH),
        .FRAME_HEIGHT  (FRAME_HEIGHT),
        .COLOR_WIDTH   (COLOR_WIDTH),
        .VGA_WIDTH     (640),
        .VGA_HEIGHT    (480),
        .VGA_X_WIDTH   (10),
        .VGA_Y_WIDTH   (10),
        .ADDRESS_WIDTH (FRAMEBUFFER_ADDR_WIDTH)
    ) framebuffer_reader_instance (
        .clk                      (clk),
        .reset                    (reset),
        .vga_x                    (vga_x),
        .vga_y                    (vga_y),
        .vga_active_video         (timing_active_video),
        .vga_hsync                (timing_hsync),
        .vga_vsync                (timing_vsync),
        .framebuffer_read_address (framebuffer_read_address),
        .framebuffer_read_color   (framebuffer_read_color),
        .display_color            (display_color),
        .display_active_video     (display_active_video),
        .display_hsync            (display_hsync),
        .display_vsync            (display_vsync)
    );

    assign vgaRed   = display_active_video ? display_color[11:8] : 4'b0000;
    assign vgaGreen = display_active_video ? display_color[7:4]  : 4'b0000;
    assign vgaBlue  = display_active_video ? display_color[3:0]  : 4'b0000;

    assign Hsync = display_hsync;
    assign Vsync = display_vsync;

endmodule
