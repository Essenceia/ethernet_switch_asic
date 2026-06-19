/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module aiguilleur #(
	parameter PHY_W = 2,
	localparam PORT_CNT = 3
)(
	input wire clk, 
	input wire rst_n, 

	input wire new_dispatch_i, 
	input wire [PORT_CNT-2:0] dir_i,

	input wire [PORT_CNT-2:0]           mac_rx_v_i,
	input wire [(PORT_CNT-1)*PHY_W-1:0] mac_rx_i,

	output wire             mac_tx_v_o,
	output wire [PHY_W-1:0] mac_tx_o
);
/* verilator lint_off UNUSEDSIGNAL */
reg [PORT_CNT-2:0] sel_onehot_q;
/* verilator lint_on UNUSEDSIGNAL */

always @(posedge clk) 
	if (~rst_n) sel_onehot_q <= {PORT_CNT-1{1'b0}};
	else if (new_dispatch_i) sel_onehot_q <= dir_i;

// valid should be masked in case valid data is being transmitted on an 
// unselected port (eg: start during IPG)
assign mac_tx_v_o = sel_onehot_q[0] & mac_rx_v_i[0] | sel_onehot_q[1] & mac_rx_v_i[1];
// could make this an reduction of masked data, but deciding to hand off control to synth
assign mac_tx_o = sel_onehot_q[0] ? mac_rx_i[PHY_W-1:0] : mac_rx_i[2*PHY_W-1-:PHY_W];

endmodule
