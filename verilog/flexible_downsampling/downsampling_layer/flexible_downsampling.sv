module flexible_downsampling #(
    parameter int CIN = 64,             // Number of input channels
    parameter int stride_scaled = 369, // Scaled stride value in Q8.8 format (1.444 * 256)
    parameter int HIN = 27,             // Input height/width
    parameter int HOUT = 19             // Output height/width
)(
    input logic clk,                               // Clock signal
    input logic rst_n,                             // Active-low reset signal
    input logic [7:0] ifmap [0:HIN-1][0:HIN-1][0:CIN-1], // Input tensor: 8-bit x HINxHIN x CIN channels
    input logic ready,                             // Ready signal to start processing
    output logic [7:0] ofmap [0:HOUT-1][0:HOUT-1][0:CIN-1], // Output tensor: 8-bit x HOUTxHOUT x CIN channels
    output logic done                              // Done signal
);

    // Internal signals
    logic [$clog2(CIN)-1:0] channel_idx;           // Index of the current channel (0 to CIN-1)
    logic [7:0] ifmap_slice [0:HIN-1][0:HIN-1];    // Current input feature map for one channel
    logic [7:0] ofmap_slice [0:HOUT-1][0:HOUT-1];  // Current output feature map for one channel
    logic [1:0] ps, ns;                            // FSM states (ready, running, done)

    // FSM states
    typedef enum logic [1:0] {
        READY = 2'b00,
        RUNNING = 2'b01,
        DONE = 2'b10
    } fsm_state_t;

    // Assign FSM outputs
    assign done = (ps == DONE);

    // FSM sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ps <= READY;
        else
            ps <= ns;
    end

    // FSM combinational logic
    always_comb begin
        case (ps)
            READY: begin
                if (ready)
                    ns = RUNNING;
                else
                    ns = READY;
            end
            RUNNING: begin
                if (channel_idx == CIN - 1)
                    ns = DONE;
                else
                    ns = RUNNING;
            end
            DONE: begin
                ns = READY; // Optionally, transition back to READY
            end
            default: ns = READY;
        endcase
    end

    // Channel processing logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            channel_idx <= 0;
        else if (ps == RUNNING)
            channel_idx <= channel_idx + 1;
    end

    // Load the input slice and store the output slice
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset output feature map
            for (int i = 0; i < HOUT; i++) begin
                for (int j = 0; j < HOUT; j++) begin
                    for (int k = 0; k < CIN; k++) begin
                        ofmap[i][j][k] <= 8'd0;
                    end
                end
            end
        end else if (ps == RUNNING) begin
            // Load input slice
            for (int i = 0; i < HIN; i++) begin
                for (int j = 0; j < HIN; j++) begin
                    ifmap_slice[i][j] <= ifmap[i][j][channel_idx];
                end
            end
            // Store output slice
            for (int i = 0; i < HOUT; i++) begin
                for (int j = 0; j < HOUT; j++) begin
                    ofmap[i][j][channel_idx] <= ofmap_slice[i][j];
                end
            end
        end
    end

    // Instantiate the downsample module
    downsample #(
        .stride_scaled(stride_scaled), // Pass Q8.8 stride
        .hin(HIN),
        .hout(HOUT)
    ) u_downsample (
        .ifmap(ifmap_slice),
        .ofmap(ofmap_slice)
    );

endmodule
