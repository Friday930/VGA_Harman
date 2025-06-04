`timescale 1ns / 1ps

// module QVGA_MemController (
//     // VGA Controller side
//     input  logic        clk,
//     input  logic [ 9:0] x_pixel,
//     input  logic [ 9:0] y_pixel,
//     input  logic        DE, // n/c
//     // frame buffer side
//     output logic        rclk,
//     output logic        d_en,
//     output logic [16:0] rAddr,
//     input  logic [15:0] rData,
//     // export side
//     output logic [ 3:0] red_port,
//     output logic [ 3:0] green_port,
//     output logic [ 3:0] blue_port
// );

//     logic display_en;

//     assign rclk = clk;
//     assign display_en = (x_pixel < 320) && (y_pixel < 240);
//     assign d_en = display_en;

//     assign rAddr = display_en ? (y_pixel * 320 + x_pixel) : 0;
//     assign {red_port, green_port, blue_port} = display_en ? {rData[15:12], rData[10:7], rData[4:1]} : 12'b0;
// endmodule


// 수정된 QVGA 컨트롤러 (1비트 출력 지원)
module QVGA_MemController_1bit (
    // VGA Controller side
    input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    // frame buffer side
    output logic        rclk,
    output logic        d_en,
    output logic [16:0] rAddr,
    input  logic [15:0] rData,
    // threshold for 1-bit conversion
    input  logic [ 4:0] threshold,
    // 1-bit output
    output logic        pixel_1bit,
    output logic        de_out
);

    logic display_en;
    logic [5:0] luminance;

    assign rclk = clk;
    assign display_en = (x_pixel < 320) && (y_pixel < 240);
    assign d_en = display_en;
    assign de_out = display_en;

    assign rAddr = display_en ? (y_pixel * 320 + x_pixel) : 0;
    
    // 휘도 계산 (간단한 평균)
    always_comb begin
        if (display_en) begin
            luminance = (rData[15:12] + rData[10:7] + rData[4:1]) / 3;
            pixel_1bit = (luminance > threshold) ? 1'b1 : 1'b0;
        end else begin
            pixel_1bit = 1'b0;
        end
    end

endmodule