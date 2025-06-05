// `timescale 1ns / 1ps

// module upscale (
//     input  logic       clk,
//     input  logic       rst_n,
    
//     // 1비트 입력
//     input  logic       pixel_1bit_i,
//     input  logic       de_i,
//     input  logic       h_sync_i,
//     input  logic       v_sync_i,
    
//     // 4비트 RGB444 출력
//     output logic [3:0] pixel_r_o,
//     output logic [3:0] pixel_g_o,
//     output logic [3:0] pixel_b_o,
//     output logic       de_o,
//     output logic       h_sync_o,
//     output logic       v_sync_o
// );

//     // 단순히 1비트를 4비트로 변환하고 바로 출력
//     logic [3:0] pixel_4bit;
//     assign pixel_4bit = pixel_1bit_i ? 4'hF : 4'h0;
    
//     // 지연 없이 바로 출력 (동기 신호 유지)
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             pixel_r_o <= '0;
//             pixel_g_o <= '0;
//             pixel_b_o <= '0;
//             de_o <= '0;
//             h_sync_o <= 1'b1;
//             v_sync_o <= 1'b1;
//         end else begin
//             pixel_r_o <= pixel_4bit;
//             pixel_g_o <= pixel_4bit;
//             pixel_b_o <= pixel_4bit;
//             de_o <= de_i;
//             h_sync_o <= h_sync_i;
//             v_sync_o <= v_sync_i;
//         end
//     end

// endmodule

// 최종 보간 업스케일 모듈 (AA 모듈 대체)
`timescale 1ns / 1ps

module upscale (
    input  logic       clk,
    input  logic       rst_n,
    
    // 원본 RGB 입력 (4비트씩)
    input  logic [3:0] pixel_r_i,
    input  logic [3:0] pixel_g_i,
    input  logic [3:0] pixel_b_i,
    input  logic       de_i,
    input  logic       h_sync_i,
    input  logic       v_sync_i,
    
    // 4비트 RGB444 출력 (업스케일된)
    output logic [3:0] pixel_r_o,
    output logic [3:0] pixel_g_o,
    output logic [3:0] pixel_b_o,
    output logic       de_o,
    output logic       h_sync_o,
    output logic       v_sync_o
);

    // 이전 픽셀 저장 (보간용)
    logic [3:0] prev_r, prev_g, prev_b;
    
    always_ff @(posedge clk) begin
        if (de_i) begin
            prev_r <= pixel_r_i;
            prev_g <= pixel_g_i;
            prev_b <= pixel_b_i;
        end
    end
    
    // 픽셀 좌표 카운터 (보간 위치 결정용)
    logic [9:0] x_cnt, y_cnt;
    logic de_prev;
    
    always_ff @(posedge clk) de_prev <= de_i;
    wire line_start = de_i & ~de_prev;
    wire frame_start = ~v_sync_i;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= '0;
            y_cnt <= '0;
        end else if (frame_start) begin
            x_cnt <= '0;
            y_cnt <= '0;
        end else if (line_start) begin
            x_cnt <= '0;
            if (y_cnt < 479) y_cnt <= y_cnt + 1'b1;
        end else if (de_i) begin
            if (x_cnt < 639) x_cnt <= x_cnt + 1'b1;
        end
    end
    
    // 보간 계산
    logic [4:0] interp_r, interp_g, interp_b;
    logic use_interpolation;
    
    always_comb begin
        // 홀수 x 좌표에서 보간 적용 (중간 픽셀)
        use_interpolation = x_cnt[0];
        
        // 현재와 이전 픽셀의 평균
        interp_r = {1'b0, pixel_r_i} + {1'b0, prev_r};
        interp_g = {1'b0, pixel_g_i} + {1'b0, prev_g};
        interp_b = {1'b0, pixel_b_i} + {1'b0, prev_b};
    end

    // 출력 - 보간 또는 원본
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_r_o <= '0;
            pixel_g_o <= '0;
            pixel_b_o <= '0;
            de_o <= '0;
            h_sync_o <= 1'b1;
            v_sync_o <= 1'b1;
        end else begin
            de_o <= de_i;
            h_sync_o <= h_sync_i;
            v_sync_o <= v_sync_i;
            
            if (use_interpolation) begin
                // 보간된 중간값 (부드러운 전환)
                pixel_r_o <= interp_r[4:1];  // ÷2
                pixel_g_o <= interp_g[4:1];
                pixel_b_o <= interp_b[4:1];
            end else begin
                // 원본 픽셀 그대로
                pixel_r_o <= pixel_r_i;
                pixel_g_o <= pixel_g_i;
                pixel_b_o <= pixel_b_i;
            end
        end
    end

endmodule