`timescale 1ns / 1ps

module ImageRom (
    input  logic [9:0] x_pixel,
    input  logic [8:0] y_pixel,
    input  logic       DE,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    logic [$clog2(76800)-1:0] image_addr;
    logic [15:0] image_data;  // RGB565 => 16'brrrrr_gggggg_bbbbb

    assign image_addr = 320 * y_pixel + x_pixel;

    always_comb begin
        if ((x_pixel < 320) && (y_pixel < 240) && DE) begin
            {red_port, green_port, blue_port} = {
            image_data[15:12], image_data[10:7], image_data[4:1]
            // => RGB444로 변환하기 위해 하위 비트를 버려서 값 추출
        };
        end else begin
            {red_port, green_port, blue_port} = {4'b0, 4'b0, 4'b0};
        end
        
    end


    image_rom U_ROM (
        .addr(image_addr),
        .data(image_data)
    );


endmodule

module image_rom (
    input  logic [$clog2(76800)-1:0] addr,
    output logic [             15:0] data
);

    logic [15:0] rom[0:(320*240)-1]; // 한 프레임을 넣기 위한 메모리 공간

    initial begin
        $readmemh("Lenna.mem", rom);
    end

    assign data = rom[addr];  // 주소 들어가면 데이터 나옴

endmodule

// `timescale 1ns / 1ps

// module ImageRom (
//     input  logic [9:0] x_pixel,
//     input  logic [9:0] y_pixel,
//     input  logic       DE,
//     output logic [3:0] red_port,
//     output logic [3:0] green_port,
//     output logic [3:0] blue_port
// );

//     logic [16:0] image_addr; 
//     logic [15:0] image_data;
//     //RGB565 => 16'b rrrrr gggggg bbbbb (green만 6bit, 나머지는 5bit)
//     //RGB444로 변경 : 상위bit만 취하고 나머지는 버림.

//     assign image_addr = 320 * y_pixel + x_pixel;
//     assign {red_port, green_port, blue_port} = {
//         image_data[15:12], image_data[10:7], image_data[4:1]
//     };
//     //data 추출하기 (RGB565 -> RGB444)

//     image_rom U_ROM (
//         .addr(image_addr), 
//         .data(image_data)  //rgb port와 연결
//     );

// endmodule

// //640 * 480 = 372,000 -> 19bit
// module image_rom (
//     input  logic [16:0] addr,
//     output logic [15:0] data
// );

//     logic [15:0] rom[0:320*240 - 1];

//     initial begin
//             $readmemh("Lenna.mem", rom); //read한 값을 rom에 넣기
//     end
//     assign data = rom[addr];

// endmodule