
module sram #(parameter row_count = 64,
              col_count = 192,
              bit_width = 8,
              addr_width = (row_count > 1) ? $clog2(row_count) : 1,
              row_width = col_count*bit_width)
(
    clk,             // Clock signal
    we,              // Write Enable
    rd_en,           // Read Enable
    addr,      // Address (192 addresses)
    din,      // Data input (32 bits = 4 bytes)
    dout      // Data output (32 bits = 4 bytes)
);
    

    input clk;
    input we;
    input rd_en;
    input [addr_width-1:0] addr;
    input [row_width-1:0] din;
    output reg [row_width-1:0] dout;

    reg [row_width-1:0] mem [0:row_count];
    wire gated_clk;
    assign gated_clk = clk & (we | rd_en);

    wire [3:0] value;
    assign value = addr%16;

    always @(posedge gated_clk) begin
        if (we) begin
            // Write operation: Store the data at the specified address
            mem[addr] <= din;
        end
        if (rd_en) begin
            // Read operation: Output the data from the specified address
            // Debug
            //dout <= mem[addr];
            dout <= {192{ {4'b0000, value} }};
        end else begin
            dout <= 0;
        end 
    end

endmodule


module sram_multp_addr#(parameter row_count = 64,
                        col_count = 4,
                        bit_width = 20,
                        row_width = col_count*bit_width,
                        addr_width = (row_count > 1) ? $clog2(row_count) : 1,
                        partition1 = 16,
                        partition2 = 3)
(
    clk,             // Clock signal
    we,              // Write Enable
    rd_en,           // Read Enable
    r_addr_qkv, //need 16 row and 3 QKV addr
    addr_qkv, //need 16 row and 3 QKV addr
    din, //16 col of 12 PE blk
    dout      // Data output (32 bits = 4 bytes)
);
    
    input clk;
    input we;
    input rd_en;
    input [addr_width-1:0] r_addr_qkv[3*16-1:0];
    input [addr_width-1:0] addr_qkv[3*16-1:0];
    input [bit_width*partition1-1:0] din[11:0];
    output reg [row_width-1:0] dout[3*16-1:0];
    
    reg [row_width-1:0] mem [0:row_count];
    wire gated_clk;
    wire [bit_width*col_count-1:0] reshaped_din[2:0][15:0];
    assign gated_clk = clk & (we | rd_en);

    genvar pe_blk, col;
    generate
        for (pe_blk = 0; pe_blk < 12; pe_blk = pe_blk + 1) begin : reshape_qkv
            for (col = 0; col < partition1; col = col+col_count) begin : reshape_din
                // Map 4 bit_width per address
                assign reshaped_din[pe_blk/4][(pe_blk%4)*4+col/4] = din[pe_blk][(col+col_count)*bit_width-1: col*bit_width];
            end
        end
    endgenerate

    genvar qkvIdx, rowIdx;
    generate
        for (qkvIdx = 0; qkvIdx < 3; qkvIdx = qkvIdx + 1) begin : addr_assign_qkv
            for (rowIdx= 0; rowIdx< 16; rowIdx= rowIdx+ 1) begin : addr_assign_row
                always @(posedge gated_clk) begin

                    if (we) begin
                        mem[addr_qkv[qkvIdx*16+rowIdx]] <= reshaped_din[qkvIdx][rowIdx];
                    end
                    if (rd_en) begin
                        // Read operation: Output the data from the specified address
                        dout[qkvIdx*16+rowIdx] <= mem[r_addr_qkv[qkvIdx*16+rowIdx]];
                    end else begin
                        dout[qkvIdx*16+rowIdx] <= 0;
                    end 
                end
            end
        end
    endgenerate

endmodule
