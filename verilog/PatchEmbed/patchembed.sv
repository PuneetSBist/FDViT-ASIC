`timescale 1ns / 1ps

//a patch embedding unit

module patchembed #(parameter bit_width=8, acc_width=18, sum_width=30, kernels=64, size=16, channels=3, pixel=224, out_channels=64, out_size=27, elements=size*size*channels, pixel_width=$clog2(pixel), stride=8)(
	input logic clk,
	input logic reset,
	input logic start,
	input logic w_en_in,
	input logic w_en_wt,
	input logic [$clog2(kernels)-1:0] write_wt_addr,
	input logic [(elements*bit_width)-1:0] write_wt_data,
	input logic [$clog2(channels)-1:0] channel_sel,
	input logic [pixel_width-1:0] write_in_addr,
	input wire [bit_width-1:0] write_in_data [0:pixel-1],
	input logic [$clog2(out_channels)-1:0] out_addr,		//to read from output sram

	output logic done,
	output logic [(out_size*out_size*sum_width)-1:0] data_out	//each channel read from output sram
);
	//Internal Signals
	logic control;
	logic w_en_out;
	logic [$clog2(kernels)-1:0] read_wt_addr;
	logic [(elements*bit_width)-1:0] wt_data;
	logic [pixel_width-1:0] read_in_row;
	logic [pixel_width-1:0] read_in_col;
	logic [(elements*bit_width)-1:0] in_data;
	logic [$clog2(out_channels)-1:0] out_row_addr;
	logic [$clog2(out_size*out_size)-1:0] out_element_addr;
	logic [sum_width-1:0] write_out_data;

	reg [acc_width-1:0] partial_prod [0:kernels-1][0:(elements-1)];	//to store prod output from each mac
	reg [sum_width-1:0] sum [0:kernels-1];

	// FSM states
	typedef enum logic [1:0] {IDLE, LOAD_MAC, COMPUTE, STORE_OUTPUT} state_t;
	state_t current_state, next_state;

	integer i, j;

//**********************************************************************************************************************************

	sramweight #(
	.bit_width(bit_width),
	.kernels(kernels),
	.size(size),
	.channels(channels)
	) sramweight_instance (
	.clk(clk),
	.reset(reset),
	.w_en(w_en_wt),
	.r_row_addr(read_wt_addr),
	.w_row_addr(write_wt_addr),
	.data_in(write_wt_data),
	.data_out(wt_data)
	);

	sraminput #(
	.bit_width(bit_width),
	.pixel(pixel),
	.patch_size(size),
	.channels(channels)
	) sraminput_instance (
	.clk(clk),
	.reset(reset),
	.w_en(w_en_in),
	.channel_select(channel_sel),
	.row_addr(write_in_addr),
	.data_in(write_in_data),
	.block_row(read_in_row),
	.block_col(read_in_col),
	.data_out(in_data)
	);

	sramoutput #(
	.bit_width(sum_width),
	.channels(out_channels),
	.size(out_size)
	) sramoutput_instance (
	.clk(clk),
	.reset(reset),
	.w_en(w_en_out),
	.ch_addr(out_row_addr),
	.addr(out_element_addr),
	.data_in(write_out_data),
	.out_addr(out_addr),
	.data_out(data_out)
	);


	// Instantiate the 64x768 MAC array
	genvar k, e;
	generate
	for (k = 0; k < kernels; k = k + 1) begin : mac_kernel_row
		for (e = 0; e < elements; e = e + 1) begin : mac_elements
		MAC #(
		.bit_width(bit_width),
		.acc_width(acc_width)
		) mac (
		.clk(clk),
		.reset(reset),
		.control(control),
		.data_in(in_data[e * bit_width +: bit_width]),
		.wt_in(wt_data[e * bit_width +: bit_width]),
		.prod_out(partial_prod[k][e])
		);
		end
	end
	endgenerate     

//**********************************************************************************************************************************
	
	always @(posedge clk) begin
		if (reset) begin
		current_state <= IDLE;
		read_wt_addr <= {($clog2(kernels)){1'b0}};
		read_in_row <= {(pixel_width){1'b0}};
		read_in_col <= {(pixel_width){1'b0}};
		out_element_addr <= {($clog2(out_size*out_size)){1'b0}};
		out_row_addr <= {($clog2(out_channels)){1'b0}};
		end else if (start) begin
		current_state <= next_state;
		end
		
		if (control && current_state == LOAD_MAC) begin
			if (read_wt_addr <= kernels-1) begin
			read_wt_addr <= read_wt_addr+1;
			end
		end else if (current_state == COMPUTE) begin
			if (read_in_col < pixel-size) begin
				if (read_in_row < pixel-size) begin
					read_in_row <= read_in_row;
					read_in_col <= read_in_col + stride;
				end
			end else begin
				read_in_row <= read_in_row + stride;
				read_in_col <= {(pixel_width){1'b0}};
			end
		end else if (current_state == STORE_OUTPUT) begin
			if (out_row_addr == kernels-1) begin
				out_element_addr <= out_element_addr + 1;
				out_row_addr <= {($clog2(out_channels)){1'b0}};
			end else begin
				out_element_addr <= out_element_addr;
				out_row_addr <= out_row_addr + 1;
			end
		end
	end
	
	
	always @(*) begin
		if (reset) begin
		done = 0;
		control = 0;
		w_en_out = 0;
		end else begin
			case (current_state)
			IDLE: begin	//IDLE: load input data and weights to respective sram
				if (start) begin
				next_state = LOAD_MAC;
				end else begin
				next_state = IDLE;
				end
			end
			LOAD_MAC: begin	//LOAD_MAC: weights from sram to mac array, control=1 then read_wt_addr modified every clock
				control = 1;
				if (read_wt_addr == (kernels-1)) begin //***
				//control = 0;
				next_state = COMPUTE;
				end else begin
				next_state = LOAD_MAC;
				end
			end
			COMPUTE: begin	//COMPUTE: read_in_row and read_in_col to bring data_in, prod to reg
				control = 0;
				w_en_out = 0;
				for (i = 0; i < kernels; i = i + 1) begin
					sum[i] = 0;
					for (j = 0; j < elements; j = j + 1) begin
						sum[i] = sum[i] + partial_prod[i][j];
					end
				end
				next_state = STORE_OUTPUT;
			end
			STORE_OUTPUT: begin	//sum reg to sram; w_en_out=1; out_row_addr, out_element_addr and write_out_data given
				w_en_out = 1;
				write_out_data = sum[out_row_addr];
				if (out_row_addr == kernels-1 && out_element_addr < out_size*out_size) begin
					next_state = COMPUTE;
					//w_en_out = 0;
				end else if (out_row_addr == kernels-1 && out_element_addr == out_size*out_size) begin
					next_state = IDLE;
					w_en_out = 0;
					done = 1;
				end else begin
				next_state = STORE_OUTPUT;
				end
			
			end
			endcase
		end		
	end

endmodule

