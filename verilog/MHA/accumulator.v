`timescale 1ns / 1ps


module Accumulator#(parameter acc_width = 2*8+2,
                    actual_width = 21, //acc_width(for 4 channel) for 64 channel
                    systolic_column = 16,
                    pe_blk_count = 16)
(
    A, B, sum);

    input [pe_blk_count*acc_width*systolic_column-1:0] A;
    input [pe_blk_count*actual_width*systolic_column-1:0] B;
    output [pe_blk_count*actual_width*systolic_column-1:0] sum;

    wire [acc_width*systolic_column-1:0] net_A[pe_blk_count-1:0];
    wire [actual_width*systolic_column-1:0] net_B[pe_blk_count-1:0];
    wire [actual_width*systolic_column-1:0] net_sum[pe_blk_count-1:0];

    genvar idx, idx2;
    generate
        for (idx = 0; idx < pe_blk_count; idx = idx+1) begin : ACCUM_RESHAPE
            assign net_A[idx] = A[acc_width*systolic_column*(idx+1)-1:acc_width*systolic_column*idx];
            assign net_B[idx] = B[actual_width*systolic_column*(idx+1)-1:actual_width*systolic_column*idx];
            assign sum[actual_width*systolic_column*(idx+1)-1:actual_width*systolic_column*idx] = net_sum[idx];
        end
    endgenerate

    generate
        for (idx = 0; idx < pe_blk_count; idx = idx+1) begin : ADDER_PEBLK
            for (idx2 = 0; idx2 < systolic_column; idx2 = idx2+1) begin : ADDER_ROW
             adder #(.multiply_width(acc_width), .acc_width(actual_width))
                 add_inst(net_A[idx][acc_width*(idx2+1)-1:acc_width*idx2],
                          net_B[idx][actual_width*(idx2+1)-1:actual_width*idx2],
                          net_sum[idx][actual_width*(idx2+1)-1:actual_width*idx2]);

            end
        end
    endgenerate

endmodule
