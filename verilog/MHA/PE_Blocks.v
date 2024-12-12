
module PE_Blocks #(parameter bit_width = 8,
             systolic_depth = 4,
             //Since each block have dimesnion of 64/2,92/3,126/4,184/6,260/9
             systolic_column = 16,
             multiply_width = 2*bit_width,
             acc_width = multiply_width + systolic_depth - 1,
             mode = 3'b100,

             pe_blk_count = 16)
(
    clk,
    is_wt,
    data_in,
    wt_in,
    acc_out
    );

    input clk;
    input is_wt;
    input [bit_width*systolic_depth-1:0] data_in[pe_blk_count-1:0];
    input [bit_width*systolic_column-1:0] wt_in[pe_blk_count-1:0];
    output [acc_width*systolic_column-1:0] acc_out[pe_blk_count-1:0];

    wire [acc_width*systolic_column-1:0] acc_out_unstage[pe_blk_count-1:0];

    wire [bit_width*systolic_depth-1:0] pe_blk_data_in[pe_blk_count-1:0];
    wire [bit_width*systolic_depth-1:0] pe_blk_data_out[pe_blk_count-1:0];


    // Define PE Modes
    // Each PE have own data
    localparam PE_SHARE_NONE	= 3'b000;
    // Two PE share data
    localparam PE_SHARE_TWO	= 3'b001;
    // Four PE share data and so on
    localparam PE_SHARE_FOUR	= 3'b010;
    localparam PE_SHARE_EIGHT	= 3'b011;
    localparam PE_SHARE_ALL	= 3'b100;


    Staging_Mem #(.acc_width(acc_width), .systolic_column(systolic_column),
                 .pe_blk_count(pe_blk_count)) stage_acc(.clk(clk), .acc_unstage(acc_out_unstage),
                                                        .acc_stage(acc_out));

    genvar peIdx;
    generate
        for (peIdx = 0; peIdx < pe_blk_count; peIdx = peIdx+1) begin : PE_DATA_DISTR
            case (mode)
                PE_SHARE_ALL: begin
                    assign pe_blk_data_in[peIdx] = data_in[0];
                end
            /*
            PE_SHARE_EIGHT: begin
                for (peIdx = 0; peIdx < pe_blk_count/2; peIdx = peIdx+1) begin
                    assign pe_blk_data_in[peIdx] = data_in[0];
                end
                for (peIdx = pe_blk_count/2; peIdx < pe_blk_count; peIdx = peIdx+1) begin
                    assign pe_blk_data_in[peIdx] = data_in[1];
                end
            end
            PE_SHARE_FOUR: begin
                for (peIdx = 0; peIdx < pe_blk_count/4; peIdx = peIdx+1) begin
                    assign pe_blk_data_in[peIdx] = data_in[0];
                end
                for (peIdx = pe_blk_count/4; peIdx < pe_blk_count/2; peIdx = peIdx+1) begin
                    assign pe_blk_data_in[peIdx] = data_in[1];
                end
                for (peIdx = pe_blk_count/2; peIdx < 3*pe_blk_count/4; peIdx = peIdx+1) begin
                    assign pe_blk_data_in[peIdx] = data_in[2];
                end
                for (peIdx = 3*pe_blk_count/4; peIdx < pe_blk_count; peIdx = peIdx+1) begin
                    assign pe_blk_data_in[peIdx] = data_in[3];
                end
            end
            //PE_SHARE_TWO: begin
            //end
            //PE_SHARE_NONE: default
            */
                default:
                    assign pe_blk_data_in[peIdx] = data_in[peIdx];
            endcase
        end
    endgenerate

    genvar pe_blk;
    generate
    for (pe_blk = 0; pe_blk < pe_blk_count; pe_blk = pe_blk +1) begin : PE_BLOCK
        //clk, control(later clock gating), data_in, //data_out, wt_in, acc_out 
        PE_Inst pe_inst(clk, is_wt,/*control[pe_blk],*/
            pe_blk_data_in[pe_blk], wt_in[pe_blk],
            pe_blk_data_out[pe_blk], acc_out_unstage[pe_blk]);
    end
    endgenerate

endmodule
