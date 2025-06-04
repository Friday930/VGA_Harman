`timescale 1ns/1ps

module gaussian_filter #(
    parameter DATA_WIDTH = 4,      // 4비트 RGB (RGB444)
    parameter H_ACTIVE = 320,      // VGA 수평 활성
    parameter V_ACTIVE = 240       // VGA 수직 활성
)(
    input  logic                    clk,        // 25MHz 픽셀 클럭
    input  logic                    rst_n,
    
    // VGA 입력
    input  logic                    h_sync_i,
    input  logic                    v_sync_i,
    input  logic                    de_i,       // 활성 영역
    input  logic [3:0]              pixel_r_i,  // 4비트 RGB
    input  logic [3:0]              pixel_g_i,
    input  logic [3:0]              pixel_b_i,
    
    // VGA 출력
    output logic                    h_sync_o,
    output logic                    v_sync_o,
    output logic                    de_o,
    output logic [3:0]              pixel_r_o,
    output logic [3:0]              pixel_g_o,
    output logic [3:0]              pixel_b_o,
    
    // 필터 활성화 스위치
    input  logic                    filter_en
);

    // 2개 라인 버퍼 - 듀얼 포트 RAM으로 구성
    (* ram_style = "block" *)
    logic [11:0] line_buffer0 [0:H_ACTIVE-1];
    (* ram_style = "block" *)
    logic [11:0] line_buffer1 [0:H_ACTIVE-1];
    
    // 최소 상태 관리
    logic [9:0] h_cnt;
    logic [1:0] v_phase;  // 0, 1, 2 순환
    logic de_prev;
    
    // 엣지 검출
    always_ff @(posedge clk) de_prev <= de_i;
    wire line_start = de_i & ~de_prev;
    wire line_end = ~de_i & de_prev;
    
    // 카운터 (전력 최적화 - 조건부 업데이트)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= '0;
            v_phase <= '0;
        end else begin
            if (v_sync_i)
                v_phase <= '0;
            else if (line_end && v_phase < 2'd2)
                v_phase <= v_phase + 1'b1;
                
            if (line_start)
                h_cnt <= '0;
            else if (de_i && h_cnt < H_ACTIVE-1)
                h_cnt <= h_cnt + 1'b1;
        end
    end
    
    // 3x3 윈도우 (패킹된 형태로 저장)
    logic [11:0] w00, w01, w02;
    logic [11:0] w10, w11, w12;
    logic [11:0] w20, w21, w22;
    
    // 라인 버퍼 포인터 (전력 절감)
    logic use_buf0_for_line0;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            use_buf0_for_line0 <= 1'b1;
        else if (line_end)
            use_buf0_for_line0 <= ~use_buf0_for_line0;
    end
    
    // 읽기 주소 (프리페치)
    logic [9:0] rd_addr;
    assign rd_addr = (h_cnt == H_ACTIVE-1) ? 10'd0 : h_cnt + 10'd1;
    
    // 라인 버퍼 읽기 (조건부)
    logic [11:0] line0_data, line1_data;
    logic rd_en;
    assign rd_en = de_i && (h_cnt < H_ACTIVE-1);
    
    always_ff @(posedge clk) begin
        if (rd_en) begin
            if (use_buf0_for_line0) begin
                line0_data <= line_buffer0[rd_addr];
                line1_data <= line_buffer1[rd_addr];
            end else begin
                line0_data <= line_buffer1[rd_addr];
                line1_data <= line_buffer0[rd_addr];
            end
        end
    end
    
    // 라인 버퍼 쓰기 (현재 픽셀)
    logic [11:0] pixel_packed;
    assign pixel_packed = {pixel_r_i, pixel_g_i, pixel_b_i};
    
    always_ff @(posedge clk) begin
        if (de_i) begin
            if (use_buf0_for_line0)
                line_buffer1[h_cnt] <= pixel_packed;
            else
                line_buffer0[h_cnt] <= pixel_packed;
        end
    end
    
    // 3x3 윈도우 업데이트 (전력 최적화)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w00 <= '0; w01 <= '0; w02 <= '0;
            w10 <= '0; w11 <= '0; w12 <= '0;
            w20 <= '0; w21 <= '0; w22 <= '0;
        end else if (de_i) begin
            // 시프트
            w02 <= w01; w01 <= w00; w00 <= line0_data;
            w12 <= w11; w11 <= w10; w10 <= line1_data;
            w22 <= w21; w21 <= w20; w20 <= pixel_packed;
        end
    end
    
    // 간단한 3x3 박스 필터 (전력 최적화)
    // 모든 픽셀 동일 가중치로 평균
    logic [6:0] sum_r, sum_g, sum_b;
    
    always_comb begin
        // R 채널 (상위 4비트씩 추출하여 합산)
        sum_r = w00[11:8] + w01[11:8] + w02[11:8] +
                w10[11:8] + w11[11:8] + w12[11:8] +
                w20[11:8] + w21[11:8] + w22[11:8];
        
        // G 채널
        sum_g = w00[7:4] + w01[7:4] + w02[7:4] +
                w10[7:4] + w11[7:4] + w12[7:4] +
                w20[7:4] + w21[7:4] + w22[7:4];
        
        // B 채널
        sum_b = w00[3:0] + w01[3:0] + w02[3:0] +
                w10[3:0] + w11[3:0] + w12[3:0] +
                w20[3:0] + w21[3:0] + w22[3:0];
    end
    
    // 나누기 9를 근사 (×7/64 ≈ /9.14)
    logic [3:0] filtered_r, filtered_g, filtered_b;
    logic [9:0] mult_r, mult_g, mult_b;
    
    always_comb begin
        mult_r = sum_r * 10'd7;  // 7배
        mult_g = sum_g * 10'd7;
        mult_b = sum_b * 10'd7;
        
        filtered_r = mult_r[9:6];  // ÷64
        filtered_g = mult_g[9:6];
        filtered_b = mult_b[9:6];
    end
    
    // 출력 파이프라인 (최소화)
    logic [2:0] de_dly;
    logic [3:0] r_out, g_out, b_out;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_dly <= '0;
            h_sync_o <= 1'b1;
            v_sync_o <= 1'b1;
            r_out <= '0;
            g_out <= '0;
            b_out <= '0;
        end else begin
            // 타이밍 신호
            de_dly <= {de_dly[1:0], de_i};
            h_sync_o <= h_sync_i;  // 직접 연결
            v_sync_o <= v_sync_i;  // 직접 연결
            
            // 픽셀 데이터
            if (filter_en && (v_phase == 2'd2) && (h_cnt >= 2)) begin
                r_out <= filtered_r;
                g_out <= filtered_g;
                b_out <= filtered_b;
            end else begin
                r_out <= w11[11:8];  // 중앙 픽셀
                g_out <= w11[7:4];
                b_out <= w11[3:0];
            end
        end
    end
    
    // 최종 출력
    assign de_o = de_dly[2];
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_r_o <= '0;
            pixel_g_o <= '0;
            pixel_b_o <= '0;
        end else if (de_dly[2]) begin
            pixel_r_o <= r_out;
            pixel_g_o <= g_out;
            pixel_b_o <= b_out;
        end else begin
            pixel_r_o <= '0;
            pixel_g_o <= '0;
            pixel_b_o <= '0;
        end
    end

endmodule