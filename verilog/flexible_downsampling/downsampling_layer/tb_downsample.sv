module tb_downsample;

    // Parameters
    parameter real stride = 1.444;
    parameter int hin = 27;
    parameter int hout = 19;

    // Input and output
    logic [7:0] ifmap [0:hin-1][0:hin-1];
  logic [7:0] ofmap [0:hout-1][0:hout-1];

    // Instantiate the module under test
    downsample #(
        .stride(stride),
        .hin(hin),
        .hout(hout)
    ) uut (
        .ifmap(ifmap),
        .ofmap(ofmap)
    );

    // Test initialization
    initial begin
        // Initialize input feature map with a simple pattern for testing
        integer i, j;
        for (i = 0; i < hin; i++) begin
            for (j = 0; j < hin; j++) begin
                ifmap[i][j] = (i + j) % 256; // Simple test pattern
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