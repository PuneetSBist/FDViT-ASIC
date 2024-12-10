`timescale 1ns / 1ns
// Systolic Array top level module. 

module MMU#(parameter depth=4, bit_width=8, acc_width=32, size=4)
(
   clk,
   control,
   data_arr,
   wt_arr,
   acc_out
);
   input clk;
   input control; 
   input [(bit_width*depth)-1:0] data_arr;
   input [(bit_width*depth)-1:0] wt_arr;
   output reg [acc_width*size-1:0] acc_out;
   
   
   // Implement your logic below based on the MAC unit design in MAC.v

   // intermediary wires
   wire [acc_width*size-1:0] mac_acc_in_wire_0, mac_acc_in_wire_1, mac_acc_in_wire_2, mac_acc_in_wire_3;
   wire [acc_width*size-1:0] mac_acc_out_wire_0, mac_acc_out_wire_1, mac_acc_out_wire_2, mac_acc_out_wire_3;
   wire [(bit_width*depth)-1:0] wt_in_wire_0, wt_in_wire_1, wt_in_wire_2, wt_in_wire_3;
   wire [(bit_width*depth)-1:0] wt_out_wire_0, wt_out_wire_1, wt_out_wire_2, wt_out_wire_3;
   wire [(bit_width*depth)-1:0] mac_data_in_wire_0, mac_data_in_wire_1, mac_data_in_wire_2, mac_data_in_wire_3;
   wire [(bit_width*depth)-1:0] mac_data_out_wire_0, mac_data_out_wire_1, mac_data_out_wire_2, mac_data_out_wire_3;

   assign mac_acc_in_wire_0 = 'h0;
   assign mac_acc_in_wire_1 = mac_acc_out_wire_0;
   assign mac_acc_in_wire_2 = mac_acc_out_wire_1;
   assign mac_acc_in_wire_3 = mac_acc_out_wire_2;
   assign mac_data_in_wire_0 = control ? 'h0 : data_arr;
   assign mac_data_in_wire_1 = mac_data_out_wire_0;
   assign mac_data_in_wire_2 = mac_data_out_wire_1;
   assign mac_data_in_wire_3 = mac_data_out_wire_2;
   assign wt_in_wire_0 = control ? wt_arr : 'h0;
   assign wt_in_wire_1 = control ? wt_out_wire_0 : 'h0;
   assign wt_in_wire_2 = control ? wt_out_wire_1 : 'h0;
   assign wt_in_wire_3 = control ? wt_out_wire_2 : 'h0;
   

   MAC MAC11 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_0[7:0]),
      .wt_path_in  (wt_in_wire_0[7:0]),
      .acc_in      (mac_acc_in_wire_0[acc_width-1:0]),
      .data_out    (mac_data_out_wire_0[7:0]),
      .wt_path_out (wt_out_wire_0[7:0]),
      .acc_out     (mac_acc_out_wire_0[acc_width-1:0])
   );
   MAC MAC12 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_0[15:8]),
      .wt_path_in  (wt_in_wire_1[7:0]),
      .acc_in      (mac_acc_in_wire_1[acc_width-1:0]),
      .data_out    (mac_data_out_wire_0[15:8]),
      .wt_path_out (wt_out_wire_1[7:0]),
      .acc_out     (mac_acc_out_wire_1[acc_width-1:0])
   );
   MAC MAC13 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_0[23:16]),
      .wt_path_in  (wt_in_wire_2[7:0]),
      .acc_in      (mac_acc_in_wire_2[acc_width-1:0]),
      .data_out    (mac_data_out_wire_0[23:16]),
      .wt_path_out (wt_out_wire_2[7:0]),
      .acc_out     (mac_acc_out_wire_2[acc_width-1:0])
   );
   MAC MAC14 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_0[31:24]),
      .wt_path_in  (wt_in_wire_3[7:0]),
      .acc_in      (mac_acc_in_wire_3[acc_width-1:0]),
      .data_out    (mac_data_out_wire_0[31:24]),
      .wt_path_out (wt_out_wire_3[7:0]),
      .acc_out     (mac_acc_out_wire_3[acc_width-1:0])
   );

   MAC MAC21 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_1[7:0]),
      .wt_path_in  (wt_in_wire_0[15:8]),
      .acc_in      (mac_acc_in_wire_0[2*acc_width-1:acc_width]),
      .data_out    (mac_data_out_wire_1[7:0]),
      .wt_path_out (wt_out_wire_0[15:8]),
      .acc_out     (mac_acc_out_wire_0[2*acc_width-1:acc_width])
   );
   MAC MAC22 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_1[15:8]),
      .wt_path_in  (wt_in_wire_1[15:8]),
      .acc_in      (mac_acc_in_wire_1[2*acc_width-1:acc_width]),
      .data_out    (mac_data_out_wire_1[15:8]),
      .wt_path_out (wt_out_wire_1[15:8]),
      .acc_out     (mac_acc_out_wire_1[2*acc_width-1:acc_width])
   );
   MAC MAC23 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_1[23:16]),
      .wt_path_in  (wt_in_wire_2[15:8]),
      .acc_in      (mac_acc_in_wire_2[2*acc_width-1:acc_width]),
      .data_out    (mac_data_out_wire_1[23:16]),
      .wt_path_out (wt_out_wire_2[15:8]),
      .acc_out     (mac_acc_out_wire_2[2*acc_width-1:acc_width])
   );
   MAC MAC24 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_1[31:24]),
      .wt_path_in  (wt_in_wire_3[15:8]),
      .acc_in      (mac_acc_in_wire_3[2*acc_width-1:acc_width]),
      .data_out    (mac_data_out_wire_1[31:24]),
      .wt_path_out (wt_out_wire_3[15:8]),
      .acc_out     (mac_acc_out_wire_3[2*acc_width-1:acc_width])
   );

   MAC MAC31 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_2[7:0]),
      .wt_path_in  (wt_in_wire_0[23:16]),
      .acc_in      (mac_acc_in_wire_0[3*acc_width-1:2*acc_width]),
      .data_out    (mac_data_out_wire_2[7:0]),
      .wt_path_out (wt_out_wire_0[23:16]),
      .acc_out     (mac_acc_out_wire_0[3*acc_width-1:2*acc_width])
   );
   MAC MAC32 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_2[15:8]),
      .wt_path_in  (wt_in_wire_1[23:16]),
      .acc_in      (mac_acc_in_wire_1[3*acc_width-1:2*acc_width]),
      .data_out    (mac_data_out_wire_2[15:8]),
      .wt_path_out (wt_out_wire_1[23:16]),
      .acc_out     (mac_acc_out_wire_1[3*acc_width-1:2*acc_width])
   );
   MAC MAC33 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_2[23:16]),
      .wt_path_in  (wt_in_wire_2[23:16]),
      .acc_in      (mac_acc_in_wire_2[3*acc_width-1:2*acc_width]),
      .data_out    (mac_data_out_wire_2[23:16]),
      .wt_path_out (wt_out_wire_2[23:16]),
      .acc_out     (mac_acc_out_wire_2[3*acc_width-1:2*acc_width])
   );
   MAC MAC34 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_2[31:24]),
      .wt_path_in  (wt_in_wire_3[23:16]),
      .acc_in      (mac_acc_in_wire_3[3*acc_width-1:2*acc_width]),
      .data_out    (mac_data_out_wire_2[31:24]),
      .wt_path_out (wt_out_wire_3[23:16]),
      .acc_out     (mac_acc_out_wire_3[3*acc_width-1:2*acc_width])
   );

   MAC MAC41 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_3[7:0]),
      .wt_path_in  (wt_in_wire_0[31:24]),
      .acc_in      (mac_acc_in_wire_0[4*acc_width-1:3*acc_width]),
      .data_out    (mac_data_out_wire_3[7:0]),
      .wt_path_out (wt_out_wire_0[31:24]),
      .acc_out     (mac_acc_out_wire_0[4*acc_width-1:3*acc_width])
   );
   MAC MAC42 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_3[15:8]),
      .wt_path_in  (wt_in_wire_1[31:24]),
      .acc_in      (mac_acc_in_wire_1[4*acc_width-1:3*acc_width]),
      .data_out    (mac_data_out_wire_3[15:8]),
      .wt_path_out (wt_out_wire_1[31:24]),
      .acc_out     (mac_acc_out_wire_1[4*acc_width-1:3*acc_width])
   );
   MAC MAC43 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_3[23:16]),
      .wt_path_in  (wt_in_wire_2[31:24]),
      .acc_in      (mac_acc_in_wire_2[4*acc_width-1:3*acc_width]),
      .data_out    (mac_data_out_wire_3[23:16]),
      .wt_path_out (wt_out_wire_2[31:24]),
      .acc_out     (mac_acc_out_wire_2[4*acc_width-1:3*acc_width])
   );
   MAC MAC44 (
      .clk         (clk),
      .control     (control),
      .data_in     (mac_data_in_wire_3[31:24]),
      .wt_path_in  (wt_in_wire_3[31:24]),
      .acc_in      (mac_acc_in_wire_3[4*acc_width-1:3*acc_width]),
      .data_out    (mac_data_out_wire_3[31:24]),
      .wt_path_out (wt_out_wire_3[31:24]),
      .acc_out     (mac_acc_out_wire_3[4*acc_width-1:3*acc_width])
   );

   always@(posedge clk) begin
      acc_out <= mac_acc_out_wire_3;
   end

endmodule
