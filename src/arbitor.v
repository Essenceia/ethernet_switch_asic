/*
Copyright (c) 2026 Julia Desmazes 

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

module arbitor #(
	localparam PORT_CNT = 3,
	parameter MAC_W = 48
)(
	input wire clk, 

	input wire [PORT_CNT-1:0] req_early_i, 
	input wire [MAC_W*PORT_CNT-1:0] req_mac_i, 

	output wire                req_v_o,	
	output wire[PORT_CNT-1:0]  req_port_o, 
	output wire[MAC_W-1:0]     req_mac_o
);

// priority selection
wire [PORT_CNT-1:0] prio_req; 
reg  [PORT_CNT-1:0] prio_req_q; 
assign prio_req[0] = req_early_i[0];
assign prio_req[1] = req_early_i[1] & ~req_early_i[0];
assign prio_req[2] = req_early_i[2] & ~|req_early_i[1:0];

always @(posedge clk) 
	prio_req_q <= prio_req;

reg [MAC_W-1:0] req_mac;
// specify this is a parallel case multiplexer and that 
// the sel is a onehot0 
/* verilator lint_off CASEOVERLAP */
always @(*) begin
	(* parallel_case *)
	casez(prio_req_q)
		3'b??1: req_mac = req_mac_i[MAC_W-1:0];
		3'b?1?: req_mac = req_mac_i[2*MAC_W-1-:MAC_W];
		3'b1??: req_mac = req_mac_i[3*MAC_W-1-:MAC_W];
		default: req_mac = {MAC_W{1'bx}};
	endcase
end
/* verilator lint_on CASEOVERLAP */

wire [MAC_W-1:0] req_mac_swap;
pairreverse_and_byteswap #(.W(MAC_W/8)) m_mac_swap(
	.i(req_mac),
	.o(req_mac_swap)
);

assign req_v_o = |prio_req_q;
assign req_port_o = prio_req_q; 
assign req_mac_o = req_mac_swap; 

endmodule
