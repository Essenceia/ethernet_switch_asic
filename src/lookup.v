/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module lookup #(
	parameter PORT_CNT = 3, 
	localparam DISP_SEL_W = PORT_CNT*(PORT_CNT-1),
	parameter MAC_W = 48
)(
	input wire clk, 
	input wire rst_n,

	input wire                req_v_i, 
	input wire                req_early_v_i,
	input wire [PORT_CNT-1:0] req_port_i, 
	input wire [MAC_W-1:0]    req_mac_i,

	input wire                 wr_early_v_i, 
	input wire [MAC_W-1:0]     wr_mac_i, 
	input wire [PORT_CNT-1:0]  wr_port_i, 	

	input wire [PORT_CNT-1:0]  phy_tx_free_i,

	output wire [PORT_CNT-1:0]   new_dispatch_o,
	output wire [DISP_SEL_W-1:0] dir_o	
);
wire [PORT_CNT-1:0] disp_lite; 
wire [DISP_SEL_W-1:0] dir;
 
// unicast -> mac lookup, fallback to broadcast in case of no match
dispatcher m_dispatcher(
	.clk(clk), 
	.rst_n(rst_n),
	.req_v_i(req_v_i),
	.req_early_v_i(req_early_v_i),
	.req_port_i(req_port_i),
	.req_mac_i(req_mac_i),

	.wr_early_v_i(wr_early_v_i),
	.wr_mac_i(wr_mac_i),
	.wr_port_i(wr_port_i),
	 
	.new_dispatch_lite_o(disp_lite),
	.dir_o(dir)
);

assign new_dispatch_o = phy_tx_free_i & disp_lite;
assign dir_o = dir; 

endmodule	
