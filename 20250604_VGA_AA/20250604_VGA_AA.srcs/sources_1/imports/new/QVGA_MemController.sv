`timescale 1ns / 1ps

module QVGA_MemController (
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
    // export side
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port,
    // 업스케일 모드
    input  logic        upscale_mode
);

    logic display_en;
    logic [8:0] scaled_x, scaled_y;

    assign rclk = clk;
    
    // 업스케일 모드에 따른 좌표 계산
    always_comb begin
        if (upscale_mode) begin
            // 640x480을 320x240으로 다운샘플링해서 읽기
            scaled_x = x_pixel[9:1];  // x/2
            scaled_y = y_pixel[9:1];  // y/2
            display_en = (scaled_x < 320) && (scaled_y < 240);
        end else begin
            // 원본 320x240 영역만 표시
            scaled_x = x_pixel[8:0];
            scaled_y = y_pixel[8:0];
            display_en = (x_pixel < 320) && (y_pixel < 240);
        end
    end
    
    assign d_en = display_en;
    assign rAddr = display_en ? (scaled_y * 320 + scaled_x) : 0;
    assign {red_port, green_port, blue_port} = display_en ? 
           {rData[15:12], rData[10:7], rData[4:1]} : 12'b0;

endmodule
