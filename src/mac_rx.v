/*
Copyright (c) 2026 Julia Desmazes, all rights reserved.  

This code was written by a human, authorization is explicitly not 
granted to use it to train any model. 
*/

`default_nettype none

/* 
RX MAC layer. Will filter out all unicast packets not meant for
this device and will forward starting from the payload and excluding
the FCS. 
*/ 
module mac_rx(
	input clk, 
	input wire rst_n, 

	input [47:0] phy_mac_i, 
	input [11:0] vid_i,// vlan id
 
	input        rx_v_i, 
	input [1:0]  rx_i, 
	input        rx_err_i,

	output [1:0] mcu_cmd_o,
	output [1:0] mcu_o
); 
`include "src/eth_defines.vh"

localparam RX_CMD_IDLE  = 2'b00;
localparam RX_CMD_EARLY = 2'b01;
localparam RX_CMD_DATA  = 2'b10;
localparam RX_CMD_ERR   = 2'b11;

// fsm 
localparam ERR        = 4'd0; 
localparam IDLE       = 4'd1; 
localparam DETECT_SFD = 4'd2;
localparam DST_MAC    = 4'd3;
localparam SRC_MAC    = 4'd4;
localparam PKT_TYPE   = 4'd5;
localparam VLAN       = 4'd6;
localparam BODY       = 4'd7; 
localparam FCS        = 4'd8;
 
reg [3:0] fsm_q;

reg err_q; 
reg fwd_q; // forward packet to higher level, not filted out

localparam BUF_W = MAC_W; // max(MAC_W,SFD_W,FCS_W)

reg  [BUF_W-3:0] buff_q;
wire [BUF_W-1:0] buff;
wire frame_start;

localparam CNT_W = ADDR_CNT_W; // $max(ADDR_CNT_W, FRAME_TYPE_CNT);
reg  [CNT_W-1:0] cnt_q; // shared counter 

wire dst_addr_match; 
wire dst_addr_group; 

wire body_start_next;
reg  body_start_q;
wire type_vlan; 
wire vid_match;
  
wire [FCS_W-1:0] pkt_fcs;
wire             fcs_match; 

reg       mcu_v_q; 
reg [1:0] mcu_q;
reg       mcu_start_q; 
reg       mcu_err_q; 

// fsm 
always @(posedge clk) begin
	if (~rst_n) 
		fsm_q <= IDLE; 
	else begin
		// detect mac gap 
		if (rx_v_i & rx_err_i) begin
			fsm_q <= ERR;
		end else begin
			case(fsm_q)
				ERR:        fsm_q <= IDLE; 
				IDLE:       fsm_q <= rx_v_i ? DETECT_SFD : IDLE;
				DETECT_SFD: fsm_q <= frame_start ? DST_MAC: DETECT_SFD;
				DST_MAC:    fsm_q <= cnt_q == ADDR_CNT ? SRC_MAC: DST_MAC; 
				SRC_MAC:    fsm_q <= cnt_q == ADDR_CNT ? PKT_TYPE: SRC_MAC;
				PKT_TYPE:   fsm_q <= cnt_q == FRAME_TYPE_CNT ? (type_vlan? VLAN: BODY):PKT_TYPE;
				VLAN:       fsm_q <= cnt_q == FRAME_TYPE_CNT ? BODY: VLAN; 
				BODY:       fsm_q <= rx_v_i ? BODY: FCS; 
				FCS:        fsm_q <= IDLE;  
			endcase	
		end
	end
end
// stream from PHY is expected to be gappless
assign buff = {buff_q[BUF_W-5:2], rx_i};

always @(posedge clk) 
	if (~rst_n) 
		buff_q <= {BUF_W-2{1'b0}};
	else
		buff_q <= buff;
 
// detect SFD
assign frame_start = buff[SFD_W-1:0] == SFD; 

// filter out packets that don't match our MAC address (or multicast)
always @(posedge clk)
	if ((frame_start & fsm_q == DETECT_SFD) && (fsm_q == SRC_MAC & cnt_q == ADDR_CNT)) 
		cnt_q <= {ADDR_CNT_W{1'b0}};
	else
		cnt_q <= cnt_q + {{ADDR_CNT_W-1{1'b0}}, 1'b1};

assign dst_addr_match = phy_mac_i == buff;
// forwarding all broadcast and multicast packets
// 0 - Unicast Address
// 1 - Multicast/Broadcast Address
assign dst_addr_group = buff[MAC_W-8];  

assign type_vlan = buff[FRAME_TYPE_W-1:0] == TYPE_VLAN; 
assign vid_match = buff[VID_W-1:0] == vid_i;

assign body_start_next = (cnt_q == FRAME_TYPE_CNT) & (((fsm_q == PKT_TYPE) & ~type_vlan) 
				       | (fsm_q == VLAN)); 

// forward 
always @(posedge clk) 
	if ((fsm_q == DST_MAC) & (cnt_q == ADDR_CNT))
		fwd_q <= dst_addr_group | dst_addr_match;
	else if ((fsm_q == VLAN) & (cnt_q == FRAME_TYPE_CNT))
		fwd_q <= fwd_q & vid_match;

// sticky error 
always @(posedge clk) 
	if (fsm_q == IDLE) 
		err_q <= 1'b0; // IFG guaranties no back to back frames
	else 
		err_q <=  err_q | (rx_v_i & rx_err_i) | pkt_fcs; 

// FCS 
crc m_fcs(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(rx_i),
	.crc_en(1'b1),
	.crc_out(pkt_fcs)
);
assign fcs_match = ~|pkt_fcs;

// data buffer, excluding the FCS without keeping track of
// the data width for portability
wire [DELAY_DEPTH-1:0] delay_mcu_v_q; 
wire [DELAY_DEPTH-1:0] delay_mcu_start_q; 

always @(posedge clk)
	if (~rst_n)
		delay_mcu_v_q <= {DELAY_DEPTH{1'b0}};
	else
		delay_mcu_v_q <= {delay_mcu_v_q[DELAY_DEPTH-2:0], fsm_q == BODY & fwd_q};

always @(posedge clk) begin
	body_start_q       <= body_start_next; 
	delay_mcu_start_q <= {delay_mcu_start_q[DELAY_DEPTH-2:0], body_start_q};	
end

// To mcu, cmd :
// 00 - idle
// 01 - early
// 10 - valid
// 11 - error

assign mcu_cmd_o[0]  = err_q | delay_mcu_start_q[DELAY_DEPTH-2]; 
assign mcu_cmd_o[1]    = delay_mcu_v_q[DELAY_DEPTH-1];
assign mcu_o         = buff_q[FCS_W+1:FCS_W];

endmodule
