
module PE_Inst #(parameter bit_width = 8,
             systolic_depth = 4,
             //Since each block have dimesnion of 64/2,92/3,126/4,184/6,260/9
             systolic_column = 16,
             multiply_width = 2*bit_width,
             acc_width = multiply_width + systolic_depth - 1)
(
    clk,
    is_wt,
    data_in,
    wt_in,
    data_out,
    acc_out
    );

    input clk;
    input is_wt;
    input [bit_width*systolic_depth-1:0] data_in;
    input [bit_width*systolic_column-1:0] wt_in;
    output [bit_width*systolic_depth-1:0] data_out;
    output reg[acc_width*systolic_column-1:0] acc_out;

    wire [bit_width*(systolic_depth+1)*systolic_column-1:0] weight_in;
    assign weight_in[bit_width*systolic_column-1:0] = wt_in;
    wire [acc_width*(systolic_depth+1)*systolic_column-1:0] noc_row;
    assign noc_row[acc_width*systolic_column-1:0] = 0;

    genvar mac_row;
    generate
    for (mac_row = 0; mac_row < systolic_depth; mac_row = mac_row +1) begin : MAC_ROW
        MAC_Row row(clk, is_wt,
            data_in[bit_width*(mac_row+1)-1:bit_width*mac_row],
            weight_in[bit_width*systolic_column*(mac_row+1)-1:bit_width*systolic_column*mac_row],
            noc_row[acc_width*systolic_column*(mac_row+1)-1:acc_width*systolic_column*mac_row],
            weight_in[bit_width*systolic_column*(mac_row+2)-1:bit_width*systolic_column*(mac_row+1)],
            noc_row[acc_width*systolic_column*(mac_row+2)-1:acc_width*systolic_column*(mac_row+1)]);
    end
    endgenerate


endmodule




module MAC_Row #(parameter bit_width = 8,
             depth = 4,
             size = 16,
             multiply_width = 2*bit_width,
             acc_width = multiply_width + depth - 1)
(
    clk,
    control,
    data_in,
    weight_in,
    acc_in, //Commenting not going to save partial sum
    weight_out,
    acc_out    //a+b*c
);
    input clk;
    input control; // control signal used to indidate if it is weight loading or not
    input [bit_width-1:0] data_in;   // weight data in
    input [bit_width*size-1:0] weight_in;
    input [acc_width*size-1:0] acc_in; // accumulation in
    output [bit_width*size-1:0] weight_out;
    output [acc_width*size-1:0] acc_out;

    wire [bit_width*(size+1)-1:0] noc_col;
    assign noc_col[bit_width-1:0] = data_in;

    genvar mac_col;
    generate
        //for (mac_col = 0; mac_col < 1; mac_col = mac_col +1) begin
        for (mac_col = 0; mac_col < size; mac_col = mac_col +1) begin : MAC_UNIT
            MAC mac_unit(clk, control,
                //acc_in
                acc_in[acc_width*(mac_col+1)-1:acc_width*mac_col],
                //data_in
                noc_col[bit_width*(mac_col+1)-1:bit_width*mac_col],
                //weight_in
                weight_in[bit_width*(mac_col+1)-1:bit_width*mac_col],
                acc_out[acc_width*(mac_col+1)-1:acc_width*mac_col],
                //data_out for next column MAC as data_in
                noc_col[bit_width*(mac_col+2)-1:bit_width*(mac_col+1)],
                //weight_out
                weight_out[bit_width*(mac_col+1)-1:bit_width*mac_col]);
        end
    endgenerate
endmodule

