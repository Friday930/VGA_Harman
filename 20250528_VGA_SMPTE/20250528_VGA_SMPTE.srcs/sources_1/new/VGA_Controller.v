`timescale 1ns / 1ps

module VGA_Controller (
    input  wire       clk,
    input  wire       reset,
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

    VGA_SMPTE U_VGA_SMPTE (
        .DE   (DE),
        .x_pol(x_pol),
        .y_pol(y_pol),
        .red  (red),
        .green(green),
        .blue (blue)
    );

endmodule


