`timescale 1ns / 1ps

// module frame_buffer (
//     // write side
//     input  logic                     wclk,
//     input  logic                     we,
//     input  logic [$clog2(76800)-1:0] wAddr,
//     input  logic [             15:0] wData,
//     // read side
//     input  logic                     rclk,
//     input  logic                     oe, // output enable (read enable)
//     input  logic [$clog2(76800)-1:0] rAddr,
//     output logic [             15:0] rData
// );

//     logic [15:0] mem[0:(320*240) - 1];

//     // write side
//     always_ff @(posedge wclk) begin : write_side
//         if (we) begin
//             mem[wAddr] <= wData;
//         end
//     end

//     // read side
//     always_ff @( posedge rclk ) begin : read_side
//         if (oe) begin
//             rData <= mem[rAddr];
//         end
//     end


// endmodule

module frame_buffer (
    // write side
    input  logic                     wclk,
    input  logic                     we,
    input  logic [$clog2(19200)-1:0] wAddr,  // 160*120 = 19200
    input  logic [             15:0] wData,
    // read side
    input  logic                     rclk,
    input  logic                     oe,
    input  logic [$clog2(19200)-1:0] rAddr,  // 160*120 = 19200
    output logic [             15:0] rData
);

    logic [15:0] mem[0:(160*120) - 1];  // 메모리 크기 변경

    // write side
    always_ff @(posedge wclk) begin : write_side
        if (we) begin
            mem[wAddr] <= wData;
        end
    end

    // read side
    always_ff @( posedge rclk ) begin : read_side
        if (oe) begin
            rData <= mem[rAddr];
        end
    end

endmodule