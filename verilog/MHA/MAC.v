`timescale 1ns / 1ps

module MAC #(parameter bit_width = 8,
             depth = 4,
             multiply_width = 2*bit_width,
             READ_WEIGHT_DATA = 1,
             acc_width = multiply_width + depth - 1) (
    clk,
    reset, 
    control,
    acc_in,     //Last row accumulator
    data_in,    //Feature in
    weight_in,  //Weight in while control =1
    acc_out,    //acc out for next row
    data_out,   //last cycle data_in for next column MAC
    weight_out  //last cycle weight to be propogated to next row MAC
    );
     
    input clk;
    input reset;
    input control; // control signal used to indidate if it is weight loading or not
    input [acc_width-1:0] acc_in; // accumulation in
    input [bit_width-1:0] data_in;   // data in
    input [bit_width-1:0] weight_in;   // weight in
    output [acc_width-1:0] acc_out;  // accumulation out
    output [bit_width-1:0] data_out; // data out
    output [bit_width-1:0] weight_out; // weight out

    // implement your MAC Unit below
    reg [bit_width-1:0] memory = 0;
    reg [bit_width-1:0] feat_memory = 0;
    reg [acc_width-1:0] reg_acc;

    wire [acc_width-1:0] acc_wire;
    wire [multiply_width - 1:0]multiply;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            memory <= {bit_width{1'b0}};
        end else begin
        //Read Weight and reset other memory
            if (control == READ_WEIGHT_DATA) begin
                memory <= weight_in;
                feat_memory <= 0;
                reg_acc <= 0;
            end
            else begin
                feat_memory <= data_in;
                reg_acc <= acc_wire;
            end
        end
    end

    assign multiply = (memory * feat_memory);
    //assign multiply = (control == READ_WEIGHT_DATA) ? 0 : (memory * feat_memory);
    //assign weight_data_out = (control == READ_WEIGHT_DATA) ? memory : feat_memory;
    assign weight_out = memory;
    assign data_out = feat_memory;
    assign acc_out = reg_acc;
    adder a_inst(multiply, acc_in, acc_wire);
    //mixed_adder a_inst(multiply, reg_acc, acc_out);
endmodule
