
module Staging_Mem#(parameter acc_width= 8,
                    systolic_column = 16,
                    pe_blk_count = 16)
(
    clk,
    acc_unstage,
    acc_stage
    );

    input clk;
    input [acc_width*systolic_column-1:0] acc_unstage[pe_blk_count-1:0];
    output [acc_width*systolic_column-1:0] acc_stage[pe_blk_count-1:0];

    genvar stagePeIdx;
    generate
        for (stagePeIdx= 0; stagePeIdx < pe_blk_count; stagePeIdx = stagePeIdx+1) begin : STAGING
            Staging_Mem_PE#(.bit_width(acc_width), .systolic_column(systolic_column))
                pe_stage(clk, acc_unstage[stagePeIdx], acc_stage[stagePeIdx]);
        end
    endgenerate
endmodule


module Staging_Mem_PE#(parameter bit_width = 8,
                       systolic_column = 16)
(
    clk,
    data_in,
    data_out
    );

    input clk;
    input [bit_width*systolic_column-1:0] data_in;
    output [bit_width*systolic_column-1:0] data_out;

    genvar stageColIdx;
    generate
        for (stageColIdx= 0; stageColIdx < systolic_column; stageColIdx = stageColIdx+1) begin : STAGING_PE
            Staging_Mem_Col#(.bit_width(bit_width), .stage_depth(stageColIdx))
                pe_stage_col(clk, data_in[bit_width*(stageColIdx+1)-1:bit_width*stageColIdx],
                         data_out[bit_width*(stageColIdx+1)-1:bit_width*stageColIdx]);
        end
    endgenerate
endmodule

module Staging_Input#(parameter bit_width = 8,
                       systolic_row = 4)
(
    clk,
    data_in,
    data_out
    );

    input clk;
    input [bit_width*systolic_row-1:0] data_in;
    output [bit_width*systolic_row-1:0] data_out;

    genvar stageColIdx;
    generate
        for (stageColIdx= 0; stageColIdx < systolic_row; stageColIdx = stageColIdx+1) begin : STAGING_INP
            Staging_Mem_Col#(.bit_width(bit_width), .stage_depth(stageColIdx))
                pe_stage_col(clk, data_in[bit_width*(stageColIdx+1)-1:bit_width*stageColIdx],
                         data_out[bit_width*(stageColIdx+1)-1:bit_width*stageColIdx]);
        end
    endgenerate
endmodule


module Staging_Mem_Col#(parameter bit_width = 8,
                    stage_depth = 16)
(
    clk,
    data_in,
    data_out
    );

    input clk;
    input [bit_width-1:0] data_in;
    output [bit_width-1:0] data_out;

    reg [bit_width-1:0] stage[stage_depth-1:0];
    assign data_out = stage[stage_depth-1];

    genvar stageIdx;
    generate
        for (stageIdx= 0; stageIdx < stage_depth; stageIdx = stageIdx+1) begin : STAGING_COL
            always @(posedge clk) begin
                if (stageIdx == 0) begin
                    stage[stageIdx] <= data_in;
                end else begin
                    stage[stageIdx] <= stage[stageIdx-1];
                end
            end
        end
    endgenerate

endmodule
