//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: VGA_Driver
// Project Name: rv32i_soc
// Target Devices: Basys3
// Description: COntrols Pulses for VGA
// 
//////////////////////////////////////////////////////////////////////////////////

module VGA_Driver(

    input  wire clk,       
    input  wire reset,

    output wire Hsync,
    output wire Vsync,
    
    output wire [9:0] xCoordinate,
    output wire [9:0] yCoordinate,

    output wire activeVideo,
    output wire frameTick,
    output wire pixelTick
);

    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;

    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    reg [1:0] pixelDivider = 0;

    assign pixelTick = (pixelDivider == 2'b11);

    reg [9:0] hCount = 0;
    reg [9:0] vCount = 0;

    assign activeVideo = (hCount < H_ACTIVE) && (vCount < V_ACTIVE);

    assign xCoordinate = hCount;
    assign yCoordinate = vCount;

    assign frameTick = pixelTick &&
                       (hCount == H_TOTAL - 1) &&
                       (vCount == V_TOTAL - 1);

    always @(posedge clk) begin
        if (reset)
            pixelDivider <= 0;
        else
            pixelDivider <= pixelDivider + 1;
    end

    always @(posedge clk) begin
        if (reset) begin
            hCount <= 0;
            vCount <= 0;
        end else if (pixelTick) begin
            if (hCount == H_TOTAL - 1) begin
                hCount <= 0;

                if (vCount == V_TOTAL - 1)
                    vCount <= 0;
                else
                    vCount <= vCount + 1;

            end else begin
                hCount <= hCount + 1;
            end
        end
    end

    assign Hsync = ~((hCount >= H_ACTIVE + H_FRONT) &&
                     (hCount <  H_ACTIVE + H_FRONT + H_SYNC));

    assign Vsync = ~((vCount >= V_ACTIVE + V_FRONT) &&
                     (vCount <  V_ACTIVE + V_FRONT + V_SYNC));
        
                      
endmodule

