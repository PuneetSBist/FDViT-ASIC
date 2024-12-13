`timescale 1ns / 1ps

// testbench

module patchembed_tb;

	// Parameters
	parameter bit_width = 8;
	parameter acc_width = 18;
	parameter sum_width = 30;
	parameter kernels = 64;
	parameter size = 16;
	parameter channels = 3;
	parameter pixel = 224;
	parameter out_channels = 64;
	parameter out_size = 27;
	parameter elements = size * size * channels;
	parameter pixel_width = $clog2(pixel);
	parameter stride = 8;

	// Testbench signals
	reg clk;
	reg reset;
	reg start;
	reg w_en_in;
	reg w_en_wt;
	reg [$clog2(kernels)-1:0] write_wt_addr;
	reg [(elements*bit_width)-1:0] write_wt_data;
	reg [$clog2(channels)-1:0] channel_sel;
	reg [pixel_width-1:0] write_in_addr;
	reg [bit_width-1:0] write_in_data [0:pixel-1];
	reg [$clog2(out_channels)-1:0] out_addr;

	wire done;
	wire [(out_size*out_size*sum_width)-1:0] data_out;

	// Time measurement variables
	reg [31:0] start_time;
	reg [31:0] end_time;
	reg [31:0] elapsed_time;
	integer intpart, fracpart;

	// Instantiate the DUT (Device Under Test)
	patchembed #(
	.bit_width(bit_width),
	.acc_width(acc_width),
	.sum_width(sum_width),
	.kernels(kernels),
	.size(size),
	.channels(channels),
	.pixel(pixel),
	.out_channels(out_channels),
	.out_size(out_size),
	.elements(elements),
	.pixel_width(pixel_width),
	.stride(stride)
	) dut (
	.clk(clk),
	.reset(reset),
	.start(start),
	.w_en_in(w_en_in),
	.w_en_wt(w_en_wt),
	.write_wt_addr(write_wt_addr),
	.write_wt_data(write_wt_data),
	.channel_sel(channel_sel),
	.write_in_addr(write_in_addr),
	.write_in_data(write_in_data),
	.out_addr(out_addr),
	.done(done),
	.data_out(data_out)
	);

	// Clock generation
	initial begin
	clk = 0;
	forever #5 clk = ~clk;  // 100 MHz clock, T = 10ns
	end

	// Testbench logic
	initial begin
	integer wfile, infile, r, i, j;
	reg [bit_width-1:0] temp [0:elements-1];
	string infilenames[0:2] = {"/afs/asu.edu/users/w/m/u/wmushtaq/asap7_rundir/EEE598_Adv_HDW_ML/FDViT/RTL/red_binary.txt", "/afs/asu.edu/users/w/m/u/wmushtaq/asap7_rundir/EEE598_Adv_HDW_ML/FDViT/RTL/green_binary.txt", "/afs/asu.edu/users/w/m/u/wmushtaq/asap7_rundir/EEE598_Adv_HDW_ML/FDViT/RTL/blue_binary.txt"};

	// Initialization
	reset = 0;
	start = 0;
	w_en_in = 0;
	w_en_wt = 0;
	write_wt_addr = 0;
	write_wt_data = 0;
	channel_sel = 0;
	write_in_addr = 0;
	out_addr = 0;

	// Reset the DUT
	#10;
	reset = 1;	
	#50;
	reset = 0;

	// Load weights from text file
	wfile = $fopen("/afs/asu.edu/users/w/m/u/wmushtaq/asap7_rundir/EEE598_Adv_HDW_ML/FDViT/RTL/kernel_binary.txt", "r");
	if (wfile == 0) begin
		$display("Error: Failed to open weight data file.");
		$finish;
	end
	
	w_en_wt = 1;
	$display("Loading weight data.");
	for (i = 0; i < kernels; i = i + 1) begin
		write_wt_addr = i;
		write_wt_data = 0;	// Reset before loading new weights
		for (j = 0; j < elements; j = j + 1) begin
			r = $fscanf(wfile, "%b ", temp[j]);
			if (r != 1) begin
				$display("Error: Failed to read weight data");
				$finish;
			end
			//temp[j] = temp[j] & 8'hFF;	// Convert to 8-bit binary
			write_wt_data = write_wt_data | (temp[j] << (j * bit_width));   
		end
		#10;
		$display("weight kernel %0d: %b ", i, write_wt_data);
	end

	$fclose(wfile);
	w_en_wt = 0;
	
	#250;

	// Load input data from respective text files
	w_en_in = 1;
	for (int ch = 0; ch < channels; ch = ch + 1) begin
		$display("Loading input data for channel %0d from file %s.", ch, infilenames[ch]);
		channel_sel = ch;
		infile = $fopen(infilenames[ch], "r");
		if (infile == 0) begin
			$display("Error: Failed to open input data file %s.", infilenames[ch]);
			$finish;
		end

		for (i = 0; i < pixel; i = i + 1) begin
			write_in_addr = i;
			for (j = 0; j < pixel; j = j + 1) begin
				r = $fscanf(infile, "%b ", temp[j]);
				if (r != 1) begin
					$display("Error: Failed to read input data.");
					$finish;
				end
				write_in_data[j] = temp[j][bit_width-1:0]; // Convert to binary
			end
			#10;
			$display("%0d: %p", i, write_in_data);
		end
		$fclose(infile);
	end
	w_en_in = 0;
        	
	#500;

	// Start computation
	start_time = $time;
	start = 1;
	//#10;
	//start = 0;

	// Wait for computation to complete
	wait(done);
	end_time = $time;
	start=0;

	// Calculate elapsed time
	elapsed_time = end_time - start_time;
	intpart = (end_time - start_time)/(1000000);
	fracpart = (end_time - start_time)%(1000000);
	$display("Time taken for computation: %d ns", elapsed_time);
	$display("Time taken for computation: %d.%3d ms", intpart, fracpart);

	// Read output

	for (int i = 0; i < out_channels; i = i + 1) begin
		out_addr = i;
		#10;
		$display("Channel %0d Output: %h", i, data_out[(i*out_size*out_size*sum_width) +: (out_size*out_size*sum_width)]);
		if (i==2) begin
		$stop;
		end
	end

	// Finish simulation
	#100
	$stop;
	
	end

endmodule

