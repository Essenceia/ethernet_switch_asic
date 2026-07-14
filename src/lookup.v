/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module lookup #(
	parameter  PORT_CNT   = 3, 
	localparam SEL_W      = PORT_CNT-1,
	localparam DISP_SEL_W = PORT_CNT*SEL_W,
	parameter  MAC_W      = 48
)(
	input wire clk, 
	input wire rst_n,

	input wire                   req_v_i, 
	input wire                   req_early_v_i,
	input wire [PORT_CNT-1:0]    req_port_i, 
	input wire [MAC_W-1:0]       req_mac_i,

	input wire                   wr_early_v_i, 
	input wire [MAC_W-1:0]       wr_mac_i, 
	input wire [PORT_CNT-1:0]    wr_port_i, 	

	input wire [PORT_CNT-1:0]    phy_tx_free_i,

	output wire [PORT_CNT-1:0]   new_dispatch_o,
	output wire [DISP_SEL_W-1:0] dir_o	
);
wire [PORT_CNT-1:0]   disp_lite; 
wire                  hit; 
wire [PORT_CNT-1:0]   hit_port;  

// unicast -> mac lookup, fallback to broadcast in case of no match
mac_addr_table #(
	.PORT_CNT(PORT_CNT), 
	.MAC_W(MAC_W)
)m_table(
	.clk         (clk),
	.rst_n       (rst_n), 

	.rd_v_i      (req_v_i),
	.rd_early_v_i(req_early_v_i),
	.rd_mac_i    (req_mac_i),
	
	.wr_early_v_i(wr_early_v_i),
	.wr_mac_i    (wr_mac_i),
	.wr_port_i   (wr_port_i),
	
	.hit_v_o     (hit),
	.hit_port_o  (hit_port)
);

// remap hit to dispatch directive

wire [DISP_SEL_W-1:0] dir_broadcast_lite;
wire [DISP_SEL_W-1:0] dir_hit_masked;
wire [DISP_SEL_W-1:0] hit_mask; // fallback on broadcast in case of no hit

genvar i;
generate 
	assign dir_broadcast_lite[SEL_W-1:0] = req_port_i[PORT_CNT-1:1];	
	for (i=1; i < PORT_CNT-1; i = i+1) begin: g_broadcast_lite
		assign dir_broadcast_lite[(i+1)*SEL_W-1-:SEL_W] = { req_port_i[PORT_CNT-1:(i+1)], req_port_i[(i-1):0]};	
	end
	assign dir_broadcast_lite[DISP_SEL_W-1-:SEL_W] = req_port_i[PORT_CNT-2:0];	
	
	for (i=0; i < PORT_CNT; i = i+1) begin: g_hit_mask
		assign hit_mask[(i+1)*SEL_W-1-:SEL_W] = {SEL_W{hit_port[i] | ~hit}};
	end
endgenerate

assign dir_hit_masked = dir_broadcast_lite & hit_mask; 
assign disp_lite      = ({PORT_CNT{~hit}} | hit_port) & ~req_port_i & {PORT_CNT{req_v_i}}; 

// output 
assign new_dispatch_o = phy_tx_free_i & disp_lite;
assign dir_o          = dir_hit_masked; 

endmodule	
