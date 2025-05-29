`timescale 1ns / 1ps

module ImageVGA (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    input  logic       sw_mode,
    output logic       h_sync,
    output logic       v_sync,
    output       [3:0] o_red,
    output       [3:0] o_green,
    output       [3:0] o_blue
);

    logic                   DE;
    logic [$clog2(640)-1:0] x_pixel;
    logic [$clog2(640)-1:0] y_pixel;

    logic [3:0] in_red, in_green, in_blue;
    logic [3:0] red, green, blue;
    logic [3:0] gray_red, gray_green, gray_blue;


    VGA_Controller U_VGA_controller (.*);
    ImageRom U_ImageRom (
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .DE        (DE),
        .red_port  (in_red),
        .green_port(in_green),
        .blue_port (in_blue)
    );

    filter_RGB U_RGB_Filter (
        .in_red  (in_red),
        .in_green(in_green),
        .in_blue (in_blue),
        .sw_red  (sw_red),
        .sw_green(sw_green),
        .sw_blue (sw_blue),
        .red     (red),
        .green   (green),
        .blue    (blue)
    );

    grayscale_converter u_grayscale_converter (
        .in_red    (in_red),
        .in_green  (in_green),
        .in_blue   (in_blue),
        .gray_red  (gray_red),
        .gray_green(gray_green),
        .gray_blue (gray_blue)
    );


    MUX2x1 U_MUX2x1 (
        .x1 ({red, green, blue}),
        .x2 ({gray_red, gray_green, gray_blue}),
        .y  ({o_red, o_green, o_blue}),
        .sel(sw_mode)
    );


endmodule

module MUX2x1 (
    input  logic [11:0] x1,
    input  logic [11:0] x2,
    input  logic        sel,
    output logic [11:0] y
);

    always_comb begin
        case (sel)
            0: y = x1;
            1: y = x2;
        endcase
    end

endmodule
