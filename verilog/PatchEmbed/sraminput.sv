`timescale 1ns / 1ps

//an SRAM for storing input image of size 224(pixel) x 224(pixel) x 3(channels); each pixel is 1byte=8bits.

module sraminput #(parameter bit_width=8, pixel=224, pixel_width=$clog2(pixel), patch_size=16, channels=3)(
	input logic clk,
	input logic reset,
	input logic w_en,					//write enable
	input logic [$clog2(channels)-1:0] channel_select,	// 00: Red, 01: Green, 10: Blue
	input logic [pixel_width-1:0] row_addr,			//For 224 rows, 8-bit row address to write data in each row
	input wire [bit_width-1:0] data_in [0:pixel-1],	// 224x8 input data for a row
	input logic [pixel_width-1:0] block_row,		//Row index for block output
	input logic [pixel_width-1:0] block_col,		//Column index for block output
	
	output logic [(patch_size*patch_size*channels*bit_width)-1:0] data_out
);
	
	//SRAM memory blocks for 3 different channels RGB, 224x224x8
	reg [bit_width-1:0] rmem [0:pixel-1][0:pixel-1];	//Red
	reg [bit_width-1:0] gmem [0:pixel-1][0:pixel-1];	//Green
	reg [bit_width-1:0] bmem [0:pixel-1][0:pixel-1];	//Blue
	
	integer i, j;
	
	//Temporary storage for 16x16 blocks
	reg [bit_width-1:0] r_out [0:patch_size-1][0:patch_size-1];	// 16x16 block output (read) from rmem
	reg [bit_width-1:0] g_out [0:patch_size-1][0:patch_size-1];	// 16x16 block output (read) from gmem
	reg [bit_width-1:0] b_out [0:patch_size-1][0:patch_size-1];	// 16x16 block output (read) from bmem
	
	always @(posedge clk) begin
		if (reset) begin
			data_out = {(patch_size*patch_size*channels*bit_width){1'b0}};
			for (i = 0; i < patch_size; i = i + 1) begin
				for (j = 0; j < patch_size; j = j + 1) begin
				r_out[i][j] <= {(bit_width){1'b0}};
				g_out[i][j] <= {(bit_width){1'b0}};
				b_out[i][j] <= {(bit_width){1'b0}};
				end
			end
			for (i = 0; i < pixel; i = i + 1) begin
				for (j = 0; j < pixel; j = j + 1) begin
				rmem[i][j] <= {(bit_width){1'b0}};
				gmem[i][j] <= {(bit_width){1'b0}};
				bmem[i][j] <= {(bit_width){1'b0}};
				end
			end
		end else if (w_en) begin	//Write to memory each row at a time
			case (channel_select)
			2'b00: rmem[row_addr] <= data_in;	// Write to Red memory
			2'b01: gmem[row_addr] <= data_in;	// Write to Green memory
			2'b10: bmem[row_addr] <= data_in;	// Write to Blue memory
			endcase
		end
		else begin		//Read 16x16 block for output
			for (i = 0; i < patch_size; i = i + 1) begin
				for (j = 0; j < patch_size; j = j + 1) begin
				r_out[i][j] <= rmem[block_row + i][block_col + j];
				g_out[i][j] <= gmem[block_row + i][block_col + j];
				b_out[i][j] <= bmem[block_row + i][block_col + j];
				end
			end
		end
	end

	always @(*) begin
	//Flatten r_out, g_out, b_out into data_out, first 256 elements r_out, then next 256 elements g_out, then last 256 elements b_out
		for (i = 0; i < patch_size; i = i + 1) begin
			for (j = 0; j < patch_size; j = j + 1) begin
			data_out[(i * patch_size + j) * bit_width +: bit_width] = r_out[i][j];
			data_out[((1 * patch_size * patch_size) + (i * patch_size + j)) * bit_width +: bit_width] = g_out[i][j];
			data_out[((2 * patch_size * patch_size) + (i * patch_size + j)) * bit_width +: bit_width] = b_out[i][j];
			end
		end
	end

endmodule

