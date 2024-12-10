`timescale 1ns / 1ps


module adder #(parameter bit_width = 8,
             depth = 4,
             multiply_width = 2*bit_width,
             acc_width = multiply_width + depth - 1) (
    A, B, sum);

    input [multiply_width -1:0] A;
    input [acc_width -1:0] B;
    output [acc_width -1:0] sum;

    wire [acc_width-1:0] carry;
    assign carry[0] = 0;

    // Adder for multiply_width data
    genvar i;
    generate
        for (i = 0; i < multiply_width; i = i + 1) begin : bit_adder
            assign sum[i] = A[i] ^ B[i] ^ carry[i];
            assign carry[i + 1] = (A[i] & B[i]) | (carry[i] & (A[i] ^ B[i]));
        end
    endgenerate

    // Half adder for rest of MSB bit
    genvar j;
    generate
        for (j = multiply_width; j < acc_width - 1; j = j + 1) begin : bit_counter
            assign sum[j] = B[j] ^ carry[j];
            assign carry[j + 1] = (carry[j] & B[j]);
        end
    endgenerate
    // 1 ^ 1 will never happen, as its overflow condition
    assign sum[acc_width - 1] = B[acc_width - 1] | carry[acc_width - 1];
/*
    assign sum[acc_width-1:multiply_width] = (carry[multiply_width] == 1'b1) ?
                                             B[acc_width-1:multiply_width] + 1'b1:
                                             B[acc_width-1:multiply_width];
 * */

endmodule

