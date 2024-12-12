module tb_flexible_downsampling;

    // Parameters
    parameter int CIN = 64;
    parameter int stride_q8_8 = 369;
    parameter int HIN = 27;
    parameter int HOUT = 19;

    // Signals
    logic clk;
    logic rst_n;
    logic [7:0] ifmap [0:HIN-1][0:HIN-1][0:CIN-1];
    logic ready;
    wire [7:0] ofmap_slice [0:HOUT-1][0:HOUT-1];
    logic done;

    // DUT instantiation
    flexible_downsampling #(
        .CIN(CIN),
        .stride_q8_8(stride_q8_8),
        .HIN(HIN),
        .HOUT(HOUT)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .ifmap(ifmap),
        .ready(ready),
        .ofmap_slice(ofmap_slice),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset sequence
    initial begin
        rst_n = 0;
        ready = 0;
        #20 rst_n = 1;
    end

    // Initialize the input feature map
    initial begin
        $display("Initializing input feature map...");
        for (int c = 0; c < CIN; c++) begin
            for (int i = 0; i < HIN; i++) begin
                for (int j = 0; j < HIN; j++) begin
                    ifmap[i][j][c] = (10 * (i + j) + c) % 256;
                end
            end
        end
    end

    // Start the downsampling process
    initial begin
        @(posedge rst_n);
        #10 ready = 1;
        @(posedge clk);
        ready = 0;
    end

    // Storage for previous cycle's ifmap_slice
    reg [7:0] prev_ifmap_slice [0:HIN-1][0:HIN-1];

    // On each positive clock edge, capture the current DUT ifmap_slice for next cycle's print
    always @(posedge clk) begin
        if (uut.ps == 2'b01) begin
            for (int i = 0; i < HIN; i++) begin
                for (int j = 0; j < HIN; j++) begin
                    prev_ifmap_slice[i][j] <= uut.ifmap_slice[i][j];
                end
            end
        end
    end

    // Print the previous cycle's ifmap_slice and current ofmap_slice each cycle during RUNNING state
    always @(posedge clk) begin
        // Check if we are in RUNNING state
        if (uut.ps == 2'b01) begin
            $display("==================================================");
            $display("Cycle %0t, Processing Channel %0d", $time, uut.channel_idx);
            $display("PREVIOUS Cycle IFMAP Slice:");
            for (int i = 0; i < HIN; i++) begin
                for (int j = 0; j < HIN; j++) begin
                    $write("%4d ", prev_ifmap_slice[i][j]);
                end
                $display();
            end

            $display("Current Cycle OFMAP Slice:");
            for (int i = 0; i < HOUT; i++) begin
                for (int j = 0; j < HOUT; j++) begin
                    $write("%4d ", ofmap_slice[i][j]);
                end
                $display();
            end
        end
    end

    // Wait for completion and then print the final ofmap slice
    initial begin
        @(posedge done);
        #10;

        $display("Downsampling completed. Final Output Slice:");
        for (int i = 0; i < HOUT; i++) begin
            for (int j = 0; j < HOUT; j++) begin
                $write("%4d ", ofmap_slice[i][j]);
            end
            $display();
        end

        $finish;
    end

endmodule

