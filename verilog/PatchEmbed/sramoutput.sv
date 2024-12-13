`timescale 1ns / 1ps

//an SRAM for storing output of size 27x27x64 bytes

module sramoutput #(parameter bit_width=30, channels=64, size=27)(
	input logic clk,
	input logic reset,
	input logic w_en,	//write enable
	input logic [$clog2(channels)-1:0] ch_addr,	//Address to select the channel (row) (6 bits for 64 channels)
	input logic [$clog2(size*size)-1:0] addr,	//Address to select the element within a row (27x27=729 cols)
	input logic [bit_width-1:0] data_in,		//8-bit input data (an element)
	input logic [$clog2(channels)-1:0] out_addr,

	output logic [(size*size*bit_width)-1:0] data_out //Entire row output so 729 elements (bytes)
);

	//SRAM memory for output, 64 rows, 729 cols (elements), 8 slices
	reg [bit_width-1:0] outmem [0:channels-1][0:(size*size-1)];

	integer i, j;
	 
	always @(posedge clk) begin
		if (reset) begin	//Reset logic: clear all memory and outputs
			data_out <= {(size*size*bit_width){1'b0}};
			for (i = 0; i < channels; i = i + 1) begin
				for (j = 0; j < (size*size); j = j + 1) begin
				outmem[i][j] <= {(bit_width){1'b0}};
				end
			end
		end else if (w_en) begin	//Write logic: write one element to the specified channel and address
		outmem[ch_addr][addr] <= data_in;
		end else begin			//Read logic: output an entire row (27x27 elements) for the selected channel
			for (i = 0; i < (size*size); i = i + 1) begin
			data_out[i * bit_width +: bit_width] <= outmem[out_addr][i];
			end
		end
	end

endmodule

