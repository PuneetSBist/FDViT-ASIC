`timescale 1ns / 1ps

//a MAC unit, weight stationary, input data changes (according to stride) so output element obtained, using as multiplier only.

module MAC #(parameter bit_width=8, acc_width=18)(
	input logic clk,
	input logic reset,
	input logic control,			//control signal used to indicate if it is weight loading (control=1) or mac operation
	//input wire [acc_width-1:0] acc_in,	//a, accumulation input, 32 bit
	input logic [bit_width-1:0] data_in,	//x, data input/activation input, 8 bit
	input logic [bit_width-1:0] wt_in,	//w, weight data in, 8 bit
	
	output logic [acc_width-1:0] prod_out	//a+x*w, accumulation out
);
	
	reg [bit_width-1:0] weight;	//stores the weight value
	
	always @(posedge clk) begin
		if (reset) begin
			prod_out <= {(acc_width){1'b0}};
			weight <= {(bit_width){1'b0}};
		end else if (control) begin	//loading weights when control=1
			weight <= wt_in;
			//prod_out <= {(acc_width){1'b0}};
		end else begin			//using input data to perform MAC operation
			//acc_out <= acc_in + (data_in * weight);
			prod_out <= (data_in * weight);
		end
	end

endmodule

