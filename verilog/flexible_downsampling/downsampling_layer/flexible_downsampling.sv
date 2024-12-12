module flexible_downsampling #(
    parameter int CIN = 64,
    parameter int stride_q8_8 = 369,
    parameter int HIN = 27,
    parameter int HOUT = 19
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] ifmap [0:HIN-1][0:HIN-1][0:CIN-1],
    input  logic ready,
    output logic [7:0] ofmap_slice [0:HOUT-1][0:HOUT-1],
    output logic done
);

    // FSM states
    typedef enum logic [1:0] {
        READY   = 2'b00,
        RUNNING = 2'b01,
        DONE    = 2'b10
    } fsm_state_t;

    logic [$clog2(CIN)-1:0] channel_idx;
    logic [1:0] ps, ns;
    logic [7:0] ifmap_slice [0:HIN-1][0:HIN-1]; // Local slice for current channel

    // Output assignment
    assign done = (ps == DONE);

    // FSM Sequential Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ps <= READY;
        else
            ps <= ns;
    end

    // FSM Combinational Logic
    always_comb begin
        case (ps)
            READY:   ns = ready ? RUNNING : READY;
            RUNNING: ns = (channel_idx == CIN - 1) ? DONE : RUNNING;
            DONE:    ns = DONE; // Remain in DONE state
            default: ns = READY;
        endcase
    end

    // Channel Index Management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            channel_idx <= 0;
        else if (ps == RUNNING)
            channel_idx <= channel_idx + 1;
    end

    // Load Input Slice (Sequential Logic)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < HIN; i++) begin
                for (int j = 0; j < HIN; j++) begin
                    ifmap_slice[i][j] <= 8'd0;
                end
            end
        end else if (ps == RUNNING) begin
            for (int i = 0; i < HIN; i++) begin
                for (int j = 0; j < HIN; j++) begin
                    ifmap_slice[i][j] <= ifmap[i][j][channel_idx];
                end
            end
        end
    end

    // Downsample Logic (Module Instantiation)
    downsample #(
        .stride_q8_8(stride_q8_8),
        .hin(HIN),
        .hout(HOUT)
    ) u_downsample (
        .ifmap(ifmap_slice),
        .ofmap(ofmap_slice)
    );

endmodule
