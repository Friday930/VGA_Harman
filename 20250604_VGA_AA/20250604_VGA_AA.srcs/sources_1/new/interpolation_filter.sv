// `timescale 1ns / 1ps

// module interpolation_filter (
//     input  logic       clk,
//     input  logic       rst_n,
    
//     // 업스케일된 RGB 입력
//     input  logic [3:0] pixel_r_i,
//     input  logic [3:0] pixel_g_i,
//     input  logic [3:0] pixel_b_i,
//     input  logic       de_i,
//     input  logic       h_sync_i,
//     input  logic       v_sync_i,
    
//     // 보간된 RGB 출력
//     output logic [3:0] pixel_r_o,
//     output logic [3:0] pixel_g_o,
//     output logic [3:0] pixel_b_o,
//     output logic       de_o,
//     output logic       h_sync_o,
//     output logic       v_sync_o
// );

//     // 3개 이전 픽셀 저장 (더 넓은 범위 보간)
//     logic [3:0] prev_r [0:2];
//     logic [3:0] prev_g [0:2];
//     logic [3:0] prev_b [0:2];
    
//     always_ff @(posedge clk) begin
//         if (de_i) begin
//             // 시프트 레지스터로 이전 픽셀들 저장
//             prev_r[2] <= prev_r[1];
//             prev_r[1] <= prev_r[0];
//             prev_r[0] <= pixel_r_i;
            
//             prev_g[2] <= prev_g[1];
//             prev_g[1] <= prev_g[0];
//             prev_g[0] <= pixel_g_i;
            
//             prev_b[2] <= prev_b[1];
//             prev_b[1] <= prev_b[0];
//             prev_b[0] <= pixel_b_i;
//         end
//     end
    
//     // 4픽셀 가중 평균 계산 (부드러운 보간)
//     logic [5:0] smooth_r, smooth_g, smooth_b;
    
//     always_comb begin
//         // 가중 평균: 현재(50%) + 이전1(25%) + 이전2(15%) + 이전3(10%)
//         smooth_r = ({2'b00, pixel_r_i} << 1) +     // 현재 * 2 (50%)
//                    {2'b00, prev_r[0]} +            // 이전1 * 1 (25%)
//                    ({2'b00, prev_r[1]} >> 1) +     // 이전2 * 0.5 (12.5%)
//                    ({2'b00, prev_r[2]} >> 1);      // 이전3 * 0.5 (12.5%)
                   
//         smooth_g = ({2'b00, pixel_g_i} << 1) +
//                    {2'b00, prev_g[0]} +
//                    ({2'b00, prev_g[1]} >> 1) +
//                    ({2'b00, prev_g[2]} >> 1);
                   
//         smooth_b = ({2'b00, pixel_b_i} << 1) +
//                    {2'b00, prev_b[0]} +
//                    ({2'b00, prev_b[1]} >> 1) +
//                    ({2'b00, prev_b[2]} >> 1);
//     end

//     // 출력 - 부드러운 보간 적용
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             pixel_r_o <= '0;
//             pixel_g_o <= '0;
//             pixel_b_o <= '0;
//             de_o <= '0;
//             h_sync_o <= 1'b1;
//             v_sync_o <= 1'b1;
//         end else begin
//             // 동기 신호는 지연 없이 바로 통과
//             de_o <= de_i;
//             h_sync_o <= h_sync_i;
//             v_sync_o <= v_sync_i;
            
//             // 가중 평균으로 부드러운 효과 (÷4)
//             pixel_r_o <= smooth_r[5:2];
//             pixel_g_o <= smooth_g[5:2];
//             pixel_b_o <= smooth_b[5:2];
//         end
//     end

// endmodule

`timescale 1ns / 1ps

module interpolation_filter (
    input  logic       clk,
    input  logic       rst_n,
    
    // 업스케일된 RGB 입력 (4비트씩)
    input  logic [3:0] pixel_r_i,
    input  logic [3:0] pixel_g_i,
    input  logic [3:0] pixel_b_i,
    input  logic       de_i,
    input  logic       h_sync_i,
    input  logic       v_sync_i,
    
    // 보간된 RGB 출력 (4비트씩)
    output logic [3:0] pixel_r_o,
    output logic [3:0] pixel_g_o,
    output logic [3:0] pixel_b_o,
    output logic       de_o,
    output logic       h_sync_o,
    output logic       v_sync_o
);

    // 최소 메모리: 이전 픽셀 4개만 저장 (4x4 보간용)
    logic [3:0] prev_r[0:3], prev_g[0:3], prev_b[0:3];
    
    // 픽셀 위치 추적 (최소 비트)
    logic [1:0] x_phase, y_phase;  // 4x4 패턴 추적
    logic [9:0] pixel_x, pixel_y;
    logic de_prev;
    
    always_ff @(posedge clk) de_prev <= de_i;
    wire line_start = de_i & ~de_prev;
    wire frame_start = ~v_sync_i;
    
    // 픽셀 좌표 카운터
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_x <= '0;
            pixel_y <= '0;
            x_phase <= '0;
            y_phase <= '0;
        end else if (frame_start) begin
            pixel_x <= '0;
            pixel_y <= '0;
            x_phase <= '0;
            y_phase <= '0;
        end else if (line_start) begin
            pixel_x <= '0;
            x_phase <= '0;
            if (pixel_y < 479) begin
                pixel_y <= pixel_y + 1'b1;
                y_phase <= y_phase + 1'b1;
            end
        end else if (de_i) begin
            if (pixel_x < 639) begin
                pixel_x <= pixel_x + 1'b1;
                x_phase <= x_phase + 1'b1;
            end
        end
    end
    
    // 이전 픽셀들 시프트 레지스터
    always_ff @(posedge clk) begin
        if (de_i) begin
            prev_r[3] <= prev_r[2];
            prev_r[2] <= prev_r[1];
            prev_r[1] <= prev_r[0];
            prev_r[0] <= pixel_r_i;
            
            prev_g[3] <= prev_g[2];
            prev_g[2] <= prev_g[1];
            prev_g[1] <= prev_g[0];
            prev_g[0] <= pixel_g_i;
            
            prev_b[3] <= prev_b[2];
            prev_b[2] <= prev_b[1];
            prev_b[1] <= prev_b[0];
            prev_b[0] <= pixel_b_i;
        end
    end
    
    // 실시간 선형 보간 계산
    logic [3:0] interp_r, interp_g, interp_b;
    logic [4:0] blend_r, blend_g, blend_b;
    
    always_comb begin
        case ({y_phase, x_phase})
            // 원본 픽셀 위치들 (4x4 격자의 모서리)
            4'b0000, 4'b0010, 4'b1000, 4'b1010: begin
                interp_r = pixel_r_i;  // 원본 그대로
                interp_g = pixel_g_i;
                interp_b = pixel_b_i;
            end
            
            // 수평 보간 (홀수 x, 짝수 y)
            4'b0001, 4'b0011, 4'b1001, 4'b1011: begin
                if (pixel_x > 0) begin
                    blend_r = {1'b0, pixel_r_i} + {1'b0, prev_r[0]};
                    blend_g = {1'b0, pixel_g_i} + {1'b0, prev_g[0]};
                    blend_b = {1'b0, pixel_b_i} + {1'b0, prev_b[0]};
                    interp_r = blend_r[4:1];  // ÷2
                    interp_g = blend_g[4:1];
                    interp_b = blend_b[4:1];
                end else begin
                    interp_r = pixel_r_i;
                    interp_g = pixel_g_i;
                    interp_b = pixel_b_i;
                end
            end
            
            // 수직 보간 (짝수 x, 홀수 y) - 이전 라인과 평균
            4'b0100, 4'b0110, 4'b1100, 4'b1110: begin
                if (pixel_y > 0) begin
                    // 간단한 수직 보간 (이전 픽셀과 평균)
                    blend_r = {1'b0, pixel_r_i} + {1'b0, prev_r[1]};
                    blend_g = {1'b0, pixel_g_i} + {1'b0, prev_g[1]};
                    blend_b = {1'b0, pixel_b_i} + {1'b0, prev_b[1]};
                    interp_r = blend_r[4:1];
                    interp_g = blend_g[4:1];
                    interp_b = blend_b[4:1];
                end else begin
                    interp_r = pixel_r_i;
                    interp_g = pixel_g_i;
                    interp_b = pixel_b_i;
                end
            end
            
            // 대각선 보간 (홀수 x, 홀수 y)
            4'b0101, 4'b0111, 4'b1101, 4'b1111: begin
                if (pixel_x > 0 && pixel_y > 0) begin
                    // 4개 픽셀의 평균 (간단하게 2개씩 평균)
                    blend_r = {1'b0, pixel_r_i} + {1'b0, prev_r[0]} + {1'b0, prev_r[1]} + {1'b0, prev_r[2]};
                    blend_g = {1'b0, pixel_g_i} + {1'b0, prev_g[0]} + {1'b0, prev_g[1]} + {1'b0, prev_g[2]};
                    blend_b = {1'b0, pixel_b_i} + {1'b0, prev_b[0]} + {1'b0, prev_b[1]} + {1'b0, prev_b[2]};
                    interp_r = blend_r[5:2];  // ÷4
                    interp_g = blend_g[5:2];
                    interp_b = blend_b[5:2];
                end else begin
                    interp_r = pixel_r_i;
                    interp_g = pixel_g_i;
                    interp_b = pixel_b_i;
                end
            end
            
            default: begin
                interp_r = pixel_r_i;
                interp_g = pixel_g_i;
                interp_b = pixel_b_i;
            end
        endcase
    end
    
    // 에지 감지로 보간 강도 조절
    logic apply_full_interp;
    logic [4:0] diff_total;
    
    always_comb begin
        diff_total = 0;
        if (pixel_x > 0) begin
            if (pixel_r_i > prev_r[0]) diff_total = diff_total + (pixel_r_i - prev_r[0]);
            else diff_total = diff_total + (prev_r[0] - pixel_r_i);
            
            if (pixel_g_i > prev_g[0]) diff_total = diff_total + (pixel_g_i - prev_g[0]);
            else diff_total = diff_total + (prev_g[0] - pixel_g_i);
            
            if (pixel_b_i > prev_b[0]) diff_total = diff_total + (pixel_b_i - prev_b[0]);
            else diff_total = diff_total + (prev_b[0] - pixel_b_i);
        end
        
        // 색상 변화가 클 때만 풀 보간 적용
        apply_full_interp = (diff_total > 5'd6);
    end
    
    // 최종 픽셀 값 결정
    logic [3:0] final_r, final_g, final_b;
    
    always_comb begin
        if (apply_full_interp) begin
            // 에지 영역: 풀 보간
            final_r = interp_r;
            final_g = interp_g;
            final_b = interp_b;
        end else begin
            // 평탄한 영역: 원본 또는 약한 보간
            case ({y_phase[0], x_phase[0]})
                2'b00: begin  // 원본 위치
                    final_r = pixel_r_i;
                    final_g = pixel_g_i;
                    final_b = pixel_b_i;
                end
                default: begin  // 약한 보간 (75% 원본 + 25% 보간)
                    final_r = (({2'b00, pixel_r_i} << 1) + {2'b00, pixel_r_i} + {2'b00, interp_r}) >> 2;
                    final_g = (({2'b00, pixel_g_i} << 1) + {2'b00, pixel_g_i} + {2'b00, interp_g}) >> 2;
                    final_b = (({2'b00, pixel_b_i} << 1) + {2'b00, pixel_b_i} + {2'b00, interp_b}) >> 2;
                end
            endcase
        end
    end

    // 출력
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_r_o <= '0;
            pixel_g_o <= '0;
            pixel_b_o <= '0;
            de_o <= '0;
            h_sync_o <= 1'b1;
            v_sync_o <= 1'b1;
        end else begin
            // 동기 신호 전달
            de_o <= de_i;
            h_sync_o <= h_sync_i;
            v_sync_o <= v_sync_i;
            
            // 보간된 RGB 출력
            pixel_r_o <= final_r;
            pixel_g_o <= final_g;
            pixel_b_o <= final_b;
        end
    end

endmodule