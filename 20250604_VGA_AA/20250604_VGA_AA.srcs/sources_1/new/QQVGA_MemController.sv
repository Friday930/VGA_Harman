`timescale 1ns / 1ps

module QQVGA_MemController (
    // VGA Controller side
    input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    // frame buffer side
    output logic        rclk,
    output logic        d_en,
    output logic [$clog2(19200)-1:0] rAddr,  // 160*120 = 19200
    input  logic [15:0] rData,
    // export side
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port,
    // 업스케일 모드
    input  logic        upscale_mode
);

    logic display_en;
    logic [7:0] scaled_x, scaled_y;  // 160, 120에 맞춰 8비트, 7비트

    assign rclk = clk;
    
    // 업스케일 모드에 따른 좌표 계산
    always_comb begin
        if (upscale_mode) begin
            // 640x480을 160x120으로 다운샘플링해서 읽기
            scaled_x = x_pixel[9:2];  // x/4
            scaled_y = y_pixel[9:2];  // y/4
            display_en = (scaled_x < 160) && (scaled_y < 120);
        end else begin
            // 원본 160x120 영역만 표시 (좌상단)
            scaled_x = x_pixel[7:0];
            scaled_y = y_pixel[6:0];
            display_en = (x_pixel < 160) && (y_pixel < 120);
        end
    end
    
    assign d_en = display_en;
    assign rAddr = display_en ? (scaled_y * 160 + scaled_x) : 0;
    assign {red_port, green_port, blue_port} = display_en ? 
           {rData[15:12], rData[10:7], rData[4:1]} : 12'b0;

endmodule
