`timescale 1ns / 1ps

module grayscale_converter (
    input  logic [3:0] in_red,
    input  logic [3:0] in_green,
    input  logic [3:0] in_blue,
    output logic [3:0] gray1,
    output logic [3:0] gray2,
    output logic [3:0] gray3
);

    assign gray1 = 77 * in_red;
    assign gray2 = 150 * in_green;
    assign gray3 = 29 * in_blue;

endmodule
