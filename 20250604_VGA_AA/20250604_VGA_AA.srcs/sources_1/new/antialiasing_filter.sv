// `timescale 1ns / 1ps

// module antialiasing_filter #(
//     parameter H_ACTIVE = 640,
//     parameter V_ACTIVE = 480
// )(
//     input  logic       clk,
//     input  logic       rst_n,
    
//     // VGA 입력
//     input  logic       h_sync_i,
//     input  logic       v_sync_i,
//     input  logic       de_i,
//     input  logic [3:0] pixel_r_i,
//     input  logic [3:0] pixel_g_i,
//     input  logic [3:0] pixel_b_i,
    
//     // VGA 출력
//     output logic       h_sync_o,
//     output logic       v_sync_o,
//     output logic       de_o,
//     output logic [3:0] pixel_r_o,
//     output logic [3:0] pixel_g_o,
//     output logic [3:0] pixel_b_o,
    
//     // 제어
//     input  logic       aa_en
// );

//     // 2개 라인 버퍼 사용
//     (* ram_style = "block" *)
//     logic [11:0] line_buffer0 [0:H_ACTIVE-1];
//     (* ram_style = "block" *)
//     logic [11:0] line_buffer1 [0:H_ACTIVE-1];
    
//     // 카운터 및 제어
//     logic [9:0] x_cnt;
//     logic [8:0] y_cnt;
//     logic buf_sel;  // 버퍼 토글
//     logic de_prev;
    
//     always_ff @(posedge clk) de_prev <= de_i;
//     wire line_start = de_i & ~de_prev;
//     wire line_end = ~de_i & de_prev;
    
//     // 좌표 카운터
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             x_cnt <= '0;
//             y_cnt <= '0;
//         end else if (v_sync_i) begin
//             x_cnt <= '0;
//             y_cnt <= '0;
//         end else if (line_start) begin
//             x_cnt <= '0;
//             if (y_cnt < V_ACTIVE-1)
//                 y_cnt <= y_cnt + 1'b1;
//         end else if (de_i) begin
//             x_cnt <= x_cnt + 1'b1;
//         end
//     end
    
//     // 버퍼 선택 토글
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n || v_sync_i)
//             buf_sel <= 1'b0;
//         else if (line_end)
//             buf_sel <= ~buf_sel;
//     end
    
//     // 3x3 픽셀 윈도우
//     // [p00 p01 p02]  <- 2줄 전
//     // [p10 p11 p12]  <- 1줄 전  
//     // [p20 p21 p22]  <- 현재 줄
//     logic [11:0] p00, p01, p02;
//     logic [11:0] p10, p11, p12;
//     logic [11:0] p20, p21, p22;
    
//     // 라인 버퍼 읽기
//     logic [11:0] line0_data, line1_data;
//     logic [9:0] rd_addr;
//     assign rd_addr = (x_cnt == H_ACTIVE-1) ? 10'd0 : x_cnt + 10'd1;
    
//     always_ff @(posedge clk) begin
//         if (de_i && x_cnt < H_ACTIVE-1) begin
//             if (buf_sel) begin
//                 line0_data <= line_buffer1[rd_addr];  // 2줄 전
//                 line1_data <= line_buffer0[rd_addr];  // 1줄 전
//             end else begin
//                 line0_data <= line_buffer0[rd_addr];  // 2줄 전
//                 line1_data <= line_buffer1[rd_addr];  // 1줄 전
//             end
//         end
//     end
    
//     // 라인 버퍼 쓰기 (현재 줄)
//     always_ff @(posedge clk) begin
//         if (de_i) begin
//             if (buf_sel)
//                 line_buffer0[x_cnt] <= {pixel_r_i, pixel_g_i, pixel_b_i};
//             else
//                 line_buffer1[x_cnt] <= {pixel_r_i, pixel_g_i, pixel_b_i};
//         end
//     end
    
//     // 3x3 윈도우 시프트
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             {p00, p01, p02} <= '0;
//             {p10, p11, p12} <= '0;
//             {p20, p21, p22} <= '0;
//         end else if (de_i) begin
//             // 각 라인 시프트
//             p02 <= p01; p01 <= p00; p00 <= line0_data;
//             p12 <= p11; p11 <= p10; p10 <= line1_data;
//             p22 <= p21; p21 <= p20; p20 <= {pixel_r_i, pixel_g_i, pixel_b_i};
//         end
//     end
    
//     // 간단한 엣지 검출 (중앙 차분만 사용)
//     logic [4:0] diff_h, diff_v;
//     logic is_edge;
    
//     always_comb begin
//         // 수평/수직 차분만 계산 (휘도 기반)
//         // 휘도 근사: Y = (R + 2G + B) / 4
//         logic [5:0] luma_center, luma_left, luma_right, luma_up, luma_down;
        
//         luma_center = p11[11:8] + (p11[7:4]<<1) + p11[3:0];
//         luma_left   = p10[11:8] + (p10[7:4]<<1) + p10[3:0];
//         luma_right  = p12[11:8] + (p12[7:4]<<1) + p12[3:0];
//         luma_up     = p01[11:8] + (p01[7:4]<<1) + p01[3:0];
//         luma_down   = p21[11:8] + (p21[7:4]<<1) + p21[3:0];
        
//         // 절대값 차이
//         diff_h = (luma_center > luma_left) ? 
//                  (luma_center - luma_left) : (luma_left - luma_center);
//         diff_v = (luma_center > luma_up) ? 
//                  (luma_center - luma_up) : (luma_up - luma_center);
        
//         // 간단한 엣지 판정
//         is_edge = (diff_h > 5'd8) || (diff_v > 5'd8);
//     end
    
//     // 간단한 4-탭 평균 필터
//     logic [5:0] avg_r, avg_g, avg_b;
    
//     always_comb begin
//         // 4방향 평균 (중앙 제외)
//         avg_r = p01[11:8] + p10[11:8] + p12[11:8] + p21[11:8];
//         avg_g = p01[7:4] + p10[7:4] + p12[7:4] + p21[7:4];
//         avg_b = p01[3:0] + p10[3:0] + p12[3:0] + p21[3:0];
//     end
    
//     // 출력 파이프라인
//     logic [2:0] de_pipe;
//     logic [3:0] r_out, g_out, b_out;
    
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             de_pipe <= '0;
//             r_out <= '0;
//             g_out <= '0;
//             b_out <= '0;
//         end else begin
//             de_pipe <= {de_pipe[1:0], de_i};
            
//             if (aa_en && is_edge && (y_cnt >= 2) && (x_cnt >= 2)) begin
//                 // 엣지에서 AA 적용 (4-탭 평균)
//                 r_out <= avg_r[5:2];  // ÷4
//                 g_out <= avg_g[5:2];
//                 b_out <= avg_b[5:2];
//             end else begin
//                 // 원본 픽셀
//                 r_out <= p11[11:8];
//                 g_out <= p11[7:4];
//                 b_out <= p11[3:0];
//             end
//         end
//     end
    
//     // 최종 출력
//     assign h_sync_o = h_sync_i;
//     assign v_sync_o = v_sync_i;
//     assign de_o = de_pipe[2];
    
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             pixel_r_o <= '0;
//             pixel_g_o <= '0;
//             pixel_b_o <= '0;
//         end else begin
//             pixel_r_o <= de_pipe[2] ? r_out : 4'h0;
//             pixel_g_o <= de_pipe[2] ? g_out : 4'h0;
//             pixel_b_o <= de_pipe[2] ? b_out : 4'h0;
//         end
//     end

// endmodule


`timescale 1ns / 1ps

module antialiasing_filter #(
    parameter H_ACTIVE = 640,
    parameter V_ACTIVE = 480
)(
    input  logic       clk,
    input  logic       rst_n,
    
    // VGA 입력
    input  logic       h_sync_i,
    input  logic       v_sync_i,
    input  logic       de_i,
    input  logic [3:0] pixel_r_i,
    input  logic [3:0] pixel_g_i,
    input  logic [3:0] pixel_b_i,
    
    // VGA 출력
    output logic       h_sync_o,
    output logic       v_sync_o,
    output logic       de_o,
    output logic [3:0] pixel_r_o,
    output logic [3:0] pixel_g_o,
    output logic [3:0] pixel_b_o,
    
    // 제어
    input  logic       aa_en
);

    // 이전 1픽셀만 저장 (가벼운 블러)
    logic [3:0] prev_r, prev_g, prev_b;
    
    always_ff @(posedge clk) begin
        if (de_i) begin
            prev_r <= pixel_r_i;
            prev_g <= pixel_g_i;
            prev_b <= pixel_b_i;
        end
    end
    
    // 가중 평균 계산 (현재 75% + 이전 25%)
    logic [5:0] blend_r, blend_g, blend_b;
    
    always_comb begin
        // 현재 픽셀에 더 많은 가중치
        blend_r = ({2'b00, pixel_r_i} << 1) + ({2'b00, pixel_r_i}) + {2'b00, prev_r};  // 3*현재 + 1*이전
        blend_g = ({2'b00, pixel_g_i} << 1) + ({2'b00, pixel_g_i}) + {2'b00, prev_g};
        blend_b = ({2'b00, pixel_b_i} << 1) + ({2'b00, pixel_b_i}) + {2'b00, prev_b};
    end

    // 출력 생성 - 밝기 유지하면서 부드럽게
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_sync_o <= 1'b1;
            v_sync_o <= 1'b1;
            de_o <= 1'b0;
            pixel_r_o <= 4'h0;
            pixel_g_o <= 4'h0;
            pixel_b_o <= 4'h0;
        end else begin
            // 동기 신호는 지연 없이 통과
            h_sync_o <= h_sync_i;
            v_sync_o <= v_sync_i;
            de_o <= de_i;
            
            if (aa_en) begin
                // AA 활성화: 가중 평균으로 부드럽게 (밝기 유지)
                pixel_r_o <= blend_r[5:2];  // ÷4 (3*현재 + 1*이전 = 75%+25%)
                pixel_g_o <= blend_g[5:2];
                pixel_b_o <= blend_b[5:2];
            end else begin
                // AA 비활성화: 원본 그대로
                pixel_r_o <= pixel_r_i;
                pixel_g_o <= pixel_g_i;
                pixel_b_o <= pixel_b_i;
            end
        end
    end

endmodule