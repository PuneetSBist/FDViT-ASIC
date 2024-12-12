module tb_downsample;

    // Parameters
    parameter int stride_q8_8 = 369; // 1.444 * 256 = 369.9
    parameter int hin = 27;
    parameter int hout = 19;

    // Input and output
    logic [7:0] ifmap [0:hin-1][0:hin-1];
    logic [7:0] ofmap [0:hout-1][0:hout-1];

    // Instantiate the module under test
    downsample #(
        .stride_q8_8(stride_q8_8),
        .hin(hin),
        .hout(hout)
    ) uut (
        .ifmap(ifmap),
        .ofmap(ofmap)
    );

    // Test initialization
    initial begin
        // Initialize input feature map with a varied pattern for testing
        integer i, j;
        for (i = 0; i < hin; i++) begin
            for (j = 0; j < hin; j++) begin
                ifmap[i][j] = 10*(i+j); // Random values between 0 and 250
            end
        end

        // Display input feature map
        $display("Input Feature Map:");
        for (i = 0; i < hin; i++) begin
            for (j = 0; j < hin; j++) begin
                $write("%4d", ifmap[i][j]);
            end
            $display();
        end

        // Wait for processing
        #10;

        // Display output feature map
        $display("Output Feature Map:");
        for (i = 0; i < hout; i++) begin
            for (j = 0; j < hout; j++) begin
                $write("%6d", ofmap[i][j]);
            end
            $display();
        end

        // End simulation
        $finish;
    end

endmodule