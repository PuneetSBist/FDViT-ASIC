`timescale 1ns / 1ps

//an SRAM for storing patch embedding weights; 64 weight kernels with each weight kernel size 16x16x3 (=768 bytes).

module sramweight #(parameter bit_width=8, kernels=64, size=16, channels=3, elements=size*size*channels)(
	input logic clk,
	input logic reset,
	input logic w_en,				//write enable
	input logic [$clog2(kernels)-1:0] r_row_addr,	//6bit row addresses point to 64 rows of sram, each row stores each kernel data
	input logic [$clog2(kernels)-1:0] w_row_addr,	
	input logic [(elements*bit_width)-1:0] data_in,	//each row input (written) to sram
	
	output logic [(elements*bit_width)-1:0] data_out	//768*8 = 6144 bits, each row is output
);

	//SRAM memory: 64 rows, each row storing all elements of one kernel so 768 bytes (768*8 bits)
	reg [bit_width-1:0] wmem [0:kernels-1][0:(elements)-1];		//[7:0]wmem[0:63][0:767]

	integer i, j;

	always @(posedge clk) begin
		if (reset) begin
			data_out <= {(elements*bit_width){1'b0}};
			for (i = 0; i < kernels; i = i + 1) begin
				for (j = 0; j < elements; j = j + 1) begin
				wmem[i][j] <= {(bit_width){1'b0}};
				end
			end
		end else if (w_en) begin	//Write operation: write a row
			for (i = 0; i < elements; i = i + 1) begin
			wmem[w_row_addr][i] <= data_in[i * bit_width +: bit_width];
			end
		end else begin			//Read operation: output all 768 bytes of the selected row
			for (i = 0; i < elements; i = i + 1) begin
			data_out[i*bit_width +: bit_width] <= wmem[r_row_addr][i];
			//Concatenate the single row data into data_out; selects bits from i*8 to i*8 + 7 inclusively
			end
		end
	end

endmodule

