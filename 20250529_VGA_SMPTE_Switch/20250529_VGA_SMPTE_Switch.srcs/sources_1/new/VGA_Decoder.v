`timescale 1ns / 1ps

module VGA_Decoder (
    input  wire                   clk,
    input  wire                   reset,
    output wire                   h_sync,
    output wire                   v_sync,
    output wire                   DE,
    output wire [$clog2(639)-1:0] x_pol,
    output wire [$clog2(479)-1:0] y_pol
);

    wire pclk;
    wire [$clog2(800)-1:0] h_counter;
    wire [$clog2(525)-1:0] v_counter;

    pix_clk_gen U_Pix_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (pclk)
    );

    pix_counter u_Pix_Counter (
        .pclk     (pclk),
        .reset    (reset),
        .h_counter(h_counter),
        .v_counter(v_counter)
    );

    pix_decoder u_Pix_Decoder (
        .h_counter(h_counter),
        .v_counter(v_counter),
        .h_sync   (h_sync),
        .v_sync   (v_sync),
        .DE       (DE),
        .x_pol    (x_pol),
        .y_pol    (y_pol)
    );

endmodule

module pix_clk_gen (
    input  wire clk,
    input  wire reset,
    output reg  pclk
);

    reg [1:0] p_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            p_counter <= 0;
            pclk      <= 0;
        end else begin
            if (p_counter == 3) begin
                p_counter <= 0;
                pclk      <= 1'b1;
            end else begin
                p_counter <= p_counter + 1;
                pclk      <= 0;
            end
        end
    end

endmodule

module pix_counter (
    input wire pclk,
    input wire reset,
    output reg [$clog2(800)-1:0] h_counter,
    output reg [$clog2(525)-1:0] v_counter
);

    localparam H_MAX = 800, V_MAX = 525;

    always @(posedge pclk, posedge reset) begin
        if (reset) begin
            h_counter <= 0;
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

endmodule

module pix_decoder (
    input  wire [$clog2(800)-1:0] h_counter,
    input  wire [$clog2(525)-1:0] v_counter,
    output wire                   h_sync,
    output wire                   v_sync,
    output wire                   DE,
    output wire [$clog2(639)-1:0] x_pol,
    output wire [$clog2(479)-1:0] y_pol
);
    localparam 
        H_Visible_area      = 640,	
        H_Front_porch	    = 16,	
        H_Sync_pulse	    = 96,	
        H_Back_porch	    = 48,	
        H_Whole_line	    = 800,

        V_Visible_area      = 480,	
        V_Front_porch	    = 10,	
        V_Sync_pulse	    = 2,	
        V_Back_porch	    = 33,	
        V_Whole_frame	    = 525;

    assign h_sync = !((h_counter >= (H_Visible_area + H_Front_porch)) && (h_counter < (H_Visible_area + H_Front_porch + H_Sync_pulse)));
    assign v_sync = !((v_counter >= (V_Visible_area + V_Front_porch)) && (v_counter < (V_Visible_area + V_Front_porch + V_Sync_pulse)));

    assign DE = (h_counter < H_Visible_area) && (v_counter < V_Visible_area);
    assign x_pol = DE ? h_counter : 10'bz;
    assign y_pol = DE ? v_counter : 10'bz;


endmodule
