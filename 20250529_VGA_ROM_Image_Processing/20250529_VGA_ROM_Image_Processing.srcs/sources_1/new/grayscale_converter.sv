`timescale 1ns / 1ps

module grayscale_converter (
    input  logic [3:0] in_red,
    input  logic [3:0] in_green,
    input  logic [3:0] in_blue,
    output logic [3:0] gray_red,
    output logic [3:0] gray_green,
    output logic [3:0] gray_blue
);

    logic [11:0] gray = 77 * in_red + 150 * in_green + 29 * in_blue;

    assign gray_red   = gray[11:8];
    assign gray_green = gray[11:8];
    assign gray_blue  = gray[11:8];

endmodule
