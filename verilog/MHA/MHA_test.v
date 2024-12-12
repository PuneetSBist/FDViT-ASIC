`timescale 1ns / 1ps

// sample testbench for a 4X4 Systolic Array

module test_MHA;

	// Inputs
	reg clk;
	reg reset;

        MHA inst(clk, reset);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		
		// Wait 100 ns for global reset to finish
		#500;
       end
		// Add stimulus here
		always
		#250 clk=!clk;
		
		initial begin
		@(posedge clk);
		reset = 0;
		
                repeat (50) @(posedge clk);
                //check_for_value(acc_out, 19'h 00000, 19'h 00000, 19'h 00000, 19'h 00000); 
		$finish;
		end
      
	// This function loops through the address matrix, from the dut and the gold values, to make sure that the correct values have been computed
        task check_for_value(input [75:0]acc, input [18:0]gld_col3,
                                      input [18:0]gld_col2, input [18:0]gld_col1, input [18:0]gld_col0);

	    begin
		//$display("Column Accumulation[0]: %d       GOLD: %d ", acc[18:0], gld_col0);
		if (acc[18:0] !== gld_col0[18:0]) begin
			$display("Column Accumulation[0]: %d       GOLD: %d ", acc[18:0], gld_col0);
			$error("!!!ERROR: Accumulation for Column 0 is Conflicting");
		end

		//$display("Column Accumulation[1]: %d       GOLD: %d ", acc[37:19], gld_col1);
		if (acc[37:19] !== gld_col1[18:0]) begin
			$display("Column Accumulation[1]: %d       GOLD: %d ", acc[37:19], gld_col1);
			$error("!!!ERROR: Accumulation for Column 1 is Conflicting");
		end

		//$display("Column Accumulation[2]: %d       GOLD: %d ", acc[56:38], gld_col2);
		if (acc[56:38] !== gld_col2[18:0]) begin
			$display("Column Accumulation[2]: %d       GOLD: %d ", acc[56:38], gld_col2);
			$error("!!!ERROR: Accumulation for Column 2 is Conflicting");
		end

		//$display("Column Accumulation[3]: %d       GOLD: %d ", acc[75:57], gld_col3);
		if (acc[75:57] !== gld_col3[18:0]) begin
                    $display("Column Accumulation[3]: %d       GOLD: %d ", acc[75:57], gld_col3);
                    $error("!!!ERROR: Accumulation for Column 3 is Conflicting");
		end

		if ((acc[18:0] === gld_col0[18:0]) && (acc[37:19] === gld_col1[18:0]) &&
                    (acc[56:38] === gld_col2[18:0]) && (acc[75:57] === gld_col3[18:0])) begin
                    $display("Passed All accumulation");
                end

		$display("\n");

	    end
	endtask
endmodule
