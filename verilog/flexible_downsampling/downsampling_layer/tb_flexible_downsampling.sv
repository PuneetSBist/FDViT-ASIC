module tb_flexible_downsampling;

    // Parameters for the testbench
    parameter int CIN = 64;          // Number of input channels
    parameter int stride_q8_8 = 369; // Scaled stride in Q8.8 format (e.g., 1.444 * 256 = 369)
    parameter int HIN = 27;          // Input height/width
    parameter int HOUT = 19;         // Output height/width

    // Signals
    logic clk;
    logic rst_n;
    logic [7:0] ifmap [0:HIN-1][0:HIN-1][0:CIN-1];
    logic ready;
    logic [7:0] ofmap [0:HOUT-1][0:HOUT-1][0:CIN-1];
    logic done;

    // DUT instantiation
    flexible_downsampling #(
        .CIN(CIN),
        .stride_scaled(stride_q8_8), // Pass the scaled stride value
        .HIN(HIN),
        .HOUT(HOUT)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .ifmap(ifmap),
        .ready(ready),
        .ofmap(ofmap),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Reset sequence
    initial begin
        rst_n = 0;
        ready = 0;
        #20 rst_n = 1;
    end

    // Test stimulus
    initial begin
        // Initialize input feature map
        for (int c = 0; c < CIN; c++) begin
            for (int i = 0; i < HIN; i++) begin
                for (int j = 0; j < HIN; j++) begin
                    ifmap[i][j][c] = 10 * (i + j) % 256; // Similar pattern as in Verilog code
                end
            end
        end

        // Start the downsampling process
        @(posedge rst_n); // Wait for reset deassertion
        #10 ready = 1;    // Assert ready signal
        @(posedge clk);   // Wait one clock cycle
        ready = 0;        // Deassert ready signal

        // Wait for the done signal
        wait(done);
        #10;

        // Verify the output (example verification)
        $display("Downsampling completed. Verifying output...");
        for (int c = 0; c < CIN; c++) begin
            for (int i = 0; i < HOUT; i++) begin
                for (int j = 0; j < HOUT; j++) begin
                    $display("ofmap[%0d][%0d][%0d] = %0d", i, j, c, ofmap[i][j][c]);
                    // Add your verification logic here (e.g., compare with expected values)
                end
            end
        end

        // End simulation
        $finish;
    end

endmodule
