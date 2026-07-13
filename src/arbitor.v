/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module arbitor #(
	parameter PORT_CNT = 3,
	parameter MAC_W    = 48
)(
	input wire clk, 

	input wire [PORT_CNT-1:0]       req_early_i, 
	input wire [MAC_W*PORT_CNT-1:0] req_mac_i, 

	output wire                req_v_o,	
	output wire                req_early_v_o,	
	output wire[PORT_CNT-1:0]  req_port_o, 
	output wire[MAC_W-1:0]     req_mac_o
);

// priority selection
wire [PORT_CNT-1:0] prio_req; 
reg  [PORT_CNT-1:0] prio_req_q; 

genvar i; 
generate 
	assign prio_req[0] = req_early_i[0];
	for(i = 1; i < PORT_CNT; i = i+1) begin: g_prio_mux
		assign prio_req[i] = req_early_i[i] & ~|req_early_i[i-1:0];
	end
endgenerate

always @(posedge clk) 
	prio_req_q <= prio_req;

reg [MAC_W-1:0] req_mac;
int x; 
always @(*) begin
	req_mac = {MAC_W{1'b0}};
	for (x = 0; x < PORT_CNT; x = x + 1) begin
	    if (prio_req_q[x])
			req_mac = req_mac | req_mac_i[(x+1)*MAC_W-1-:MAC_W];
	end
end

wire [MAC_W-1:0] req_mac_swap;
pairreverse_and_byteswap #(.W(MAC_W/8)) m_mac_swap(
	.i(req_mac),
	.o(req_mac_swap)
);

assign req_v_o       = |prio_req_q;
assign req_early_v_o = |prio_req;
assign req_port_o    = prio_req_q; 
assign req_mac_o     = req_mac_swap; 

endmodule
