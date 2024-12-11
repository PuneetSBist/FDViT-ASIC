module downsample #(
    parameter real stride = 1.444, // Default stride value
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
                localparam int floor_ph = $floor(stride * i);
                localparam int ceil_ph = $ceil(stride * i);
                localparam int floor_pw = $floor(stride * j);
                localparam int ceil_pw = $ceil(stride * j);

                logic [7:0] a1, a2, a3, a4;
                assign a1 = ifmap[ceil_ph][ceil_pw];    // Top right
                assign a2 = ifmap[ceil_ph][floor_pw];   // Top left
                assign a3 = ifmap[floor_ph][ceil_pw];   // Bottom right
                assign a4 = ifmap[floor_ph][floor_pw];  // Bottom left

                logic [7:0] v_output; // Interpolated output

                bilinear_interpolation u_bilinear_interpolation (
                    .x(stride * j - floor_pw), // x offset within the cell
                    .y(stride * i - floor_ph), // y offset within the cell
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