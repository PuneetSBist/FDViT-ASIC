module downsample #(
    parameter int stride_q8_8 = 369, // Default stride value (1.444 * 256 = 369.664) ROUND DOWN OR RISK OUT OF BOUNDS
    parameter int hin = 27,
    parameter int hout = 19
)(
    input logic [7:0] ifmap [0:hin-1][0:hin-1],
    output logic [7:0] ofmap [0:hout-1][0:hout-1]
);

    genvar i, j;
    generate 
        for (i = 0; i < hout; i++) begin
            for (j = 0; j < hout; j++) begin : bilinear_block
                localparam int floor_ph = (stride_q8_8 * i) >> 8; // Integer part of stride * i
                localparam int ceil_ph = floor_ph + 1; // Ceiling of stride * i
                localparam int floor_pw = (stride_q8_8 * j) >> 8; // Integer part of stride * j
                localparam int ceil_pw = floor_pw + 1; // Ceiling of stride * j

                logic [7:0] a1, a2, a3, a4;
                assign a1 = ifmap[ceil_ph][ceil_pw];    // Top right
                assign a2 = ifmap[ceil_ph][floor_pw];   // Top left
                assign a3 = ifmap[floor_ph][ceil_pw];   // Bottom right
                assign a4 = ifmap[floor_ph][floor_pw];  // Bottom left

                logic [7:0] v_output; // Interpolated output

                bilinear_interpolation u_bilinear_interpolation (
                    .x((stride_q8_8 * j) & 8'hFF), // Fractional part of stride * j
                    .y((stride_q8_8 * i) & 8'hFF), // Fractional part of stride * i
                    .a1(a1),                   // Top right
                    .a2(a2),                   // Top left
                    .a3(a3),                   // Bottom right
                    .a4(a4),                   // Bottom left
                    .v(v_output)               // Interpolated output
                );

                assign ofmap[i][j] = v_output;
            end
        end
    endgenerate

endmodule