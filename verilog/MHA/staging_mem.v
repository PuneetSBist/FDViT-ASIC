
module Staging_Mem#(parameter acc_width= 8,
                    systolic_column = 16,
                    pe_blk_count = 16)
(
    clk,
    reset,
    acc_unstage,
    acc_stage
    );

    input clk;
    input reset;
    input [acc_width*systolic_column*pe_blk_count-1:0] acc_unstage;
    output [acc_width*systolic_column*pe_blk_count-1:0] acc_stage;

    genvar stagePeIdx;
    generate
        for (stagePeIdx= 0; stagePeIdx < pe_blk_count; stagePeIdx = stagePeIdx+1) begin : STAGING
            Staging_Mem_PE#(.bit_width(acc_width), .systolic_column(systolic_column))
                pe_stage(clk, reset,
                         acc_unstage[acc_width*systolic_column*(stagePeIdx+1)-1:acc_width*systolic_column*stagePeIdx],
                         acc_stage[acc_width*systolic_column*(stagePeIdx+1)-1:acc_width*systolic_column*stagePeIdx]);
        end
    endgenerate
endmodule


module Staging_Mem_PE#(parameter bit_width = 8,
                       systolic_column = 16)
(
    clk,
    reset,
    data_in,
    data_out
    );

    input clk;
    input reset;
    input [bit_width*systolic_column-1:0] data_in;
    output [bit_width*systolic_column-1:0] data_out;

    genvar stageColIdx;
    generate
        for (stageColIdx= 0; stageColIdx < systolic_column-1; stageColIdx = stageColIdx+1) begin : STAGING_PE
            Staging_Mem_Col#(.bit_width(bit_width), .stage_depth(systolic_column-stageColIdx-1))
                pe_stage_col(clk, reset, data_in[bit_width*(stageColIdx+1)-1:bit_width*stageColIdx],
                         data_out[bit_width*(stageColIdx+1)-1:bit_width*stageColIdx]);
        end
    endgenerate
    assign data_out[bit_width*16-1:bit_width*15] = data_in[bit_width*16-1:bit_width*15];
endmodule

module Staging_Input#(parameter bit_width = 8,
                       systolic_row = 4)
(
    clk,
    reset,
    data_in,
    data_out
    );

    input clk;
    input reset;
    input [bit_width*systolic_row-1:0] data_in;
    output [bit_width*systolic_row-1:0] data_out;

    genvar stageColIdx;
    generate
        for (stageColIdx= 1; stageColIdx < systolic_row; stageColIdx = stageColIdx+1) begin : STAGING_INP
            Staging_Mem_Col#(.bit_width(bit_width), .stage_depth(stageColIdx))
                pe_stage_col(clk, reset, data_in[bit_width*(stageColIdx+1)-1:bit_width*stageColIdx],
                         data_out[bit_width*(stageColIdx+1)-1:bit_width*stageColIdx]);
        end
    endgenerate
    assign data_out[bit_width-1:0] = data_in[bit_width-1:0];
endmodule


module Staging_Mem_Col#(parameter bit_width = 8,
                    stage_depth = 16)
(
    clk,
    reset,
    data_in,
    data_out
    );

    input clk;
    input reset;
    input [bit_width-1:0] data_in;
    output [bit_width-1:0] data_out;

    reg [bit_width-1:0] stage[stage_depth-1:0];
    assign data_out = stage[stage_depth-1];

    genvar stageIdx;
    generate
        for (stageIdx= 0; stageIdx < stage_depth; stageIdx = stageIdx+1) begin : STAGING_COL
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    stage[stageIdx] <= {bit_width{1'b0}};
                end else begin
                    if (stageIdx == 0) begin
                        stage[stageIdx] <= data_in;
                    end else begin
                        stage[stageIdx] <= stage[stageIdx-1];
                    end
                end
            end
        end
    endgenerate

endmodule
