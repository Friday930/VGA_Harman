`timescale 1ns / 1ps

module OV7670_VGA_Display (
//     // global signals
//     input  logic       clk,
//     input  logic       reset,
//     // ov7670 signals
//     output logic       ov7670_xclk,    // == mclk
//     input  logic       ov7670_pclk,
//     input  logic       ov7670_href,
//     input  logic       ov7670_v_sync,
//     input  logic [7:0] ov7670_data,
//     // export signals
//     output logic       Hsync,
//     output logic       Vsync,
//     output logic [3:0] vgaRed,
//     output logic [3:0] vgaGreen,
//     output logic [3:0] vgaBlue
// );

//     logic        we;
//     logic [16:0] wAddr;
//     logic [15:0] wData;
//     logic [16:0] rAddr;
//     logic [15:0] rData;

//     logic [ 9:0] x_pixel;
//     logic [ 9:0] y_pixel;
//     logic        DE;
//     logic        w_rclk;
//     logic        rclk;
//     logic        oe;

//     pixel_clk_gen U_OV7670_Clk_Gen (
//         .clk  (clk),
//         .reset(reset),
//         .pclk (ov7670_xclk)
//     );

//     VGA_Controller U_VGAController (
//         .clk    (clk),
//         .reset  (reset),
//         .rclk   (w_rclk),
//         .h_sync (Hsync),
//         .v_sync (Vsync),
//         .DE     (DE),
//         .x_pixel(x_pixel),
//         .y_pixel(y_pixel)
//     );

//     OV7670_MemController U_OV7670_MemController (
//         .pclk       (ov7670_pclk),
//         .reset      (reset),
//         .href       (ov7670_href),
//         .v_sync     (ov7670_v_sync),
//         .ov7670_data(ov7670_data),
//         .we         (we),
//         .wAddr      (wAddr),
//         .wData      (wData)
//     );

//     frame_buffer U_Frame_Buffer (
//         .wclk (ov7670_pclk),
//         .we   (we),
//         .wAddr(wAddr),
//         .wData(wData),
//         .rclk (rclk),
//         .oe   (oe),
//         .rAddr(rAddr),
//         .rData(rData)
//     );


//     QVGA_MemController U_QVGA_MemController (
//         .clk       (w_rclk),
//         .x_pixel   (x_pixel),
//         .y_pixel   (y_pixel),
//         .DE        (DE),
//         .rclk      (rclk),
//         .d_en      (oe),
//         .rAddr     (rAddr),
//         .rData     (rData),
//         .red_port  (vgaRed),
//         .green_port(vgaGreen),
//         .blue_port (vgaBlue)
//     );


// endmodule

    // global signals
    input  logic       clk,
    input  logic       reset,
    // ov7670 signals
    output logic       ov7670_xclk,    // == mclk
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    // export signals
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    // 추가 제어 신호
    input  logic       aa_en,          // 안티앨리어싱 활성화
    input  logic [1:0] color_sel,      // 색상 선택
    input  logic [4:0] threshold       // 1비트 변환 임계값
);

    // 기존 신호들
    logic        we;
    logic [16:0] wAddr;
    logic [15:0] wData;
    logic [16:0] rAddr;
    logic [15:0] rData;
    logic [ 9:0] x_pixel;
    logic [ 9:0] y_pixel;
    logic        DE;
    logic        w_rclk;
    logic        rclk;
    logic        oe;
    
    // 새로운 신호들 (업스케일/AA용)
    logic        pixel_1bit;
    logic        de_internal;
    logic        h_sync_internal;
    logic        v_sync_internal;
    logic [3:0]  red_upscaled;
    logic [3:0]  green_upscaled;
    logic [3:0]  blue_upscaled;
    logic        de_upscaled;
    logic        h_sync_upscaled;
    logic        v_sync_upscaled;

    // 기존 모듈들 인스턴스화
    pixel_clk_gen U_OV7670_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

    VGA_Controller U_VGAController (
        .clk    (clk),
        .reset  (reset),
        .rclk   (w_rclk),
        .h_sync (h_sync_internal),
        .v_sync (v_sync_internal),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    OV7670_MemController U_OV7670_MemController (
        .pclk       (ov7670_pclk),
        .reset      (reset),
        .href       (ov7670_href),
        .v_sync     (ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    frame_buffer U_Frame_Buffer (
        .wclk (ov7670_pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (rclk),
        .oe   (oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    // 수정된 QVGA 컨트롤러 (1비트 출력 추가)
    QVGA_MemController_1bit U_QVGA_MemController (
        .clk       (w_rclk),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .DE        (DE),
        .rclk      (rclk),
        .d_en      (oe),
        .rAddr     (rAddr),
        .rData     (rData),
        .threshold (threshold),
        // 1비트 출력
        .pixel_1bit(pixel_1bit),
        .de_out    (de_internal)
    );

    // 업스케일 모듈 (1비트 → 4비트 RGB)
    upscale U_Upscale (
        .clk         (clk),
        .rst_n       (~reset),
        .pixel_1bit_i(pixel_1bit),
        .de_i        (de_internal),
        .h_sync_i    (h_sync_internal),
        .v_sync_i    (v_sync_internal),
        .pixel_r_o   (red_upscaled),
        .pixel_g_o   (green_upscaled),
        .pixel_b_o   (blue_upscaled),
        .de_o        (de_upscaled),
        .h_sync_o    (h_sync_upscaled),
        .v_sync_o    (v_sync_upscaled),
        .color_sel   (color_sel)
    );

    // 안티앨리어싱 모듈
    antialiasing_filter #(
        .H_ACTIVE(320),
        .V_ACTIVE(240)
    ) U_AA_Filter (
        .clk        (clk),
        .rst_n      (~reset),
        .h_sync_i   (h_sync_upscaled),
        .v_sync_i   (v_sync_upscaled),
        .de_i       (de_upscaled),
        .pixel_r_i  (red_upscaled),
        .pixel_g_i  (green_upscaled),
        .pixel_b_i  (blue_upscaled),
        .h_sync_o   (Hsync),
        .v_sync_o   (Vsync),
        .de_o       (),  // 사용하지 않음
        .pixel_r_o  (vgaRed),
        .pixel_g_o  (vgaGreen),
        .pixel_b_o  (vgaBlue),
        .aa_en      (aa_en)
    );

endmodule
