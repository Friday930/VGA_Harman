`timescale 1ns / 1ps

module VGA_Controller ();
endmodule

module pixel_clk_gen (
    input  logic clk,
    input  logic reset,
    output logic pclk
);

    logic [1:0] p_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            p_counter <= 0;
            pclk      <= 1'b0;
        end else begin
            if (p_counter == 3) begin
                p_counter <= 0;
                pclk      <= 1'b1;
            end else begin
                p_counter <= p_counter + 1;
                pclk      <= 1'b0;
            end
        end
    end  // 25MHz clk generate

endmodule

module pixel_counter (
    input  logic                   pclk,
    input  logic                   reset,
    output logic [$clog2(800)-1:0] h_counter,
    output logic [$clog2(525)-1:0] v_counter
);

    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(posedge pclk, posedge reset) begin : Horizontal_counter
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge pclk, posedge reset) begin : Vertical_counter
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end

endmodule

module vga_decoder ();

    localparam Visible_area = 640;
    localparam Front_porch = 16;
    localparam Sync_pulse = 96;
    localparam Back_porch = 48;
    localparam Whole_line = 800;

    localparam Visible_area = 480;
    localparam Front_porch = 10;
    localparam Sync_pulse = 2;
    localparam Back_porch = 33;
    localparam Whole_frame = 525;

endmodule
