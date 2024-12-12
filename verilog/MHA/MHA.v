`timescale 1ns / 1ps

//Block dim:	64,	92,	126,	184,	260
//Head     :	 2,	 4,	  6,	  8,	 10
//Mat Mul  : 	32, 	23,  	 21,	 23, 	 26
//Spatial  :	27,	19,	 14,  	 10,	  7
//QKV Cal  : 3*Block dim
//QK MatMul:   729,	361,	196,	100,	 49
//Blk1 : (4 cycle(192 Weight) + 27X27 cycle(4 feat)) X 64/4 times for out channel
//Only use 12 PE block out of 16

module MHA #(parameter bit_width = 8,
             spatial = 27,
             channel = 64,
             systolic_depth = 4,
             //Since each block have dimesnion of 64/2,92/3,126/4,184/6,260/9
             systolic_column = 16,
             pe_blk_count = 16,
             multiply_width = 2*bit_width,
             acc_width = multiply_width + systolic_depth - 1,

             encoder_block = 2,

             //SRAM row address row*2, 2 for storing each col in 2 row
             qkv_wt_sram_row_count = channel,
             qkv_wt_sram_col_count = channel*3,
             qkv_wt_sram_row_width = qkv_wt_sram_col_count*bit_width,


             patch_sram_col_count = 4,
             patch_sram_row_count = spatial*spatial*channel/patch_sram_col_count,
             patch_sram_row_width = patch_sram_col_count*bit_width,

             qkv_wt_outer_loop = qkv_wt_sram_row_count/systolic_depth,
             qkv_wt_inner_loop = systolic_depth,
             qkv_feat_inner_loop = spatial*spatial)

// Systolic Array top level module. 
(
    clk,
    reset
    );

    localparam actual_width = 21; //acc_width(for 4 channel) for 64 channel
    localparam pe_control_width = $clog2(pe_blk_count);
    localparam qkv_wt_sram_addr_width = $clog2(qkv_wt_sram_row_count);
    localparam qkv_act_sram_addr_width = $clog2(16'h9000); //0x300*16*3
    localparam patch_sram_addr_width = $clog2(patch_sram_row_count);
    //localparam actual_addr_width = (qkv_wt_sram_addr_width > patch_sram_addr_width) ? qkv_wt_sram_addr_width: patch_sram_addr_width;
    localparam actual_addr_width = (qkv_act_sram_addr_width > patch_sram_addr_width) ? qkv_act_sram_addr_width : patch_sram_addr_width;

    input clk;
    input reset;

    //wire [pe_control_width-1:0]control; 
    wire [patch_sram_row_width-1:0] data_arr;
    wire [qkv_wt_sram_row_width-1:0] wt_arr;
    wire [acc_width*systolic_column*pe_blk_count-1:0] acc_out;

    wire [actual_addr_width-1:0] addr;      // Address (192 addresses)
    wire [3*16*actual_addr_width-1:0] read_addr_qkv;  // Address (27X27X16=729X16 addresses)
    reg [3*16*actual_addr_width-1:0] write_addr_qkv;  // Address (27X27X16=729X16 addresses)
    wire is_wt, qkv_write, qkv_read, is_read, done;
    wire [bit_width*systolic_depth*pe_blk_count-1:0] pe_blk_data_in;
    wire [bit_width*systolic_column*pe_blk_count-1:0] pe_blk_wt_in;

    //Assuming each row sram contains 192 weight of qkv op channel
    //Distribute 192 (instead of 256) weight into 16 pe block of 16 cols
    genvar idx;
    assign pe_blk_wt_in[qkv_wt_sram_row_width-1:0] = wt_arr;

    generate
        for (idx = 12; idx < pe_blk_count; idx = idx+1) begin : WEIGHT_PARTITION_NULL
            assign pe_blk_wt_in[bit_width*systolic_column*(idx+1)-1:bit_width*systolic_column*idx] = 0;
        end
    endgenerate

    //data_arr from SRAM contains per token 4 channel, so schedule as:
    //cycle 0:tok0ch3, 1:tok1ch3 tok0ch2, 2:tok2ch3 tok1ch2 tok0ch1 so on
    Staging_Input inp_schedule(clk, reset, data_arr, pe_blk_data_in[bit_width*systolic_depth-1:0]);
    //Share same input for all PE blocks, so init latency reduces to 16
    generate
        for (idx = 1; idx < pe_blk_count; idx = idx+1) begin
            assign pe_blk_data_in[bit_width*systolic_depth*(idx+1)-1:bit_width*systolic_depth*idx] = pe_blk_data_in[bit_width*systolic_depth-1:0];
        end
    endgenerate

    //weight SRAM #row=64, row data=192byte (64XQKV) OP channel/IP channel
    //is_wt true starting 4(row) cycle, false 27X27(token) cycle + wait 16
    //cycle(for act propogation)
    sram #(.row_count(qkv_wt_sram_row_count), .col_count(qkv_wt_sram_col_count), .bit_width(bit_width),
           .addr_width(qkv_wt_sram_addr_width), .row_width(qkv_wt_sram_row_width))
        sram_qkv_wt(.clk(clk), .we(1'b0), .rd_en(is_wt&is_read),
                    .addr(addr[qkv_wt_sram_addr_width-1:0]), .din({qkv_wt_sram_row_width{1'b0}}), .dout(wt_arr[qkv_wt_sram_row_width-1:0]));

    // Fetch from Input SRAM #row=27X27X16, row data=4byte
    sram #(.row_count(patch_sram_row_count), .col_count(patch_sram_col_count), .bit_width(bit_width),
           .addr_width(patch_sram_addr_width), .row_width(patch_sram_row_width))
        sram_data_inp(.clk(clk), .we(1'b0), .rd_en(!is_wt&is_read),
                    .addr(addr[patch_sram_addr_width-1:0]), .din(0), .dout(data_arr[patch_sram_row_width-1:0]));

    //is_wt set first 4 cycle(wt loading), than false for 27*27+16+3 cycles
    //is_read enable during 4(wt load) + 27*27(input read), reset 16+3
    MHA_fsm #(.outer_loop(qkv_wt_outer_loop), .inner_loop_1(qkv_wt_inner_loop),
              .inner_loop_2(qkv_feat_inner_loop), .addr_width(actual_addr_width),
              .pe_control_width(pe_control_width))
        state_m (clk, reset, is_wt, is_read, qkv_write, qkv_read,
                 addr, read_addr_qkv,/*control,*/ done);


    //QKV cycle -> (4 weight load + 27X27 IP load + 16 wait)/per 4 channel * 16
    PE_Blocks #(.mode(3'b100)) pe_blocks (clk, reset, is_wt, pe_blk_data_in, pe_blk_wt_in, acc_out);
    //OP Wait first (4 Wt+ 3Cycle) then partial acc of all channel per cycle 
    //Each 4 channel save together than after x300 memeory


    wire [actual_width*systolic_column*12-1:0] sram_acc_r;
    wire [actual_width*systolic_column*12-1:0] sram_acc_w;

    // Fetch from weight SRAM #row=64, row data=192byte
    sram_multp_addr#(.row_count(12'h300 * 16 * 3), .col_count(4), .bit_width(actual_width),
           .addr_width(actual_addr_width), .row_width(actual_width*4))
        sram_qkv_val(.clk(clk), .we(qkv_write), .rd_en(qkv_read),
                   .r_addr_qkv(read_addr_qkv), .addr_qkv(write_addr_qkv), .din(sram_acc_w), .dout(sram_acc_r));
                   //.addr(addr_qkv), .din(acc_out[11:0]), .dout(0));

    always @(posedge clk or posedge reset) begin
        write_addr_qkv <= read_addr_qkv;
    end

    Accumulator #(.acc_width(acc_width), .actual_width(actual_width),
                  .systolic_column(systolic_column), .pe_blk_count(12))
                  accum(acc_out[acc_width*systolic_column*12-1:0], sram_acc_r, sram_acc_w);


    //Sram_Store();
    //QK_Value();
    //V_lepe();
    //Sram_Store2();
    //Linear();
    //adder_RNN();
    //Sram_Store3();
    //MLP0();
    //Sram_Store4();
    //MLP1();
    //adder_RNN2();
    //Sram_Store5();

endmodule
