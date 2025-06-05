// `timescale 1ns / 1ps

// module OV7670_VGA_Display_with_AA (
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
//     output logic [3:0] vgaBlue,
//     // 추가 제어 신호
//     input  logic       aa_en          // 안티앨리어싱 활성화
// );

//     // 기존 모듈 출력 신호
//     logic       Hsync_orig;
//     logic       Vsync_orig;
//     logic [3:0] vgaRed_orig;
//     logic [3:0] vgaGreen_orig;
//     logic [3:0] vgaBlue_orig;
    
//     // 중간 신호
//     logic       pixel_1bit;
//     logic [3:0] red_upscaled;
//     logic [3:0] green_upscaled;
//     logic [3:0] blue_upscaled;
//     logic       de_upscaled;
//     logic       h_sync_upscaled;
//     logic       v_sync_upscaled;

//     // 기존 OV7670_VGA_Display 모듈 인스턴스
//     OV7670_VGA_Display U_Original_Display (
//         .clk         (clk),
//         .reset       (reset),
//         .ov7670_xclk (ov7670_xclk),
//         .ov7670_pclk (ov7670_pclk),
//         .ov7670_href (ov7670_href),
//         .ov7670_v_sync(ov7670_v_sync),
//         .ov7670_data (ov7670_data),
//         .Hsync       (Hsync_orig),
//         .Vsync       (Vsync_orig),
//         .vgaRed      (vgaRed_orig),
//         .vgaGreen    (vgaGreen_orig),
//         .vgaBlue     (vgaBlue_orig)
//     );
    
//     // RGB를 1비트로 변환 (휘도 기반)
//     logic [5:0] luminance;
//     logic de_signal;
//     logic [9:0] x_pixel_internal;
//     logic [9:0] y_pixel_internal;
//     logic DE_internal;
//     logic pclk;
    
//     // VGA 컨트롤러에서 내부 신호 가져오기
//     assign pclk = U_Original_Display.U_VGAController.pclk;
//     assign x_pixel_internal = U_Original_Display.U_VGAController.x_pixel;
//     assign y_pixel_internal = U_Original_Display.U_VGAController.y_pixel;
//     assign DE_internal = U_Original_Display.U_VGAController.DE;
    
//     // 320x240 영역만 DE 활성화
//     assign de_signal = (x_pixel_internal < 320) && (y_pixel_internal < 240) && DE_internal;
    
//     always_comb begin
//         // 간단한 휘도 계산
//         luminance = (vgaRed_orig + vgaGreen_orig + vgaBlue_orig) / 3;
//         pixel_1bit = (luminance > 6'd7) ? 1'b1 : 1'b0;
//     end
    
//     // 업스케일 모듈
//     upscale U_Upscale (
//         .clk         (clk),
//         .rst_n       (~reset),
//         .pixel_1bit_i(pixel_1bit),
//         .de_i        (de_signal),
//         .h_sync_i    (Hsync_orig),
//         .v_sync_i    (Vsync_orig),
//         .pixel_r_o   (red_upscaled),
//         .pixel_g_o   (green_upscaled),
//         .pixel_b_o   (blue_upscaled),
//         .de_o        (de_upscaled),
//         .h_sync_o    (h_sync_upscaled),
//         .v_sync_o    (v_sync_upscaled)
//     );
    
//     // 안티앨리어싱 모듈
//     antialiasing_filter #(
//         .H_ACTIVE(320),
//         .V_ACTIVE(240)
//     ) U_AA_Filter (
//         .clk        (clk),
//         .rst_n      (~reset),
//         .h_sync_i   (h_sync_upscaled),
//         .v_sync_i   (v_sync_upscaled),
//         .de_i       (de_upscaled),
//         .pixel_r_i  (red_upscaled),
//         .pixel_g_i  (green_upscaled),
//         .pixel_b_i  (blue_upscaled),
//         .h_sync_o   (Hsync),
//         .v_sync_o   (Vsync),
//         .de_o       (),
//         .pixel_r_o  (vgaRed),
//         .pixel_g_o  (vgaGreen),
//         .pixel_b_o  (vgaBlue),
//         .aa_en      (aa_en)
//     );

// endmodule

`timescale 1ns / 1ps

module OV7670_VGA_Display_with_AA (
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
    // input  logic       aa_en,          // 안티앨리어싱 활성화
    input  logic       initial_start,
    output logic       sioc,
    inout  logic       siod,
    // 디버그용
    input  logic [1:0] mode_sel        // 00: 원본, 01: 1비트, 10: 업스케일, 11: AA
);

    // 내부 신호들
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
    
    // 중간 처리 신호
    logic [3:0]  red_orig, green_orig, blue_orig;
    logic        h_sync_orig, v_sync_orig;
    logic        pixel_1bit;
    logic [3:0]  red_up, green_up, blue_up;
    logic        de_up, h_sync_up, v_sync_up;
    // logic [3:0]  red_aa, green_aa, blue_aa;
    // logic        h_sync_aa, v_sync_aa;

    // 픽셀 클럭 생성
    pixel_clk_gen U_OV7670_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

    // VGA 컨트롤러
    VGA_Controller U_VGAController (
        .clk    (clk),
        .reset  (reset),
        .rclk   (w_rclk),
        .h_sync (h_sync_orig),
        .v_sync (v_sync_orig),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    // 카메라 메모리 컨트롤러
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

    // 프레임 버퍼
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

    // QVGA 메모리 컨트롤러
    // QVGA_MemController U_QVGA_MemController (
    //     .clk       (w_rclk),
    //     .x_pixel   (x_pixel),
    //     .y_pixel   (y_pixel),
    //     .DE        (DE),
    //     .rclk      (rclk),
    //     .d_en      (oe),
    //     .rAddr     (rAddr),
    //     .rData     (rData),
    //     .red_port  (red_orig),
    //     .green_port(green_orig),
    //     .blue_port (blue_orig)
    // );

    QVGA_MemController U_QVGA_MemController (
        .clk       (w_rclk),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .DE        (DE),
        .rclk      (rclk),
        .d_en      (oe),
        .rAddr     (rAddr),
        .rData     (rData),
        .red_port  (red_orig),
        .green_port(green_orig),
        .blue_port (blue_orig),
        .upscale_mode(mode_sel[1])  // mode 2,3에서 업스케일
    );
    
    // SCCB 모듈
    SCCB_core u_SCCB_core(
        .clk           (clk),
        .reset         (reset),
        .initial_start (initial_start),
        .sioc          (sioc),
        .siod          (siod)
    );
    
    // 1비트 변환 (휘도 기반) - 임계값 조정
    logic [5:0] luminance;
    // always_comb begin
    //     // 가중치를 적용한 휘도 계산 (더 정확함)
    //     // Y = 0.299*R + 0.587*G + 0.114*B
    //     luminance = (red_orig >> 2) + (green_orig >> 1) + (blue_orig >> 3);
    //     pixel_1bit = (luminance > 6'd4) ? 1'b1 : 1'b0;  // 임계값 낮춤
    // end

    always_comb begin
    // 간단한 휘도 계산
        luminance = (red_orig + green_orig + blue_orig);
        pixel_1bit = (luminance > 6'd16) ? 1'b1 : 1'b0;  // 임계값 조정
    end
    
    // DE 신호 생성 (전체 640x480 영역)
    logic de_full;
    assign de_full = DE;  // 전체 화면 사용
    
    // 업스케일 모듈
    // upscale U_Upscale (
    //     .clk         (clk),
    //     .rst_n       (~reset),
    //     .pixel_1bit_i(pixel_1bit),
    //     .de_i        (de_full),     // 전체 화면 DE 사용
    //     .h_sync_i    (h_sync_orig),
    //     .v_sync_i    (v_sync_orig),
    //     .pixel_r_o   (red_up),
    //     .pixel_g_o   (green_up),
    //     .pixel_b_o   (blue_up),
    //     .de_o        (de_up),
    //     .h_sync_o    (h_sync_up),
    //     .v_sync_o    (v_sync_up)
    // );

    upscale U_Upscale (
        .clk         (clk),
        .rst_n       (~reset),
        .pixel_r_i   (red_orig),      // 원본 RGB 입력
        .pixel_g_i   (green_orig),
        .pixel_b_i   (blue_orig),
        .de_i        (de_full),
        .h_sync_i    (h_sync_orig),
        .v_sync_i    (v_sync_orig),
        .pixel_r_o   (red_up),
        .pixel_g_o   (green_up),
        .pixel_b_o   (blue_up),
        .de_o        (de_up),
        .h_sync_o    (h_sync_up),
        .v_sync_o    (v_sync_up)
    );
    
    // 안티앨리어싱 모듈 (640x480로 수정)
    // antialiasing_filter #(
    //     .H_ACTIVE(640),     // 320 -> 640
    //     .V_ACTIVE(480)      // 240 -> 480
    // ) U_AA_Filter (
    //     .clk        (clk),
    //     .rst_n      (~reset),
    //     .h_sync_i   (h_sync_up),
    //     .v_sync_i   (v_sync_up),
    //     .de_i       (de_up),
    //     .pixel_r_i  (red_up),
    //     .pixel_g_i  (green_up),
    //     .pixel_b_i  (blue_up),
    //     .h_sync_o   (h_sync_aa),
    //     .v_sync_o   (v_sync_aa),
    //     .de_o       (),
    //     .pixel_r_o  (red_aa),
    //     .pixel_g_o  (green_aa),
    //     .pixel_b_o  (blue_aa),
    //     .aa_en      (aa_en)
    // );
    
    // 출력 선택 (모드별)
    // always_ff @(posedge clk) begin
    //     case (mode_sel)
    //         2'b00: begin  // 원본
    //             Hsync    <= h_sync_orig;
    //             Vsync    <= v_sync_orig;
    //             vgaRed   <= red_orig;
    //             vgaGreen <= green_orig;
    //             vgaBlue  <= blue_orig;
    //         end
            
    //         2'b01: begin  // 1비트 변환 (흑백)
    //             Hsync    <= h_sync_orig;
    //             Vsync    <= v_sync_orig;
    //             vgaRed   <= pixel_1bit ? 4'hF : 4'h0;
    //             vgaGreen <= pixel_1bit ? 4'hF : 4'h0;
    //             vgaBlue  <= pixel_1bit ? 4'hF : 4'h0;
    //         end
            
    //         2'b10: begin  // 업스케일만
    //             Hsync    <= h_sync_up;
    //             Vsync    <= v_sync_up;
    //             vgaRed   <= red_up;
    //             vgaGreen <= green_up;
    //             vgaBlue  <= blue_up;
    //         end
            
    //         2'b11: begin  // AA 적용
    //             Hsync    <= h_sync_aa;
    //             Vsync    <= v_sync_aa;
    //             vgaRed   <= red_aa;
    //             vgaGreen <= green_aa;
    //             vgaBlue  <= blue_aa;
    //         end
    //     endcase
    // end

    always_ff @(posedge clk) begin
        case (mode_sel)
            2'b00: begin  // 원본 (320x240 컬러)
                Hsync    <= h_sync_orig;
                Vsync    <= v_sync_orig;
                vgaRed   <= red_orig;
                vgaGreen <= green_orig;
                vgaBlue  <= blue_orig;
            end
            
            2'b01: begin  // 1비트 변환 (320x240 흑백)
                Hsync    <= h_sync_orig;
                Vsync    <= v_sync_orig;
                vgaRed   <= pixel_1bit ? 4'hF : 4'h0;
                vgaGreen <= pixel_1bit ? 4'hF : 4'h0;
                vgaBlue  <= pixel_1bit ? 4'hF : 4'h0;
            end
            
            2'b10: begin  // 보간 업스케일 (640x480 컬러, 부드러움)
                Hsync    <= h_sync_orig;
                Vsync    <= v_sync_orig;
                vgaRed   <= red_up;       // 보간된 업스케일 출력
                vgaGreen <= green_up;
                vgaBlue  <= blue_up;
            end
            
            2'b11: begin  // Mode 2와 동일 (또는 다른 기능)
                Hsync    <= h_sync_orig;
                Vsync    <= v_sync_orig;
                vgaRed   <= red_up;       // 같은 출력
                vgaGreen <= green_up;
                vgaBlue  <= blue_up;
            end
        endcase
    end

endmodule