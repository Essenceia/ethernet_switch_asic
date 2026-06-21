/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* trigger regular updates and hold update request until full 
update has been finished.
This timer was design for a target operating frequency of 50MHz and a timeout of ~300s.
 */
module ttnn_timer #(
	parameter TTNN_W = 4
)(
	input wire clk, 
	input wire rst_n, 
	
	input wire  update_finished_i, 
	output wire update_req_o
);
// 2 intermediary times of 13 bits each
`ifdef COCOTB // increase tb stress
localparam INNER_CNT_W = 2; 
`else
localparam INNER_CNT_W = 13; 
`endif

localparam CNT_MAX_VAL = 224/(2 ** TTNN_W);
localparam CNT_W = $clog2(CNT_MAX_VAL);
/* verilator lint_off WIDTHTRUNC */
localparam [CNT_W-1:0] CNT_MAX = CNT_MAX_VAL; 
/* verilator lint_on WIDTHTRUNC */

reg  [INNER_CNT_W-1:0]  inner0_q, inner1_q; 
wire [INNER_CNT_W-1:0]  inner0_next, inner1_next; 
wire inner0_overflow,   inner1_overflow;  
reg  inner0_overflow_q, inner1_overflow_q;  

assign {inner0_overflow, inner0_next} = inner0_q + {{INNER_CNT_W-1{1'b0}}, 1'b1};
assign {inner1_overflow, inner1_next} = inner1_q + {{INNER_CNT_W-1{1'b0}}, inner0_overflow_q};

always @(posedge clk) begin
	if (~rst_n) begin
		inner0_q          <= {INNER_CNT_W{1'b0}};
		inner1_q          <= {INNER_CNT_W{1'b0}};
		inner0_overflow_q <= 1'b0;
		inner1_overflow_q <= 1'b0;
	end else begin
		inner0_q          <= inner0_next;
		inner1_q          <= inner1_next;
		inner0_overflow_q <= inner0_overflow;
		inner1_overflow_q <= inner1_overflow;
	end
end

// main counter
reg  [CNT_W-1:0] cnt_q; 
wire             trigger;

assign trigger = cnt_q == CNT_MAX;
always @(posedge clk) 
	if (~rst_n | trigger) cnt_q <= {CNT_W{1'b0}};
	else cnt_q <= cnt_q + {{CNT_W-1{1'b0}}, inner1_overflow_q}; 

// send update
reg update_pending_q; 

always @(posedge clk)
	if (~rst_n | update_finished_i) update_pending_q <= 1'b0; 
	else if (trigger) update_pending_q <= 1'b1;

assign update_req_o = update_pending_q;

endmodule

