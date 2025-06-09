// `timescale 1ns / 1ps

// module noise_reduction_filter (
//     input  logic       clk,
//     input  logic       reset,
    
//     // RGB 입력
//     input  logic [3:0] pixel_r_i,
//     input  logic [3:0] pixel_g_i,
//     input  logic [3:0] pixel_b_i,
//     input  logic       de_i,
//     input  logic       h_sync_i,
//     input  logic       v_sync_i,
    
//     // 필터된 RGB 출력
//     output logic [3:0] pixel_r_o,
//     output logic [3:0] pixel_g_o,
//     output logic [3:0] pixel_b_o,
//     output logic       de_o,
//     output logic       h_sync_o,
//     output logic       v_sync_o
// );

//     // 이전 픽셀들 저장 (수평 방향)
//     logic [3:0] prev_r[0:3];  // 4픽셀 히스토리
//     logic [3:0] prev_g[0:3];
//     logic [3:0] prev_b[0:3];
    
//     // 픽셀 히스토리 시프트
//     always_ff @(posedge clk) begin
//         if (de_i) begin
//             prev_r[3] <= prev_r[2];
//             prev_r[2] <= prev_r[1];
//             prev_r[1] <= prev_r[0];
//             prev_r[0] <= pixel_r_i;
            
//             prev_g[3] <= prev_g[2];
//             prev_g[2] <= prev_g[1];
//             prev_g[1] <= prev_g[0];
//             prev_g[0] <= pixel_g_i;
            
//             prev_b[3] <= prev_b[2];
//             prev_b[2] <= prev_b[1];
//             prev_b[1] <= prev_b[0];
//             prev_b[0] <= pixel_b_i;
//         end
//     end
    
//     // 계단 검출: 4픽셀이 모두 같으면 계단 (4x4 블록의 특징)
//     logic is_step_r, is_step_g, is_step_b;
//     always_comb begin
//         is_step_r = (pixel_r_i == prev_r[0]) && (prev_r[0] == prev_r[1]) && 
//                     (prev_r[1] == prev_r[2]) && (prev_r[2] == prev_r[3]);
//         is_step_g = (pixel_g_i == prev_g[0]) && (prev_g[0] == prev_g[1]) && 
//                     (prev_g[1] == prev_g[2]) && (prev_g[2] == prev_g[3]);
//         is_step_b = (pixel_b_i == prev_b[0]) && (prev_b[0] == prev_b[1]) && 
//                     (prev_b[1] == prev_b[2]) && (prev_b[2] == prev_b[3]);
//     end
    
//     // 계단 끝 검출: 4픽셀 같다가 갑자기 바뀜
//     logic step_end_r, step_end_g, step_end_b;
//     always_comb begin
//         step_end_r = is_step_r && (pixel_r_i != prev_r[0]);
//         step_end_g = is_step_g && (pixel_g_i != prev_g[0]);
//         step_end_b = is_step_b && (pixel_b_i != prev_b[0]);
//     end
    
//     // 계단현상 완화 필터
//     logic [3:0] smooth_r, smooth_g, smooth_b;
    
//     always_comb begin
//         // R 채널 처리
//         if (step_end_r && de_i) begin
//             // 계단 끝에서 중간값 생성 (이전 + 현재) / 2
//             smooth_r = (prev_r[0] + pixel_r_i) >> 1;
//         end else if (is_step_r && de_i) begin
//             // 계단 중간에서 약간의 노이즈 추가 (자연스럽게)
//             case (prev_r[0][1:0])  // 하위 2비트로 패턴 생성
//                 2'b00: smooth_r = prev_r[0];
//                 2'b01: smooth_r = (prev_r[0] > 0) ? prev_r[0] - 1 : prev_r[0];
//                 2'b10: smooth_r = (prev_r[0] < 15) ? prev_r[0] + 1 : prev_r[0];
//                 2'b11: smooth_r = prev_r[0];
//             endcase
//         end else begin
//             smooth_r = pixel_r_i;  // 원본 유지
//         end
        
//         // G 채널 처리
//         if (step_end_g && de_i) begin
//             smooth_g = (prev_g[0] + pixel_g_i) >> 1;
//         end else if (is_step_g && de_i) begin
//             case (prev_g[0][1:0])
//                 2'b00: smooth_g = prev_g[0];
//                 2'b01: smooth_g = (prev_g[0] > 0) ? prev_g[0] - 1 : prev_g[0];
//                 2'b10: smooth_g = (prev_g[0] < 15) ? prev_g[0] + 1 : prev_g[0];
//                 2'b11: smooth_g = prev_g[0];
//             endcase
//         end else begin
//             smooth_g = pixel_g_i;
//         end
        
//         // B 채널 처리
//         if (step_end_b && de_i) begin
//             smooth_b = (prev_b[0] + pixel_b_i) >> 1;
//         end else if (is_step_b && de_i) begin
//             case (prev_b[0][1:0])
//                 2'b00: smooth_b = prev_b[0];
//                 2'b01: smooth_b = (prev_b[0] > 0) ? prev_b[0] - 1 : prev_b[0];
//                 2'b10: smooth_b = (prev_b[0] < 15) ? prev_b[0] + 1 : prev_b[0];
//                 2'b11: smooth_b = prev_b[0];
//             endcase
//         end else begin
//             smooth_b = pixel_b_i;
//         end
//     end

//     // 출력
//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             pixel_r_o <= '0;
//             pixel_g_o <= '0;
//             pixel_b_o <= '0;
//             de_o <= '0;
//             h_sync_o <= 1'b1;
//             v_sync_o <= 1'b1;
//         end else begin
//             de_o <= de_i;
//             h_sync_o <= h_sync_i;
//             v_sync_o <= v_sync_i;
            
//             pixel_r_o <= smooth_r;
//             pixel_g_o <= smooth_g;
//             pixel_b_o <= smooth_b;
//         end
//     end

// endmodule

`timescale 1ns / 1ps

module gamma_correction_filter (
    input  logic       clk,
    input  logic       reset,
    
    // RGB 입력
    input  logic [3:0] pixel_r_i,
    input  logic [3:0] pixel_g_i,
    input  logic [3:0] pixel_b_i,
    input  logic       de_i,
    input  logic       h_sync_i,
    input  logic       v_sync_i,
    
    // 계단현상 완화된 RGB 출력
    output logic [3:0] pixel_r_o,
    output logic [3:0] pixel_g_o,
    output logic [3:0] pixel_b_o,
    output logic       de_o,
    output logic       h_sync_o,
    output logic       v_sync_o
);

    // 라인 버퍼 (이전 라인 저장) - 160픽셀만
    logic [11:0] line_buffer[0:159];  // RGB 12비트
    logic [8:0] x_count, y_count;     // 9비트로 확장 (0~319, 0~239)
    logic line_start, frame_start;
    logic de_prev;
    
    always_ff @(posedge clk) de_prev <= de_i;
    assign line_start = de_i && !de_prev;
    assign frame_start = !v_sync_i;
    
    // 좌표 카운터 (실제 320x240 기준)
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            x_count <= '0;
            y_count <= '0;
        end else if (frame_start) begin
            x_count <= '0;
            y_count <= '0;
        end else if (line_start) begin
            x_count <= '0;
            if (y_count < 239) y_count <= y_count + 1'b1;
        end else if (de_i) begin
            if (x_count < 319) x_count <= x_count + 1'b1;
        end
    end
    
    // 2x2 업스케일 패턴에서 원본 좌표 계산
    logic [7:0] orig_x, orig_y;
    logic [0:0] sub_x, sub_y;
    assign orig_x = x_count[8:1];  // ÷2 (이제 9비트에서 8비트 추출)
    assign orig_y = y_count[8:1];  // ÷2  
    assign sub_x = x_count[0];     // 2x2 블록 내 x위치
    assign sub_y = y_count[0];     // 2x2 블록 내 y위치
    
    // 라인 버퍼 업데이트 (원본 해상도 기준)
    always_ff @(posedge clk) begin
        if (de_i && (sub_x == 0) && (sub_y == 0) && (orig_x < 160)) begin
            line_buffer[orig_x] <= {pixel_r_i, pixel_g_i, pixel_b_i};
        end
    end
    
    // 2x2 윈도우 구성
    logic [3:0] p00_r, p00_g, p00_b;  // 좌상단
    logic [3:0] p01_r, p01_g, p01_b;  // 우상단
    logic [3:0] p10_r, p10_g, p10_b;  // 좌하단
    logic [3:0] p11_r, p11_g, p11_b;  // 우하단 (현재)
    
    always_comb begin
        // 현재 픽셀 (우하단)
        p11_r = pixel_r_i;
        p11_g = pixel_g_i;
        p11_b = pixel_b_i;
        
        // 이전 라인에서 가져오기
        if (y_count > 0 && orig_x < 160) begin
            p00_r = line_buffer[orig_x][11:8];
            p00_g = line_buffer[orig_x][7:4];
            p00_b = line_buffer[orig_x][3:0];
            
            if (orig_x < 159) begin
                p01_r = line_buffer[orig_x + 1][11:8];
                p01_g = line_buffer[orig_x + 1][7:4];
                p01_b = line_buffer[orig_x + 1][3:0];
            end else begin
                p01_r = p00_r;
                p01_g = p00_g;
                p01_b = p00_b;
            end
        end else begin
            p00_r = pixel_r_i;
            p00_g = pixel_g_i;
            p00_b = pixel_b_i;
            p01_r = pixel_r_i;
            p01_g = pixel_g_i;
            p01_b = pixel_b_i;
        end
        
        // 좌하단은 현재 라인, 이전 픽셀
        p10_r = pixel_r_i;  // 단순화
        p10_g = pixel_g_i;
        p10_b = pixel_b_i;
    end
    
    // 이선형 보간
    logic [3:0] interp_r, interp_g, interp_b;
    
    always_comb begin
        case ({sub_y, sub_x})
            2'b00: begin  // 좌상단 - 원본
                interp_r = p00_r;
                interp_g = p00_g;
                interp_b = p00_b;
            end
            2'b01: begin  // 우상단 - 수평 보간
                interp_r = (p00_r + p01_r) >> 1;
                interp_g = (p00_g + p01_g) >> 1;
                interp_b = (p00_b + p01_b) >> 1;
            end
            2'b10: begin  // 좌하단 - 수직 보간
                interp_r = (p00_r + p10_r) >> 1;
                interp_g = (p00_g + p10_g) >> 1;
                interp_b = (p00_b + p10_b) >> 1;
            end
            2'b11: begin  // 우하단 - 대각선 보간
                interp_r = (p00_r + p01_r + p10_r + p11_r) >> 2;
                interp_g = (p00_g + p01_g + p10_g + p11_g) >> 2;
                interp_b = (p00_b + p01_b + p10_b + p11_b) >> 2;
            end
        endcase
    end

    // 출력
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
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
            
            pixel_r_o <= interp_r;
            pixel_g_o <= interp_g;
            pixel_b_o <= interp_b;
        end
    end

endmodule