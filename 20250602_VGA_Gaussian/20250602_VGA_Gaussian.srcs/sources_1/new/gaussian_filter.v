`timescale 1ns / 1ps

// module gaussian_filter #(
//     parameter IMG_WIDTH = 32,
//     parameter IMG_HEIGHT = 32,
//     parameter PIXEL_WIDTH = 8,
//     parameter KERNEL_SIZE = 3
// )(
//     input wire clk,
//     input wire rst_n,
//     input wire start,
    
//     input wire [PIXEL_WIDTH-1:0] pixel_in,
//     input wire pixel_valid,
    
//     output reg [PIXEL_WIDTH-1:0] pixel_out,
//     output reg pixel_valid_out,
//     output reg done
// );

//     // 상태 정의
//     localparam IDLE = 2'd0;
//     localparam LOADING = 2'd1;
//     localparam PROCESSING = 2'd2;
//     localparam DONE_STATE = 2'd3;
    
//     reg [1:0] state;
//     reg [15:0] pixel_count;
//     reg [7:0] x_pos, y_pos;
    
//     // 라인 버퍼 (3라인 저장)
//     localparam LINE_BUFFER_SIZE = 3 * IMG_WIDTH;
//     reg [PIXEL_WIDTH-1:0] line_buffer [0:LINE_BUFFER_SIZE-1];
//     reg [15:0] buffer_addr;
    
//     // 3x3 가우시안 커널
//     wire [7:0] kernel [0:8];
//     assign kernel[0] = 8'd1; assign kernel[1] = 8'd2; assign kernel[2] = 8'd1;
//     assign kernel[3] = 8'd2; assign kernel[4] = 8'd4; assign kernel[5] = 8'd2;
//     assign kernel[6] = 8'd1; assign kernel[7] = 8'd2; assign kernel[8] = 8'd1;
    
//     // 컨볼루션 결과
//     reg [19:0] conv_sum;
//     reg [PIXEL_WIDTH-1:0] conv_result;
    
//     // 메인 상태 머신
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             state <= IDLE;
//             pixel_count <= 0;
//             x_pos <= 0;
//             y_pos <= 0;
//             buffer_addr <= 0;
//             pixel_out <= 0;
//             pixel_valid_out <= 0;
//             done <= 0;
//         end else begin
//             case (state)
//                 IDLE: begin
//                     if (start) begin
//                         state <= LOADING;
//                         pixel_count <= 0;
//                         x_pos <= 1;
//                         y_pos <= 1;
//                         buffer_addr <= 0;
//                         done <= 0;
//                     end
//                     pixel_valid_out <= 0;
//                 end
                
//                 LOADING: begin
//                     if (pixel_valid) begin
//                         line_buffer[buffer_addr] <= pixel_in;
//                         buffer_addr <= (buffer_addr + 1) % LINE_BUFFER_SIZE;
//                         pixel_count <= pixel_count + 1;
                        
//                         // 처음 3라인이 로드되면 처리 시작
//                         if (pixel_count >= 3 * IMG_WIDTH - 1) begin
//                             state <= PROCESSING;
//                         end
//                     end
//                 end
                
//                 PROCESSING: begin
//                     // 가우시안 필터 적용
//                     apply_gaussian_filter();
//                     pixel_out <= conv_result;
//                     pixel_valid_out <= 1;
                    
//                     // 다음 픽셀 위치로 이동
//                     if (x_pos < IMG_WIDTH - 2) begin
//                         x_pos <= x_pos + 1;
//                     end else begin
//                         x_pos <= 1;
//                         if (y_pos < IMG_HEIGHT - 2) begin
//                             y_pos <= y_pos + 1;
//                         end else begin
//                             state <= DONE_STATE;
//                         end
//                     end
//                 end
                
//                 DONE_STATE: begin
//                     done <= 1;
//                     pixel_valid_out <= 0;
//                 end
                
//                 default: state <= IDLE;
//             endcase
//         end
//     end
    
//     // 가우시안 필터 적용 태스크
//     task apply_gaussian_filter;
//         integer ki, kj;
//         integer buf_idx;
//         reg [PIXEL_WIDTH-1:0] pixel_val;
        
//         begin
//             conv_sum = 0;
            
//             // 3x3 윈도우에 대해 컨볼루션 수행
//             for (ki = 0; ki < 3; ki = ki + 1) begin
//                 for (kj = 0; kj < 3; kj = kj + 1) begin
//                     // 라인 버퍼에서 픽셀 읽기
//                     buf_idx = ((y_pos + ki - 1) % 3) * IMG_WIDTH + (x_pos + kj - 1);
//                     pixel_val = line_buffer[buf_idx];
                    
//                     // 커널과 곱셈 후 누적
//                     conv_sum = conv_sum + (pixel_val * kernel[ki * 3 + kj]);
//                 end
//             end
            
//             // 정규화 (16으로 나누기)
//             conv_result = conv_sum >> 4;
//         end
//     endtask
    
// endmodule

module gaussian_filter_pipeline #(
    parameter IMG_WIDTH = 32,
    parameter IMG_HEIGHT = 32,
    parameter PIXEL_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    
    input wire [PIXEL_WIDTH-1:0] pixel_in,
    input wire pixel_valid_in,
    
    output reg [PIXEL_WIDTH-1:0] pixel_out,
    output reg pixel_valid_out
);

    // 슬라이딩 윈도우 (3x3)
    reg [PIXEL_WIDTH-1:0] window [0:8];
    
    // 라인 버퍼 (2라인만 필요)
    reg [PIXEL_WIDTH-1:0] line1 [0:IMG_WIDTH-1];
    reg [PIXEL_WIDTH-1:0] line2 [0:IMG_WIDTH-1];
    
    // 파이프라인 단계
    reg [15:0] mult_results [0:8];
    reg [19:0] add_result;
    reg [PIXEL_WIDTH-1:0] final_result;
    
    // 가우시안 커널
    wire [7:0] kernel [0:8];
    assign kernel[0] = 1; assign kernel[1] = 2; assign kernel[2] = 1;
    assign kernel[3] = 2; assign kernel[4] = 4; assign kernel[5] = 2;
    assign kernel[6] = 1; assign kernel[7] = 2; assign kernel[8] = 1;
    
    reg [7:0] col_count, row_count;
    reg [2:0] pipeline_valid;
    
    integer i;
    
    // 라인 버퍼 및 윈도우 업데이트
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_count <= 0;
            row_count <= 0;
            pipeline_valid <= 0;
            
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line1[i] <= 0;
                line2[i] <= 0;
            end
            
            for (i = 0; i < 9; i = i + 1) begin
                window[i] <= 0;
            end
        end else if (enable && pixel_valid_in) begin
            // 라인 버퍼 시프트
            for (i = 0; i < IMG_WIDTH-1; i = i + 1) begin
                line1[i] <= line1[i+1];
                line2[i] <= line2[i+1];
            end
            
            // 새 픽셀 입력
            line1[IMG_WIDTH-1] <= line2[IMG_WIDTH-1];
            line2[IMG_WIDTH-1] <= pixel_in;
            
            // 3x3 윈도우 업데이트
            window[0] <= line1[0]; window[1] <= line1[1]; window[2] <= line1[2];
            window[3] <= line2[0]; window[4] <= line2[1]; window[5] <= line2[2];
            window[6] <= pixel_in;  // 현재 라인의 첫 픽셀은 입력값
            window[7] <= line2[IMG_WIDTH-2]; // 임시값
            window[8] <= line2[IMG_WIDTH-1];
            
            // 카운터 업데이트
            if (col_count < IMG_WIDTH - 1) begin
                col_count <= col_count + 1;
            end else begin
                col_count <= 0;
                if (row_count < IMG_HEIGHT - 1) begin
                    row_count <= row_count + 1;
                end
            end
            
            // 파이프라인 유효 신호
            pipeline_valid <= {pipeline_valid[1:0], 1'b1};
        end
    end
    
    // 파이프라인 단계 1: 곱셈
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 9; i = i + 1) begin
                mult_results[i] <= 0;
            end
        end else if (enable) begin
            for (i = 0; i < 9; i = i + 1) begin
                mult_results[i] <= window[i] * kernel[i];
            end
        end
    end
    
    // 파이프라인 단계 2: 덧셈
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            add_result <= 0;
        end else if (enable) begin
            add_result <= mult_results[0] + mult_results[1] + mult_results[2] +
                         mult_results[3] + mult_results[4] + mult_results[5] +
                         mult_results[6] + mult_results[7] + mult_results[8];
        end
    end
    
    // 파이프라인 단계 3: 정규화 및 출력
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_result <= 0;
            pixel_out <= 0;
            pixel_valid_out <= 0;
        end else if (enable) begin
            final_result <= add_result >> 4; // /16
            pixel_out <= final_result;
            pixel_valid_out <= pipeline_valid[2] && (col_count >= 2) && (row_count >= 2);
        end
    end
    
endmodule