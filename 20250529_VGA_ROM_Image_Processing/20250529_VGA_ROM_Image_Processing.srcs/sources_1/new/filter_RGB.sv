`timescale 1ns / 1ps


module filter_RGB(
    input  logic [3:0] in_red,
    input  logic [3:0] in_green,
    input  logic [3:0] in_blue,
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue
    );

    assign red = in_red & ~sw_red;
    assign green = in_green & ~sw_green;
    assign blue = in_blue & ~sw_blue;
endmodule
