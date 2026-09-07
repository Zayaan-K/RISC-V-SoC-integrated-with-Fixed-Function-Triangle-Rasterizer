`timescale 1ns / 1ps

module rasterizer_registers #(
    parameter integer COORD_WIDTH = 16,
    parameter integer COLOR_WIDTH = 12,
    parameter integer ADDR_WIDTH  = 6
)(
    input  wire                      clk,
    input  wire                      reset,

    // CPU/MMIO interface
    input  wire                      write_enable,
    input  wire                      read_enable,
    input  wire [ADDR_WIDTH-1:0]     address,
    input  wire [31:0]               write_data,
    output reg  [31:0]               read_data,

    // Status from graphics pipeline
    input  wire                      rasterizer_busy,
    input  wire                      rasterizer_done,

    // Triangle data sent to triangle_setup
    output reg signed [COORD_WIDTH-1:0] x0,
    output reg signed [COORD_WIDTH-1:0] y0,
    output reg signed [COORD_WIDTH-1:0] x1,
    output reg signed [COORD_WIDTH-1:0] y1,
    output reg signed [COORD_WIDTH-1:0] x2,
    output reg signed [COORD_WIDTH-1:0] y2,
    output reg        [COLOR_WIDTH-1:0] triangle_color,


    output reg                       start
);

    /*//===============================================
     * Byte-addressed register map:
     *
     * 0x00 : Control
     *        bit 0 = write 1 to start
     *        bit 1 = write 1 to clear done status
     *
     * 0x04 : Status
     *        bit 0 = busy
     *        bit 1 = done
     *
     * 0x08 : x0
     * 0x0C : y0
     * 0x10 : x1
     * 0x14 : y1
     * 0x18 : x2
     * 0x1C : y2
     * 0x20 : triangle color
     *///======================================================

    localparam [ADDR_WIDTH-1:0] ADDR_CONTROL = 6'h00;
    localparam [ADDR_WIDTH-1:0] ADDR_STATUS  = 6'h04;
    localparam [ADDR_WIDTH-1:0] ADDR_X0      = 6'h08;
    localparam [ADDR_WIDTH-1:0] ADDR_Y0      = 6'h0C;
    localparam [ADDR_WIDTH-1:0] ADDR_X1      = 6'h10;
    localparam [ADDR_WIDTH-1:0] ADDR_Y1      = 6'h14;
    localparam [ADDR_WIDTH-1:0] ADDR_X2      = 6'h18;
    localparam [ADDR_WIDTH-1:0] ADDR_Y2      = 6'h1C;
    localparam [ADDR_WIDTH-1:0] ADDR_COLOR   = 6'h20;

    reg done_status;

    always @(posedge clk) begin
        if (reset) begin
            x0             <= '0;
            y0             <= '0;
            x1             <= '0;
            y1             <= '0;
            x2             <= '0;
            y2             <= '0;
            triangle_color <= '0;
            start          <= 1'b0;
            done_status    <= 1'b0;
        end else begin

            start <= 1'b0;

            if (rasterizer_done)
                done_status <= 1'b1;

            if (write_enable) begin
                case (address)
                    ADDR_CONTROL: begin
                        if (write_data[0] && !rasterizer_busy) begin
                            start       <= 1'b1;
                            done_status <= 1'b0;
                        end

                        if (write_data[1])
                            done_status <= 1'b0;
                    end

                    ADDR_X0:
                        x0 <= write_data[COORD_WIDTH-1:0];

                    ADDR_Y0:
                        y0 <= write_data[COORD_WIDTH-1:0];

                    ADDR_X1:
                        x1 <= write_data[COORD_WIDTH-1:0];

                    ADDR_Y1:
                        y1 <= write_data[COORD_WIDTH-1:0];

                    ADDR_X2:
                        x2 <= write_data[COORD_WIDTH-1:0];

                    ADDR_Y2:
                        y2 <= write_data[COORD_WIDTH-1:0];

                    ADDR_COLOR:
                        triangle_color <= write_data[COLOR_WIDTH-1:0];

                    default: begin
                        // No register at this address.
                    end
                endcase
            end
        end
    end

    always @(*) begin
        read_data = 32'b0;

        if (read_enable) begin
            case (address)
                ADDR_CONTROL:
                    read_data = 32'b0;

                ADDR_STATUS: begin
                    read_data[0] = rasterizer_busy;
                    read_data[1] = done_status;
                end

                ADDR_X0:
                    read_data = {{(32-COORD_WIDTH){x0[COORD_WIDTH-1]}}, x0};

                ADDR_Y0:
                    read_data = {{(32-COORD_WIDTH){y0[COORD_WIDTH-1]}}, y0};

                ADDR_X1:
                    read_data = {{(32-COORD_WIDTH){x1[COORD_WIDTH-1]}}, x1};

                ADDR_Y1:
                    read_data = {{(32-COORD_WIDTH){y1[COORD_WIDTH-1]}}, y1};

                ADDR_X2:
                    read_data = {{(32-COORD_WIDTH){x2[COORD_WIDTH-1]}}, x2};

                ADDR_Y2:
                    read_data = {{(32-COORD_WIDTH){y2[COORD_WIDTH-1]}}, y2};

                ADDR_COLOR:
                    read_data = {{(32-COLOR_WIDTH){1'b0}}, triangle_color};

                default:
                    read_data = 32'b0;
            endcase
        end
    end

endmodule
