`timescale 1ns / 1ps

module VGA_Controller (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] sw_red,
    input  wire [3:0] sw_green,
    input  wire [3:0] sw_blue,
    input  wire       sw_mode,
    output wire       h_sync,
    output wire       v_sync,
    output wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue
);

    wire                   DE;
    wire [$clog2(639)-1:0] x_pol;
    wire [$clog2(479)-1:0] y_pol;

    VGA_Decoder U_VGA_Decoder (
        .clk   (clk),
        .reset (reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE    (DE),
        .x_pol (x_pol),
        .y_pol (y_pol)
    );

    VGA_Display U_VGA_Display (
        .sw_red  (sw_red),
        .sw_green(sw_green),
        .sw_blue (sw_blue),
        .sw_mode (sw_mode),
        .DE      (DE),
        .x_pol   (x_pol),
        .y_pol   (y_pol),
        .red     (red),
        .green   (green),
        .blue    (blue)
    );


endmodule


