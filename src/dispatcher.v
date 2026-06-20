/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module dispatcher #(
	localparam PORT_CNT = 3, 
	localparam DISP_SEL_W = PORT_CNT*(PORT_CNT-1),
	parameter MAC_W = 48
)(
	input wire clk, 
	input wire rst_n,

	input wire                   req_v_i,
	input wire                   req_early_v_i,
	input wire [PORT_CNT-1:0]    req_port_i, 
	input wire [MAC_W-1:0]       req_mac_i, 

	input wire                 wr_early_v_i, 
	input wire [MAC_W-1:0]     wr_mac_i, 
	input wire [PORT_CNT-1:0]  wr_port_i, 
	
	output wire [PORT_CNT-1:0]   new_dispatch_lite_o,
	output wire [DISP_SEL_W-1:0] dir_o
);

wire                hit; 
wire [PORT_CNT-1:0] hit_port; 

mac_addr_table #(
	.PORT_CNT(PORT_CNT), 
	.MAC_W(MAC_W)
)m_table(
	.clk(clk),
	.rst_n(rst_n), 
	.rd_v_i(req_v_i),
	.rd_early_v_i(req_early_v_i),
	.rd_mac_i(req_mac_i),
	
	.wr_early_v_i(wr_early_v_i),
	.wr_mac_i(wr_mac_i),
	.wr_port_i(wr_port_i),
	
	.hit_v_o(hit),
	.hit_port_o(hit_port)
);

// remap hit to dispatch directive
localparam SEL_W = PORT_CNT-1;

wire [DISP_SEL_W-1:0] dir_lite;
wire [DISP_SEL_W-1:0] dir_hit_masked;
wire [DISP_SEL_W-1:0] hit_mask;
assign dir_lite = {{req_port_i[1:0]}, // tx2
				   {req_port_i[2], req_port_i[0]}, // tx1
                   {req_port_i[2:1]}};// tx0

// fallback on broadcast in case of no hit
assign hit_mask = { {SEL_W{hit_port[2] | ~hit}},
					{SEL_W{hit_port[1] | ~hit}},
					{SEL_W{hit_port[0] | ~hit}}}; 
assign dir_hit_masked = dir_lite & hit_mask; 

// output 
assign new_dispatch_lite_o = ({PORT_CNT{~hit}} | hit_port) & ~req_port_i & {PORT_CNT{req_v_i}}; 
assign dir_o = dir_hit_masked; 
endmodule
