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
    input  logic       reset,
    
    // 업스케일된 RGB 입력 (4비트씩) - 이미 640x480
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

    // 픽셀 위치 카운터
    logic [9:0] x_pos, y_pos;
    logic de_prev, h_sync_prev;
    
    always_ff @(posedge clk) begin
        de_prev <= de_i;
        h_sync_prev <= h_sync_i;
    end
    
    wire h_sync_fall = h_sync_prev && !h_sync_i;
    wire de_rise = !de_prev && de_i;
    
    // 위치 추적
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            x_pos <= '0;
            y_pos <= '0;
        end else if (!v_sync_i) begin
            x_pos <= '0;
            y_pos <= '0;
        end else if (h_sync_fall) begin
            x_pos <= '0;
            if (y_pos < 479) y_pos <= y_pos + 1'b1;
        end else if (de_i) begin
            if (x_pos < 639) x_pos <= x_pos + 1'b1;
        end
    end

    // 4x4 블록 내 위치 (160x120 -> 640x480 매핑)
    logic [1:0] block_x, block_y;
    assign block_x = x_pos[1:0];  // 0,1,2,3
    assign block_y = y_pos[1:0];  // 0,1,2,3
    
    // 이전 픽셀들 저장 (수평 방향)
    logic [3:0] pixel_hist_r[0:7];  // 8픽셀 히스토리
    logic [3:0] pixel_hist_g[0:7];
    logic [3:0] pixel_hist_b[0:7];
    
    // 픽셀 히스토리 시프트
    always_ff @(posedge clk) begin
        if (de_i) begin
            for (int i = 7; i > 0; i--) begin
                pixel_hist_r[i] <= pixel_hist_r[i-1];
                pixel_hist_g[i] <= pixel_hist_g[i-1];
                pixel_hist_b[i] <= pixel_hist_b[i-1];
            end
            pixel_hist_r[0] <= pixel_r_i;
            pixel_hist_g[0] <= pixel_g_i;
            pixel_hist_b[0] <= pixel_b_i;
        end
    end
    
    // 라인 버퍼 (이전 라인들 저장)
    logic [11:0] line_buf[0:3][0:639];  // 4라인 버퍼
    logic [1:0] line_wr_idx;
    
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            line_wr_idx <= '0;
        end else if (!v_sync_i) begin
            line_wr_idx <= '0;
        end else if (h_sync_fall) begin
            line_wr_idx <= line_wr_idx + 1'b1;
        end
    end
    
    // 라인 버퍼 업데이트
    always_ff @(posedge clk) begin
        if (de_i && x_pos < 640) begin
            line_buf[line_wr_idx][x_pos] <= {pixel_r_i, pixel_g_i, pixel_b_i};
        end
    end
    
    // 보간 계산
    logic [3:0] interp_r, interp_g, interp_b;
    logic apply_interp;
    
    // 보간 적용 조건: 4x4 블록의 경계 위치
    assign apply_interp = de_i && (
        (block_x == 2'b01) ||  // x=1: 좌우 보간
        (block_x == 2'b10) ||  // x=2: 좌우 보간  
        (block_y == 2'b01) ||  // y=1: 상하 보간
        (block_y == 2'b10)     // y=2: 상하 보간
    );
    
    always_comb begin
        if (!apply_interp) begin
            // 원본 픽셀 그대로
            interp_r = pixel_r_i;
            interp_g = pixel_g_i;
            interp_b = pixel_b_i;
        end else begin
            // 보간 적용
            case ({block_y, block_x})
                4'b0001: begin  // (0,1) - 수평 보간
                    if (x_pos >= 4) begin
                        interp_r = (pixel_r_i + pixel_hist_r[3]) >> 1;  // 현재와 4픽셀 전 평균
                        interp_g = (pixel_g_i + pixel_hist_g[3]) >> 1;
                        interp_b = (pixel_b_i + pixel_hist_b[3]) >> 1;
                    end else begin
                        interp_r = pixel_r_i;
                        interp_g = pixel_g_i;
                        interp_b = pixel_b_i;
                    end
                end
                
                4'b0010: begin  // (0,2) - 수평 보간
                    if (x_pos >= 4) begin
                        interp_r = (pixel_r_i + pixel_hist_r[3]) >> 1;
                        interp_g = (pixel_g_i + pixel_hist_g[3]) >> 1;
                        interp_b = (pixel_b_i + pixel_hist_b[3]) >> 1;
                    end else begin
                        interp_r = pixel_r_i;
                        interp_g = pixel_g_i;
                        interp_b = pixel_b_i;
                    end
                end
                
                4'b0100, 4'b1000: begin  // (1,0), (2,0) - 수직 보간
                    if (y_pos >= 4 && x_pos < 640) begin
                        logic [1:0] prev_line_idx;
                        prev_line_idx = line_wr_idx - 1'b1;  // 4라인 전
                        interp_r = (pixel_r_i + line_buf[prev_line_idx][x_pos][11:8]) >> 1;
                        interp_g = (pixel_g_i + line_buf[prev_line_idx][x_pos][7:4]) >> 1;
                        interp_b = (pixel_b_i + line_buf[prev_line_idx][x_pos][3:0]) >> 1;
                    end else begin
                        interp_r = pixel_r_i;
                        interp_g = pixel_g_i;
                        interp_b = pixel_b_i;
                    end
                end
                
                4'b0101, 4'b0110, 4'b1001, 4'b1010: begin  // 대각선 보간
                    if (y_pos >= 4 && x_pos >= 4) begin
                        logic [1:0] prev_line_idx;
                        prev_line_idx = line_wr_idx - 1'b1;
                        // 4방향 평균
                        interp_r = (pixel_r_i + pixel_hist_r[3] + line_buf[prev_line_idx][x_pos][11:8] + line_buf[prev_line_idx][x_pos-4][11:8]) >> 2;
                        interp_g = (pixel_g_i + pixel_hist_g[3] + line_buf[prev_line_idx][x_pos][7:4] + line_buf[prev_line_idx][x_pos-4][7:4]) >> 2;
                        interp_b = (pixel_b_i + pixel_hist_b[3] + line_buf[prev_line_idx][x_pos][3:0] + line_buf[prev_line_idx][x_pos-4][3:0]) >> 2;
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