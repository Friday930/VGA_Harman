`timescale 1ns / 1ps

module VGA_SMPTE (
    input  wire                   DE,
    input  wire [$clog2(639)-1:0] x_pol,
    input  wire [$clog2(479)-1:0] y_pol,
    output wire [            3:0] red,
    output wire [            3:0] green,
    output wire [            3:0] blue
);

    localparam Y_UPPER = 320, Y_MIDDLE = 360, Y_LOWER = 480;

    reg [11:0] color;
    assign {red, green, blue} = color;

    wire [$clog2(8)-1:0] color_hnum;
    wire [$clog2(8)-1:0] color_hnum2;
    assign color_hnum  = x_pol / 92;
    assign color_hnum2 = x_pol / 108;

    always @(*) begin
        color = 12'bz;
        if (DE) begin
            if (y_pol < Y_UPPER - 1) begin
                case (color_hnum)
                    3'd0: color = 12'b0110_0110_0110;
                    3'd1: color = 12'b1011_1011_0001;
                    3'd2: color = 12'b0001_1011_1011;
                    3'd3: color = 12'b0001_1011_0001;
                    3'd4: color = 12'b1011_0001_1011;
                    3'd5: color = 12'b1011_0001_0001;
                    3'd6: color = 12'b0001_0001_1011;
                endcase
            end else if (y_pol < Y_MIDDLE - 1) begin
                case (color_hnum)
                    3'd0: color = 12'b0001_0001_1011;
                    3'd1: color = 12'b0000_0000_0000;
                    3'd2: color = 12'b1011_0001_1011;
                    3'd3: color = 12'b0000_0000_0000;
                    3'd4: color = 12'b0001_1011_1011;
                    3'd5: color = 12'b0000_0000_0000;
                    3'd6: color = 12'b0110_0110_0110;
                endcase
            end else begin
                case (color_hnum2)
                    3'd0: color = 12'b0100_0001_0111;
                    3'd1: color = 12'b1111_1111_1111;
                    3'd2: color = 12'b0010_0000_0100;
                    3'd3: color = 12'b0000_0000_0000;
                    3'd4: color = 12'b1111_1111_0000;
                    3'd5: color = 12'b0000_1111_1111;
                endcase
            end
        end
    end

endmodule
