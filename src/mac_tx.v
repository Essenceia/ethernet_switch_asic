/*
Copyright (c) 2026 Julia Desmazes, all rights reserved.  

This code was written by a human, authorization is explicitly not 
granted for it to be used to train any model. 
*/

`default_nettype none

/* MAC TX 
Send out response packet with accelerator results encapsulated.
Packet will NOT contain a VLAN tag.
Module will be adding : 
- header
- fcs 
*/
module mac_tx #(
	parameter PHY_W = 2,
	localparam MAC_W = 48,
	localparam ETHTYPE_W = 16,
	parameter APP_ETHTYPE = 16'h88B6 
)(
	input clk, 
	input wire rst_n, 

	input wire [MAC_W-1:0] phy_mac_i, 

	input wire             data_v_i, 
	input wire             data_last_i, 
	input wire [PHY_W-1:0] data_i, 
	input wire [MAC_W-1:0] data_dst_mac_i,
	output wire            data_acc_o, // accept payload, start streaming

	output wire             phy_v_o,
	output wire [PHY_W-1:0] phy_o	
);
localparam CNT_W = 6; 
localparam [CNT_W-1:0] PREAMBLE_CNT = 7 * (8/PHY_W) - 1; 
localparam [CNT_W-1:0] SFD_CNT      = 1 * (8/PHY_W) - 1; 
localparam [CNT_W-1:0] MAC_CNT      = 6 * (8/PHY_W) - 1; 
localparam [CNT_W-1:0] ETHTYPE_CNT  = 2 * (8/PHY_W) - 1; 
localparam [CNT_W-1:0] FCS_CNT      = 4 * (8/PHY_W) - 1; 

localparam [CNT_W-1:0] SFD_CNT_MIN_1 = 1 * (8/PHY_W) - 2; 

localparam FCS_W = 32;
/* 
fsm
start streaming out header when a new request arrived (data_v_i), 
and lift the accept signal to tell application that it can start
streaming payload.
When data_v_i is deaserted this signals the end of the payload
so append the fcs */
localparam IDLE     = 3'd0;
localparam PREAMBLE = 3'd1;
localparam SFD      = 3'd2;// seperating preamble and sfd to save 16b of ff 
localparam SRC_MAC  = 3'd3;
localparam DST_MAC  = 3'd4;
localparam ETHTYPE  = 3'd5;
localparam PAYLOAD  = 3'd6;
localparam FCS      = 3'd7;

reg [2:0]       fsm_q;
reg [CNT_W-1:0] cnt_q; 
always @(posedge clk) 
	if (~rst_n) 
		fsm_q <= IDLE; 
	else begin
		case(fsm_q) 
			IDLE    : fsm_q <= data_v_i ? PREAMBLE: IDLE; 
			PREAMBLE: fsm_q <= cnt_q == PREAMBLE_CNT ? SFD: PREAMBLE; 
			SFD     : fsm_q <= cnt_q == SFD_CNT ? SRC_MAC: SFD; 
			SRC_MAC : fsm_q <= cnt_q == MAC_CNT ? DST_MAC: SRC_MAC; 
			DST_MAC : fsm_q <= cnt_q == MAC_CNT ? ETHTYPE: DST_MAC;
			ETHTYPE : fsm_q <= cnt_q == ETHTYPE_CNT ? PAYLOAD : ETHTYPE; 
			PAYLOAD : fsm_q <= data_last_i ? FCS : PAYLOAD;
			FCS     : fsm_q <= cnt_q == FCS_CNT ? IDLE : FCS;
		endcase
	end

wire rst_cnt; 
assign rst_cnt = (fsm_q == IDLE) | (fsm_q == PAYLOAD) 
			   | ((fsm_q == PREAMBLE) & (cnt_q == PREAMBLE_CNT))
			   | ((fsm_q == SFD) & (cnt_q == SFD_CNT))
               | (((fsm_q == SRC_MAC) | (fsm_q == DST_MAC)) & (cnt_q == MAC_CNT))
			   | ((fsm_q == ETHTYPE) & (cnt_q == ETHTYPE_CNT));

always @(posedge clk) 
	cnt_q <= rst_cnt ? {CNT_W{1'b0}}: cnt_q + {{CNT_W-1{1'b0}}, 1'b1}; 
	
assign data_acc_o = (fsm_q == PAYLOAD) | ((fsm_q == ETHTYPE) & (cnt_q == ETHTYPE_CNT));

// fcs 
wire [FCS_W-1:0] pkt_fcs;
crc m_fcs(
	.clk(clk),
	.rst_crc(fsm_q == SFD),
	.data_in(phy_o),
	.crc_en(1'b1),
	.crc_out(pkt_fcs)
);

// output shift buffer
localparam BUFF_W = MAC_W; // max(MAC_W, FCS, ETHTYPE)
reg [BUFF_W-1:0] shift_buff_q;
wire sel_src_mac;
wire sel_dst_mac;
wire sel_ethtype; 
wire sel_fcs;

assign sel_src_mac = (fsm_q == SFD) & (cnt_q == SFD_CNT);
assign sel_dst_mac = (fsm_q == SRC_MAC) & (cnt_q == MAC_CNT);
assign sel_ethtype = (fsm_q == DST_MAC) & (cnt_q == MAC_CNT);
assign sel_fcs     = (fsm_q == PAYLOAD) & data_last_i;

// TODO add a onehot0 attribute if yosys doesn't catch it automatically 
always @(posedge clk) begin
	case ({sel_fcs, sel_ethtype, sel_dst_mac, sel_src_mac})
		4'b0001: shift_buff_q <= phy_mac_i;
		4'b0010: shift_buff_q <= data_dst_mac_i;
		4'b0100: shift_buff_q <= {APP_ETHTYPE, {BUFF_W-ETHTYPE_W{1'bX}}};
		4'b1000: shift_buff_q <= {pkt_fcs, {BUFF_W-FCS_W{1'bX}}};
		default: shift_buff_q <= {shift_buff_q[BUFF_W-PHY_W-1:0], {PHY_W{1'bX}}}; 
	endcase
end

wire [PHY_W-1:0] preamble_data; 
wire sel_sfd_last;
wire sel_preamble_sfd;

assign sel_sfd_last     = (fsm_q == SFD) & (cnt_q == SFD_CNT);
assign sel_preamble_sfd = (fsm_q == PREAMBLE) | (fsm_q == SFD);
assign preamble_data = sel_sfd_last? 2'b11 : 2'b01; 

assign phy_o = sel_preamble_sfd ? preamble_data: (fsm_q == PAYLOAD)? data_i: shift_buff_q[BUFF_W-1-:PHY_W];   
assign phy_v_o = (fsm_q != IDLE);
endmodule	
