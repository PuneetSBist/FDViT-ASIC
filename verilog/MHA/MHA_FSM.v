
module MHA_fsm #(parameter act_propogate = 16,
                 initial_latency = 3,
                 last_relax_loop = act_propogate+initial_latency,

                 outer_loop = 16,
                 inner_loop_1 = 4,
                 inner_loop_2 = 27*27,
                 pe_control_width = 4,
                 addr_width = 32)
(
    clk,                 // Clock signal
    reset,               // Reset signal
    is_wt,
    is_read,
    write_qkv,
    read_qkv_op,
    addr_bus,
    addr_bus_QKV,
    //output reg [pe_control_width-1:0] control,
    done                 // DONE signal to indicate completion
);

    localparam last_relax_loop_width = $clog2(last_relax_loop);
    localparam outer_loop_width = $clog2(outer_loop);
    localparam inner_loop_1_width = $clog2(inner_loop_1);
    localparam inner_loop_2_width = $clog2(inner_loop_2);

    input wire clk;
    input wire reset;
    output reg is_wt;
    output reg is_read;
    output reg write_qkv;
    output read_qkv_op;
    output reg [addr_width-1:0] addr_bus;
    output reg [addr_width-1:0] addr_bus_QKV[3*16-1:0];
    //output reg [pe_control_width-1:0] control,
    output reg done;                 // DONE signal to indicate completion

    // Define state encoding
    localparam QKV_CALC_STATE   = 3'b000;
    localparam QK_MULT_STATE    = 3'b001;
    localparam V_LEPE_STATE     = 3'b010;
    localparam MHA_SCORE_STATE  = 3'b011;                                               
    localparam LINEAR_STATE     = 3'b100;                                               
    localparam MLP0_STATE       = 3'b101;                                               
    localparam MLP1_STATE       = 3'b110;                                               
    localparam DONE_STATE       = 3'b111;                                               

    reg [2:0] state;
    reg [inner_loop_1_width-1:0] counter_1;
    reg [inner_loop_2_width-1:0] counter_2;
    reg [outer_loop_width-1:0] counter_3;
    reg [outer_loop_width-1:0] counter_o;
    reg [last_relax_loop_width-1:0] counter_relax;
    reg [last_relax_loop_width-1:0] init_latency;

    reg next_is_wt;
    reg next_read;
    reg next_done;
    reg [2:0]next_state;
    reg [inner_loop_1_width-1:0] next_counter_1;
    reg [inner_loop_2_width-1:0] next_counter_2;
    reg [outer_loop_width-1:0] next_counter_3;
    reg [outer_loop_width-1:0] next_counter_o;
    reg [last_relax_loop_width-1:0] next_counter_relax;
    reg [addr_width-1:0] next_addr_bus;
    reg read_qkv;

    assign read_qkv_op = (counter_o == 0) ? 0:read_qkv;

    //16X3 memory adress to store 16*3*4 channels per token seprated by address
    //write_qkv is set after 3+16 cycles and reset when wt is reloaded
    genvar qkvIdx, chIdx;
    generate
        for (qkvIdx = 0; qkvIdx< 3; qkvIdx= qkvIdx+1) begin : QKV_INDEX
            for (chIdx = 0; chIdx< 16; chIdx= chIdx+1) begin : CHANNEL_INDEX
                always @(posedge clk or posedge reset) begin
                    if (reset) begin
                        if (chIdx == 0) begin
                            addr_bus_QKV[qkvIdx*16] <= qkvIdx*16'h3000;
                        end else begin
                            addr_bus_QKV[qkvIdx*16+chIdx] <= addr_bus_QKV[qkvIdx*16+chIdx-1]+ 12'h300;
                        end
                    end else begin
                        addr_bus_QKV[qkvIdx*16+chIdx] <= addr_bus_QKV[qkvIdx*16+chIdx] + write_qkv;
                    end
                end
            end
        end
    endgenerate

    // FSM state machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all values
            is_wt <= 1;
            is_read <= 1;
            addr_bus <= {addr_width {1'b0}};
            write_qkv <= 0;
            read_qkv <= 0;
            //control <= 4b';
            done <= 0;
            state <= QKV_CALC_STATE;
            counter_1 <= {inner_loop_1_width{1'b0}};
            counter_relax <= {last_relax_loop_width{1'b0}};
            counter_2 <= {inner_loop_2_width{1'b0}};
            counter_3 <= {outer_loop_width{1'b0}};
            counter_o <= {outer_loop_width{1'b0}};
            init_latency <= 0;
        end else begin
            is_wt <= next_is_wt;
            is_read <= next_read;
            addr_bus <= next_addr_bus;
            //control <= ;
            done <= next_done;
            state <= next_state ;
            counter_1 <= next_counter_1;
            counter_relax <= next_counter_relax;
            counter_2 <= next_counter_2;
            counter_3 <= next_counter_3;
            counter_o <= next_counter_o;

            write_qkv <= read_qkv;
            //Writing output QKV val after 3+16 cycles
            if (state != QKV_CALC_STATE) begin
                write_qkv <= 0;
                init_latency <= 0;
            //Reset before weight reload
            end else if (counter_3 == act_propogate-1) begin
                read_qkv <= 0;
                init_latency <= 0;
            end else if (init_latency == last_relax_loop) begin
                read_qkv <= 1;
            end else begin
                init_latency <= init_latency+1;
            end

        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            QKV_CALC_STATE: begin
                if (counter_o == outer_loop-1) begin
                    //inner loop3 takes care of act propogation(16), but still
                    //need to change when accum of first row reach the last
                    if (counter_relax == initial_latency-1) begin
                        next_state = DONE_STATE;
                        next_done = 1;
                    end else begin
                        //weight sram off as well as MAC input propogate
                        next_is_wt = 0;
                        next_counter_relax = counter_relax + 1;
                        next_state = QKV_CALC_STATE;  // Stay in QKV_CALC_STATE until the cycle completes
                    end 
                    next_read = 0;
                    next_addr_bus = 0;
                end else begin
                    //Increment outer loop: 4 inp channel processed, need 16
                    //more outer loop, restart inner loops
                    if (counter_3 == act_propogate-1) begin
                        next_counter_o = counter_o + 1;
                        next_is_wt = 1;
                        next_counter_1 = {inner_loop_1_width{1'b0}};
                        next_counter_2 = {inner_loop_2_width{1'b0}};
                        next_addr_bus = counter_o*inner_loop_1;
                        next_read = 1;

                    //Wait till activation propogated for new weight reload
                    end else if (counter_2 == inner_loop_2-1) begin
                        next_counter_3 = counter_3 + 1;
                        next_is_wt = 0;
                        next_read = 0;
                        next_addr_bus = 0;

                    //Inner loop activation load 27X27 cycle(token)
                    end else if (counter_1 == inner_loop_1-1) begin
                        if (is_wt) begin
                            next_counter_2 = 0;
                        end else begin
                            next_counter_2 = counter_2 + 1;
                        end
                        next_is_wt = 0;
                        next_read = 1;
                        next_addr_bus = counter_o*inner_loop_2+ next_counter_2;
                    //Inner loop weight load 4 cycle(systolic row)
                    end else begin
                        next_read = 1;
                        next_is_wt = 1;
                        next_counter_1 = counter_1 + 1;
                        next_addr_bus = counter_o*inner_loop_1+ next_counter_1;
                    end 
                    next_done = 0;
                    next_state = QKV_CALC_STATE;  // Stay in QKV_CALC_STATE until the cycle completes
                end
            end

            QK_MULT_STATE: begin
            end

            V_LEPE_STATE: begin
            end

            MHA_SCORE_STATE: begin
            end

            LINEAR_STATE: begin
            end

            MLP0_STATE: begin
            end

            MLP1_STATE: begin
            end

            DONE_STATE: begin
                next_done = 1;  // Assert done signal when in DONE_STATE
                next_state = DONE_STATE;  // Stay in DONE_STATE
            end

            default: next_state = QKV_CALC_STATE;  // Default state in case of an error
        endcase
    end

endmodule

