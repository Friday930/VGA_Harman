`timescale 1ns / 1ps

module upscale (
    input  logic       clk,
    input  logic       rst_n,
    
    // 1비트 입력
    input  logic       pixel_1bit_i,
    input  logic       de_i,
    input  logic       h_sync_i,
    input  logic       v_sync_i,
    
    // 4비트 RGB444 출력 (AA 모듈용)
    output logic [3:0] pixel_r_o,
    output logic [3:0] pixel_g_o,
    output logic [3:0] pixel_b_o,
    output logic       de_o,
    output logic       h_sync_o,
    output logic       v_sync_o,
    
    // 색상 선택 (0: 흰색/검정, 1: 빨강/검정, 2: 초록/검정, 3: 파랑/검정)
    input  logic [1:0] color_sel
);

    // RGB 출력
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_r_o <= '0;
            pixel_g_o <= '0;
            pixel_b_o <= '0;
            de_o <= '0;
            h_sync_o <= 1'b1;
            v_sync_o <= 1'b1;
        end else begin
            if (pixel_1bit_i) begin
                // 1비트가 1일 때 색상
                case (color_sel)
                    2'b00: {pixel_r_o, pixel_g_o, pixel_b_o} <= {4'hF, 4'hF, 4'hF};  // 흰색
                    2'b01: {pixel_r_o, pixel_g_o, pixel_b_o} <= {4'hF, 4'h0, 4'h0};  // 빨강
                    2'b10: {pixel_r_o, pixel_g_o, pixel_b_o} <= {4'h0, 4'hF, 4'h0};  // 초록
                    2'b11: {pixel_r_o, pixel_g_o, pixel_b_o} <= {4'h0, 4'h0, 4'hF};  // 파랑
                endcase
            end else begin
                // 1비트가 0일 때는 항상 검정
                pixel_r_o <= 4'h0;
                pixel_g_o <= 4'h0;
                pixel_b_o <= 4'h0;
            end
            de_o <= de_i;
            h_sync_o <= h_sync_i;
            v_sync_o <= v_sync_i;
        end
    end

endmodule