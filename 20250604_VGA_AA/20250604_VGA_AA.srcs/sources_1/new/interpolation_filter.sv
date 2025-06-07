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

    // 160개 원본을 640개로 선형보간 (4배 확장)
    logic [11:0] line_buffer[0:639];
    logic [7:0] write_idx;
    logic [9:0] read_idx;
    logic [9:0] x_cnt;
    logic de_prev, writing;
    
    always_ff @(posedge clk) de_prev <= de_i;
    wire line_start = de_i & ~de_prev;
    
    // X 카운터
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= '0;
        end else if (~v_sync_i || line_start) begin
            x_cnt <= '0;
        end else if (de_i) begin
            x_cnt <= x_cnt + 1'b1;
        end
    end

    // 수평 블랭킹에서 라인버퍼 생성 (선형보간)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_idx <= 0;
            writing <= 0;
        end else if (~v_sync_i) begin
            write_idx <= 0;
            writing <= 0;
        end else if (~h_sync_i && !writing) begin
            writing <= 1;
            write_idx <= 0;
        end else if (writing && write_idx < 160) begin
            // 160개 픽셀로 640개 생성 (선형보간)
            logic [9:0] base_addr;
            base_addr = write_idx << 2;  // 4배 확장
            
            // 원본 픽셀 저장
            line_buffer[base_addr] <= {pixel_r_i, pixel_g_i, pixel_b_i};
            
            // 선형보간으로 중간값들 생성
            if (write_idx > 0) begin
                logic [3:0] prev_r, prev_g, prev_b;
                logic [3:0] curr_r, curr_g, curr_b;
                logic [4:0] step1_r, step1_g, step1_b;
                logic [4:0] step2_r, step2_g, step2_b;
                logic [4:0] step3_r, step3_g, step3_b;
                
                prev_r = line_buffer[base_addr-4][11:8];
                prev_g = line_buffer[base_addr-4][7:4];
                prev_b = line_buffer[base_addr-4][3:0];
                curr_r = pixel_r_i;
                curr_g = pixel_g_i;
                curr_b = pixel_b_i;
                
                // 선형보간: prev + (curr-prev) * t
                // t = 1/4, 2/4, 3/4
                step1_r = {1'b0, prev_r} + (({1'b0, curr_r} - {1'b0, prev_r}) >> 2);
                step1_g = {1'b0, prev_g} + (({1'b0, curr_g} - {1'b0, prev_g}) >> 2);
                step1_b = {1'b0, prev_b} + (({1'b0, curr_b} - {1'b0, prev_b}) >> 2);
                
                step2_r = {1'b0, prev_r} + (({1'b0, curr_r} - {1'b0, prev_r}) >> 1);
                step2_g = {1'b0, prev_g} + (({1'b0, curr_g} - {1'b0, prev_g}) >> 1);
                step2_b = {1'b0, prev_b} + (({1'b0, curr_b} - {1'b0, prev_b}) >> 1);
                
                step3_r = {1'b0, prev_r} + ((({1'b0, curr_r} - {1'b0, prev_r}) * 3) >> 2);
                step3_g = {1'b0, prev_g} + ((({1'b0, curr_g} - {1'b0, prev_g}) * 3) >> 2);
                step3_b = {1'b0, prev_b} + ((({1'b0, curr_b} - {1'b0, prev_b}) * 3) >> 2);
                
                line_buffer[base_addr-3] <= {step1_r[3:0], step1_g[3:0], step1_b[3:0]};
                line_buffer[base_addr-2] <= {step2_r[3:0], step2_g[3:0], step2_b[3:0]};
                line_buffer[base_addr-1] <= {step3_r[3:0], step3_g[3:0], step3_b[3:0]};
            end
            
            write_idx <= write_idx + 1;
        end else if (write_idx >= 160) begin
            writing <= 0;
        end
    end

    // 읽기: 640개 그대로 (1:1 매핑)
    always_comb begin
        if (de_i && x_cnt < 640) begin
            read_idx = x_cnt;  // 1:1 매핑
        end else begin
            read_idx = 0;
        end
    end

    logic [11:0] read_data;
    always_ff @(posedge clk) begin
        read_data <= line_buffer[read_idx];
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
            de_o <= de_i;
            h_sync_o <= h_sync_i;
            v_sync_o <= v_sync_i;
            
            if (de_i) begin
                pixel_r_o <= read_data[11:8];
                pixel_g_o <= read_data[7:4];
                pixel_b_o <= read_data[3:0];
            end else begin
                pixel_r_o <= '0;
                pixel_g_o <= '0;
                pixel_b_o <= '0;
            end
        end
    end

endmodule