`timescale 1ns / 1ps

module tb_gaussian_filter_simple();
    
    reg clk;
    reg rst;
    reg start_btn;
    reg [7:0] sw;
    
    wire [7:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    
    // DUT 인스턴스
    gaussian_filter_basys3_simple dut (
        .clk(clk),
        .rst(rst),
        .start_btn(start_btn),
        .sw(sw),
        .led(led),
        .seg(seg),
        .an(an)
    );
    
    // 클록 생성 (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 테스트 시퀀스
    initial begin
        // 초기화
        rst = 1;
        start_btn = 0;
        sw = 8'b00000001; // 3x3 커널 선택
        
        // 리셋 해제
        #100 rst = 0;
        #100;
        
        // 필터링 시작
        start_btn = 1;
        #50;
        start_btn = 0;
        
        // 처리 완료까지 대기
        wait(led[1] == 1);
        #1000;
        
        $display("가우시안 필터 테스트 완료");
        $finish;
    end
    
    // 상태 모니터링
    always @(posedge clk) begin
        if (led[0]) begin
            $display("처리 중... 픽셀 카운트: %d", led[7:2]);
        end
        if (led[1]) begin
            $display("처리 완료!");
        end
    end
    
endmodule
