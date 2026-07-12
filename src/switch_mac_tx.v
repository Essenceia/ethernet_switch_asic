/*
Copyright (c) 2026 Julia Desmazes, all rights reserved.  

This code was written by a human, authorization is explicitly not 
granted for it to be used to train any model. 
*/

`default_nettype none

/* MAC TX 
start streaming out preamble when a new request arrived (data_v_i), 
and lift the accept signal to tell application that it can start
streaming the packet.
When data_v_i is deaserted this signals the end of the packet
so start the ipg. 
*/
module switch_mac_tx #(
	parameter PHY_W = 2
)(
	input wire clk, 
	input wire rst_n, 

	input wire             data_v_i, 
	input wire             data_last_i, 
	input wire [PHY_W-1:0] data_i, 

	output wire            data_acc_o, 

	output wire             tx_v_o,
	output wire [PHY_W-1:0] tx_o	
);
localparam CNT_W = 6; 
localparam [CNT_W-1:0] PREAMBLE_CNT = 7 * (8/PHY_W) - 1; 
localparam [CNT_W-1:0] SFD_CNT      = 1 * (8/PHY_W) - 1; 
localparam [CNT_W-1:0] IPG_CNT      = 12 * (8/PHY_W) - 1; 

/* fsm */
localparam IDLE     = 3'd0;
localparam PREAMBLE = 3'd1;
localparam SFD      = 3'd2;// seperating preamble and sfd to save 16b of ff 
localparam PACKET   = 3'd3;
localparam IPG      = 3'd4;

(* MARK_DEBUG = "true" *)reg [2:0] fsm_q;
reg [CNT_W-1:0] cnt_q; 

always @(posedge clk) 
	if (~rst_n) 
		fsm_q <= IDLE; 
	else begin
		case(fsm_q) 
			IDLE    : fsm_q <= data_v_i ? PREAMBLE: IDLE; 
			PREAMBLE: fsm_q <= cnt_q == PREAMBLE_CNT ? SFD: PREAMBLE; 
			SFD     : fsm_q <= cnt_q == SFD_CNT ? PACKET : SFD; 
			PACKET  : fsm_q <= data_last_i ? IPG : PACKET;
			IPG     : fsm_q <= cnt_q == IPG_CNT ? IDLE : IPG;
			default: fsm_q <= IDLE; 
		endcase
	end

wire rst_cnt; 
assign rst_cnt = (fsm_q == IDLE) 
			   | ((fsm_q == PACKET) & data_last_i)
			   | ((fsm_q == PREAMBLE) & (cnt_q == PREAMBLE_CNT));

always @(posedge clk) 
	cnt_q <= rst_cnt ? {CNT_W{1'b0}}: cnt_q + {{CNT_W-1{1'b0}}, 1'b1}; 
	
assign data_acc_o = (fsm_q == IDLE);

// preamble + sfd
wire [PHY_W-1:0] preamble_data; 
wire sel_sfd_last;
wire sel_preamble_sfd;

assign sel_sfd_last     = (fsm_q == SFD) & (cnt_q == SFD_CNT);
assign preamble_data    = sel_sfd_last? 2'b11 : 2'b01; 
assign sel_preamble_sfd = (fsm_q == PREAMBLE) | (fsm_q == SFD);

assign tx_o = sel_preamble_sfd ? preamble_data: (fsm_q == PACKET)? data_i: {PHY_W{1'b0}};   
assign tx_v_o = (fsm_q != IDLE) & (fsm_q != IPG);

endmodule	
