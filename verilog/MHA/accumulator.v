`timescale 1ns / 1ps


module Accumulator#(parameter acc_width = 2*8+2,
                    actual_width = 21, //acc_width(for 4 channel) for 64 channel
                    systolic_column = 16,
                    pe_blk_count = 16)
(
    A, B, sum);

    input [acc_width*systolic_column-1:0] A[pe_blk_count-1:0];
    input [actual_width*systolic_column-1:0] B[pe_blk_count-1:0];
    output [actual_width*systolic_column-1:0] sum[pe_blk_count-1:0];

    genvar idx, idx2;
    generate
        for (idx = 0; idx < pe_blk_count; idx = idx+1) begin : ADDER_PEBLK
            for (idx2 = 0; idx2 < systolic_column; idx2 = idx2+1) begin : ADDER_ROW
             adder #(.bit_width(acc_width), .acc_width(actual_width))
                 add_inst(A[idx][acc_width*(idx2+1)-1:acc_width*idx2],
                          B[idx][actual_width*(idx2+1)-1:actual_width*idx2],
                          sum[idx][actual_width*(idx2+1)-1:actual_width*idx2]);

            end
        end
    endgenerate

endmodule
