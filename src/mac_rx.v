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

	output       data_v_o,
	output       data_start_o,
	output       data_err_o,
	output [1:0] data_o
); 
// physical interface
localparam PHY_W = 2; 

localparam MAC_W        = 48;
localparam ADDR_CNT_VAL = (MAC_W/PHY_W) - 1;
localparam ADDR_CNT_W   = $clog2(ADDR_CNT_VAL); 
/* verilator lint_off WIDTHTRUNC */
localparam [ADDR_CNT_W-1:0] ADDR_CNT = ADDR_CNT_VAL;
/* verilator lint_on WIDTHTRUNC */

localparam SFD_W = 8; 
localparam [SFD_W-1:0] SFD = 8'b10101011; 

localparam FRAME_TYPE_W       = 16;
localparam FRAME_TYPE_CNT_VAL = (FRAME_TYPE_W/PHY_W) - 1;
localparam FRAME_TYPE_CNT_W   = $clog2(FRAME_TYPE_CNT_VAL);
/* verilator lint_off WIDTHTRUNC */
localparam [FRAME_TYPE_CNT_W-1:0] FRAME_TYPE_CNT = FRAME_TYPE_CNT_VAL;
/* verilator lint_on WIDTHTRUNC */

localparam [FRAME_TYPE_W-1:0] TYPE_VLAN = 16'h8100;
localparam VID_W = 12;

// FCS 
localparam FCS_W = 32; 

localparam DELAY_DEPTH = (FCS_W /PHY_W) + 1;

// fsm 
localparam ERR        = 4'd0; 
localparam IDLE       = 4'd1; 
localparam DETECT_SFD = 4'd2;
localparam DST_MAC    = 4'd3;
localparam SRC_MAC    = 4'd4;
localparam PKT_TYPE   = 4'd5;
localparam VLAN       = 4'd6;
localparam BODY       = 4'd7; 
 
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
wire dst_addr_broadcat; 
wire dst_addr_group; 

wire body_start_next;
reg  body_start_q;
wire type_vlan; 
wire vid_match;
  
wire [FCS_W-1:0] pkt_fcs;
wire             fcs_err; 

// fsm 
wire eof; 

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
				DST_MAC:    fsm_q <= cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT ? SRC_MAC: DST_MAC; 
				SRC_MAC:    fsm_q <= cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT ? PKT_TYPE: SRC_MAC;
				PKT_TYPE:   fsm_q <= cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT ? (type_vlan? VLAN: BODY):PKT_TYPE;
				VLAN:       fsm_q <= cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT ? BODY: VLAN; 
				BODY:       fsm_q <= rx_v_i ? BODY: IDLE; 
				default:    fsm_q <= IDLE; 
			endcase	
		end
	end
end

assign eof = (fsm_q == BODY) & ~ rx_v_i;

// stream from PHY is expected to be gappless
assign buff = {buff_q[BUF_W-PHY_W-1:0], rx_i};

always @(posedge clk) 
	if (~rst_n) 
		buff_q <= {BUF_W-2{1'b0}};
	else
		buff_q <= buff[BUF_W-3:0];
 
// detect SFD
assign frame_start = buff[SFD_W-1:0] == SFD; 

// filter out packets that don't match our MAC address (or multicast)
always @(posedge clk)
	if ((frame_start & fsm_q == DETECT_SFD) 
       | (((fsm_q == SRC_MAC) | (fsm_q == DST_MAC)) & cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT) 
       | (((fsm_q == PKT_TYPE) | (fsm_q == VLAN)) & cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT)) 
		cnt_q <= {CNT_W{1'b0}};
	else
		cnt_q <= cnt_q + {{CNT_W-1{1'b0}}, 1'b1};

assign dst_addr_match = phy_mac_i == buff;
// forwarding all broadcast and multicast packets
// 0 - Unicast Address
// 1 - Multicast/Broadcast Address
assign dst_addr_group = buff[MAC_W-8];  

assign type_vlan = buff[FRAME_TYPE_W-1:0] == TYPE_VLAN; 
assign vid_match = buff[VID_W-1:0] == vid_i;

assign body_start_next = (cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT) & (((fsm_q == PKT_TYPE) & ~type_vlan) 
				       | (fsm_q == VLAN)); 

// forward 
always @(posedge clk) 
	if ((fsm_q == DST_MAC) & (cnt_q[ADDR_CNT_W-1:0] == ADDR_CNT))
		fwd_q <= dst_addr_group | dst_addr_match;
	else if ((fsm_q == VLAN) & (cnt_q[FRAME_TYPE_CNT_W-1:0] == FRAME_TYPE_CNT))
		fwd_q <= fwd_q & vid_match;

// sticky error 
always @(posedge clk) 
	if (fsm_q == IDLE) 
		err_q <= 1'b0; // IFG guaranties no back to back frames
	else 
		err_q <=  err_q | (rx_v_i & rx_err_i) | fcs_err; 

// FCS 
crc m_fcs(
	.clk(clk),
	.rst_crc(fsm_q == IDLE),
	.data_in(rx_i),
	.crc_en(fsm_q != DETECT_SFD),
	.crc_out(pkt_fcs)
);
assign fcs_err = eof & |(pkt_fcs);// end of packet, check fcs

// data buffer, excluding the FCS without keeping track of
// the data width for portability
reg [DELAY_DEPTH-1:0] delay_data_v_q; 
reg [DELAY_DEPTH-1:0] delay_data_start_q; 

always @(posedge clk)
	if (~rst_n | eof)
		delay_data_v_q <= {DELAY_DEPTH{1'b0}};
	else
		delay_data_v_q <= {delay_data_v_q[DELAY_DEPTH-2:0], fsm_q == BODY & fwd_q};

always @(posedge clk) begin
	delay_data_start_q <= {delay_data_start_q[DELAY_DEPTH-2:0], body_start_next & fwd_q};	
end

assign data_v_o       = delay_data_v_q[DELAY_DEPTH-1];
assign data_start_o   = delay_data_start_q[DELAY_DEPTH-1]; 
assign data_err_o     = err_q;
assign data_o         = buff_q[FCS_W+1:FCS_W];

endmodule
