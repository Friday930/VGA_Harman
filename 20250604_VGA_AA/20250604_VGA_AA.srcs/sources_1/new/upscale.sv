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

    // 완전히 원본 그대로 통과 (픽셀화된 업스케일)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_r_o <= '0;
            pixel_g_o <= '0;
            pixel_b_o <= '0;
            de_o <= '0;
            h_sync_o <= 1'b1;
            v_sync_o <= 1'b1;
        end else begin
            // 모든 신호를 그대로 통과
            de_o <= de_i;
            h_sync_o <= h_sync_i;
            v_sync_o <= v_sync_i;
            
            // 원본 RGB 그대로 (계단식 픽셀)
            pixel_r_o <= pixel_r_i;
            pixel_g_o <= pixel_g_i;
            pixel_b_o <= pixel_b_i;
        end
    end

endmodule